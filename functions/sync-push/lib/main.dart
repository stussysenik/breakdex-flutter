import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'reconcile.dart';

/// Database id — matches the `breakdex` TablesDB in `appwrite.config.json`.
const String _databaseId = 'breakdex';

/// The shared soft-delete table (schema table `$id`).
const String _tombstonesTable = 'tombstones';

/// `sync-push` Appwrite Function entrypoint (Dart runtime).
///
/// Accepts one batched `{table, upserts, deletes}` push (same wire shape as the
/// Convex `sync:pushRecords` mutation) and applies it with server-side
/// last-writer-wins + tombstones + idempotency via [applyPush]. The reconcile
/// core is pure and separately unit-tested; this handler is the thin IO glue:
/// authenticate the caller, wire a [TablesDbSyncStore], marshal the response.
///
/// `userId` is taken from the trusted `x-appwrite-user-id` header (stamped by
/// Appwrite for an authenticated invocation) — never from the payload — so
/// every row is written under that user's identity and per-row permissions.
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
  final store = TablesDbSyncStore(TablesDB(client), _databaseId);

  final PushRequest request;
  try {
    request = PushRequest.fromJson(_bodyMap(context.req.bodyJson));
  } on PushRejection catch (e) {
    return context.res.json(
      <String, dynamic>{'error': e.message},
      400,
    );
  }

  try {
    final result = await applyPush(
      store,
      userId,
      request,
      onError: (final message) => context.error(message),
    );
    return context.res.json(<String, dynamic>{
      'applied': result.applied,
      'skipped': result.skipped,
      'failed': result.failed,
    });
  } on PushRejection catch (e) {
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

/// [SyncStore] backed by Appwrite TablesDB. A live descriptive row and its
/// tombstone are located by the trusted `(userId, id)` pair through the
/// `by_user_id` index (authored in task 1.1), mirroring the Convex
/// `withIndex('by_localId').unique()` lookup. Writes stamp owner-only per-row
/// permissions so a user can only ever read/write their own records.
class TablesDbSyncStore implements SyncStore {
  TablesDbSyncStore(this._db, this._databaseId);

  final TablesDB _db;
  final String _databaseId;

  @override
  Future<StoredRow?> getLive(
    final String table,
    final String userId,
    final String id,
  ) async {
    final rows = await _db.listRows(
      databaseId: _databaseId,
      tableId: table,
      queries: [
        Query.equal('userId', userId),
        Query.equal('id', id),
        Query.limit(1),
      ],
    );
    if (rows.rows.isEmpty) {
      return null;
    }
    final row = rows.rows.first;
    return StoredRow(ref: row.$id, clock: _asInt(row.data['updatedAt']));
  }

  @override
  Future<StoredRow?> getTombstone(
    final String table,
    final String userId,
    final String id,
  ) async {
    final rows = await _db.listRows(
      databaseId: _databaseId,
      tableId: _tombstonesTable,
      queries: [
        Query.equal('userId', userId),
        Query.equal('entityType', table),
        Query.equal('id', id),
        Query.limit(1),
      ],
    );
    if (rows.rows.isEmpty) {
      return null;
    }
    final row = rows.rows.first;
    return StoredRow(ref: row.$id, clock: _asInt(row.data['deletedAt']));
  }

  @override
  Future<void> createLive(
    final String table, {
    required final String userId,
    required final String id,
    required final int updatedAt,
    required final String clientOpId,
    required final Map<String, dynamic> json,
  }) async {
    await _db.createRow(
      databaseId: _databaseId,
      tableId: table,
      rowId: ID.unique(),
      data: <String, dynamic>{
        'id': id,
        'userId': userId,
        'updatedAt': updatedAt,
        'clientOpId': clientOpId,
        'payload': jsonEncode(json),
      },
      permissions: _ownerOnly(userId),
    );
  }

  @override
  Future<void> updateLive(
    final String table,
    final String ref, {
    required final int updatedAt,
    required final String clientOpId,
    required final Map<String, dynamic> json,
  }) async {
    await _db.updateRow(
      databaseId: _databaseId,
      tableId: table,
      rowId: ref,
      data: <String, dynamic>{
        'updatedAt': updatedAt,
        'clientOpId': clientOpId,
        'payload': jsonEncode(json),
      },
    );
  }

  @override
  Future<void> deleteLive(final String table, final String ref) async {
    await _db.deleteRow(
      databaseId: _databaseId,
      tableId: table,
      rowId: ref,
    );
  }

  @override
  Future<void> createTombstone(
    final String table, {
    required final String userId,
    required final String id,
    required final int deletedAt,
    required final String clientOpId,
  }) async {
    await _db.createRow(
      databaseId: _databaseId,
      tableId: _tombstonesTable,
      rowId: ID.unique(),
      data: <String, dynamic>{
        'id': id,
        'entityType': table,
        'userId': userId,
        'deletedAt': deletedAt,
        'clientOpId': clientOpId,
      },
      permissions: _ownerOnly(userId),
    );
  }

  @override
  Future<void> updateTombstone(
    final String table,
    final String ref, {
    required final int deletedAt,
    required final String clientOpId,
  }) async {
    await _db.updateRow(
      databaseId: _databaseId,
      tableId: _tombstonesTable,
      rowId: ref,
      data: <String, dynamic>{
        'deletedAt': deletedAt,
        'clientOpId': clientOpId,
      },
    );
  }

  @override
  Future<void> deleteTombstone(final String table, final String ref) async {
    await _db.deleteRow(
      databaseId: _databaseId,
      tableId: _tombstonesTable,
      rowId: ref,
    );
  }

  List<String> _ownerOnly(final String userId) => [
    Permission.read(Role.user(userId)),
    Permission.update(Role.user(userId)),
    Permission.delete(Role.user(userId)),
  ];

  int _asInt(final Object? v) => v is int ? v : (v as num).toInt();
}
