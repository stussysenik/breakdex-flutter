import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'pull.dart';

/// Database id — matches the `breakdex` TablesDB in `appwrite.config.json`.
const String _databaseId = 'breakdex';

/// The shared soft-delete table (schema table `$id`).
const String _tombstonesTable = 'tombstones';

/// Page size for the paginated reads. Each state's whole delta is collected by
/// cursor-paging until a short page, so a delta larger than one page is never
/// silently truncated (which would corrupt the high-water cursor).
const int _pageSize = 100;

/// `sync-pull` Appwrite Function entrypoint (Dart runtime).
///
/// Accepts one `{table, since?}` pull (same wire shape as the Convex
/// `sync:pullRecords` query) and returns `{upserts, deletes, cursor}` — the
/// delta changed since `since` plus the server high-water cursor — via [pull].
/// The delta core is pure and separately unit-tested; this handler is the thin
/// IO glue: authenticate the caller, wire a paginating [TablesDbPullStore],
/// marshal the response.
///
/// `userId` is taken from the trusted `x-appwrite-user-id` header (stamped by
/// Appwrite for an authenticated invocation) — never from the payload — so a
/// caller can only ever pull their own rows.
Future<dynamic> main(final dynamic context) async {
  final userId = _header(context, 'x-appwrite-user-id');
  if (userId.isEmpty) {
    return context.res.json(
      <String, dynamic>{'error': 'unauthenticated: missing x-appwrite-user-id'},
      401,
    );
  }

  final client = Client()
      .setEndpoint(Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT'] ?? '')
      .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'] ?? '')
      .setKey(_header(context, 'x-appwrite-key'));
  final store = TablesDbPullStore(TablesDB(client), _databaseId);

  final PullRequest request;
  try {
    request = PullRequest.fromJson(_bodyMap(context.req.bodyJson));
  } on PullRejection catch (e) {
    return context.res.json(
      <String, dynamic>{'error': e.message},
      400,
    );
  }

  try {
    final delta = await pull(store, userId, request);
    return context.res.json(delta.toJson());
  } on PullRejection catch (e) {
    return context.res.json(
      <String, dynamic>{'error': e.message},
      400,
    );
  }
}

/// Read a request header, defaulting to `''`. Header keys are lowercase.
String _header(final dynamic context, final String name) {
  final Object? value = context.req.headers[name];
  return value is String ? value : '';
}

Map<String, dynamic> _bodyMap(final Object? body) =>
    body is Map ? body.cast<String, dynamic>() : <String, dynamic>{};

/// [PullStore] backed by Appwrite TablesDB. Live descriptive rows are read from
/// the entity table via the `by_user_updatedAt` index; tombstones from the
/// shared `tombstones` table via `by_user_entity_deletedAt` (both authored in
/// task 1.1). Each state is ordered by its clock and cursor-paged to completion,
/// so the union covers the full delta regardless of size.
class TablesDbPullStore implements PullStore {
  TablesDbPullStore(this._db, this._databaseId);

  final TablesDB _db;
  final String _databaseId;

  @override
  Future<List<LiveRecord>> listLiveSince(
    final String table,
    final String userId,
    final int? since,
  ) async {
    final out = <LiveRecord>[];
    String? cursor;
    while (true) {
      final page = await _db.listRows(
        databaseId: _databaseId,
        tableId: table,
        queries: [
          Query.equal('userId', userId),
          if (since != null) Query.greaterThan('updatedAt', since),
          Query.orderAsc('updatedAt'),
          Query.limit(_pageSize),
          if (cursor != null) Query.cursorAfter(cursor),
        ],
      );
      for (final row in page.rows) {
        out.add(
          LiveRecord(
            id: _str(row.data['id']),
            json: _decodePayload(row.data['payload']),
            updatedAt: _asInt(row.data['updatedAt']),
            clientOpId: _str(row.data['clientOpId']),
          ),
        );
      }
      if (page.rows.length < _pageSize) {
        break;
      }
      cursor = page.rows.last.$id;
    }
    return out;
  }

  @override
  Future<List<TombstoneRecord>> listTombstonesSince(
    final String table,
    final String userId,
    final int? since,
  ) async {
    final out = <TombstoneRecord>[];
    String? cursor;
    while (true) {
      final page = await _db.listRows(
        databaseId: _databaseId,
        tableId: _tombstonesTable,
        queries: [
          Query.equal('userId', userId),
          Query.equal('entityType', table),
          if (since != null) Query.greaterThan('deletedAt', since),
          Query.orderAsc('deletedAt'),
          Query.limit(_pageSize),
          if (cursor != null) Query.cursorAfter(cursor),
        ],
      );
      for (final row in page.rows) {
        out.add(
          TombstoneRecord(
            id: _str(row.data['id']),
            deletedAt: _asInt(row.data['deletedAt']),
            clientOpId: _str(row.data['clientOpId']),
          ),
        );
      }
      if (page.rows.length < _pageSize) {
        break;
      }
      cursor = page.rows.last.$id;
    }
    return out;
  }

  Map<String, dynamic> _decodePayload(final Object? v) {
    if (v is! String || v.isEmpty) {
      return <String, dynamic>{};
    }
    final Object? decoded = jsonDecode(v);
    return decoded is Map ? decoded.cast<String, dynamic>() : <String, dynamic>{};
  }

  String _str(final Object? v) => v is String ? v : '';

  int _asInt(final Object? v) => v is int ? v : (v as num).toInt();
}
