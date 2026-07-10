import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'append.dart';
import 'derive.dart';

/// Database id — matches the `breakdex` TablesDB in `appwrite.config.json`.
const String _databaseId = 'breakdex';

/// The append-only review log table (schema table `$id`, authored in task 1.1).
const String _reviewEventsTable = 'reviewEvents';

/// The server-derived FSRS card table (schema table `$id`).
const String _fsrsCardsTable = 'fsrsCards';

/// `reviews-append` Appwrite Function entrypoint (Dart runtime).
///
/// Accepts one batched `{events: [...]}` append (same wire shape as the Convex
/// `reviews:appendReviewEvents` mutation) and, via [applyAppend]: appends each
/// event idempotently (by `clientOpId`) to the immutable `reviewEvents` log,
/// then re-derives the FSRS card for every entity a newly appended event touched
/// (event-triggered derivation — see `append.dart`). The append + derive core is
/// pure and separately unit-tested; this handler is the thin IO glue:
/// authenticate the caller, wire a [TablesDbAppendStore], marshal the response.
///
/// `userId` is taken from the trusted `x-appwrite-user-id` header (stamped by
/// Appwrite for an authenticated invocation) — never from the payload — so every
/// row is written under that user's identity and per-row permissions.
Future<dynamic> main(final dynamic context) async {
  final userId = _header(context, 'x-appwrite-user-id');
  if (userId.isEmpty) {
    return context.res.json(
      <String, dynamic>{'error': 'unauthenticated: missing x-appwrite-user-id'},
      statusCode: 401,
    );
  }

  final client = Client()
      .setEndpoint(Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT'] ?? '')
      .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'] ?? '')
      .setKey(_header(context, 'x-appwrite-key'));
  final store = TablesDbAppendStore(TablesDB(client), _databaseId);

  final AppendRequest request;
  try {
    request = AppendRequest.fromJson(_bodyMap(context.req.bodyJson));
  } on AppendRejection catch (e) {
    return context.res.json(
      <String, dynamic>{'error': e.message},
      statusCode: 400,
    );
  }

  final result = await applyAppend(
    store,
    userId,
    request,
    onError: (final message) => context.error(message),
  );
  return context.res.json(<String, dynamic>{
    'appended': result.appended,
    'skipped': result.skipped,
    'derived': result.derived,
    'failed': result.failed,
  });
}

/// Read a request header, defaulting to `''`. Header keys are lowercase.
String _header(final dynamic context, final String name) {
  final Object? value = context.req.headers[name];
  return value is String ? value : '';
}

Map<String, dynamic> _bodyMap(final Object? body) =>
    body is Map ? body.cast<String, dynamic>() : <String, dynamic>{};

/// [AppendStore] backed by Appwrite TablesDB. Review events are located by the
/// trusted `(userId, clientOpId)` pair (idempotency) and folded per entity via
/// the `by_user_entity` index authored in task 1.1; the derived card is upserted
/// under owner-only permissions so a user can only ever read/write their own
/// rows (the per-user isolation `rowSecurity:true` requires).
class TablesDbAppendStore implements AppendStore {
  TablesDbAppendStore(this._db, this._databaseId);

  final TablesDB _db;
  final String _databaseId;

  @override
  Future<bool> hasEvent(final String userId, final String clientOpId) async {
    final rows = await _db.listRows(
      databaseId: _databaseId,
      tableId: _reviewEventsTable,
      queries: [
        Query.equal('userId', userId),
        Query.equal('clientOpId', clientOpId),
        Query.limit(1),
      ],
    );
    return rows.rows.isNotEmpty;
  }

  @override
  Future<void> insertEvent(
    final String userId,
    final ReviewEventOp event,
  ) async {
    await _db.createRow(
      databaseId: _databaseId,
      tableId: _reviewEventsTable,
      rowId: ID.unique(),
      data: <String, dynamic>{
        'id': event.localId,
        'userId': userId,
        'entityId': event.entityId,
        'entityType': event.entityType,
        'rating': event.rating,
        'reviewedAt': event.reviewedAt,
        'clientOpId': event.clientOpId,
      },
      permissions: _ownerOnly(userId),
    );
  }

  @override
  Future<List<DerivableEvent>> listEventsForEntity(
    final String userId,
    final EntityKey entity,
  ) async {
    // Cursor-paginate the full log for this entity (a delta larger than one
    // page would otherwise be silently truncated and corrupt the derivation),
    // ordered oldest→newest to match the client's fold order.
    final events = <DerivableEvent>[];
    String? cursor;
    while (true) {
      final page = await _db.listRows(
        databaseId: _databaseId,
        tableId: _reviewEventsTable,
        queries: [
          Query.equal('userId', userId),
          Query.equal('entityType', entity.entityType),
          Query.equal('entityId', entity.entityId),
          Query.orderAsc('reviewedAt'),
          Query.limit(_pageSize),
          if (cursor != null) Query.cursorAfter(cursor),
        ],
      );
      for (final row in page.rows) {
        events.add(DerivableEvent(
          rating: _asInt(row.data['rating']),
          reviewedAt: _asInt(row.data['reviewedAt']),
          clientOpId: row.data['clientOpId'] as String,
        ));
      }
      if (page.rows.length < _pageSize) {
        break;
      }
      cursor = page.rows.last.$id;
    }
    return events;
  }

  @override
  Future<void> upsertCard(
    final String userId,
    final EntityKey entity,
    final DerivedCard card,
  ) async {
    final data = <String, dynamic>{
      'entityId': entity.entityId,
      'entityType': entity.entityType,
      'userId': userId,
      'stability': card.stability,
      'difficulty': card.difficulty,
      'due': card.due,
      'state': card.state,
      'lastEventOpId': card.lastEventOpId,
      'updatedAt': card.updatedAt,
    };
    final existing = await _db.listRows(
      databaseId: _databaseId,
      tableId: _fsrsCardsTable,
      queries: [
        Query.equal('userId', userId),
        Query.equal('entityType', entity.entityType),
        Query.equal('entityId', entity.entityId),
        Query.limit(1),
      ],
    );
    if (existing.rows.isEmpty) {
      await _db.createRow(
        databaseId: _databaseId,
        tableId: _fsrsCardsTable,
        rowId: ID.unique(),
        data: data,
        permissions: _ownerOnly(userId),
      );
    } else {
      await _db.updateRow(
        databaseId: _databaseId,
        tableId: _fsrsCardsTable,
        rowId: existing.rows.first.$id,
        data: data,
      );
    }
  }

  static const int _pageSize = 100;

  List<String> _ownerOnly(final String userId) => [
        Permission.read(Role.user(userId)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ];

  int _asInt(final Object? v) => v is int ? v : (v as num).toInt();
}
