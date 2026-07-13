import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'redeem.dart';

/// Database id — matches the `breakdex` TablesDB in `appwrite.config.json`.
const String _databaseId = 'breakdex';

/// Owner-minted invite table (`$id` authored in task 2.1).
const String _invitesTable = 'invites';

/// Per-user entitlement table (`$id` authored in task 2.1).
const String _entitlementsTable = 'entitlements';

/// `invites-redeem` Appwrite Function entrypoint (Dart runtime).
///
/// Accepts one `{ "code": "..." }` redeem and, via [redeemInvite]: idempotently
/// grants the caller the invite's entitlement (tier + cohort) and consumes one
/// use of the code — replays by the same user consume nothing further. The
/// redeem core is pure and separately unit-tested; this handler is the thin IO
/// glue: authenticate, wire a [TablesDbRedeemStore], marshal the response.
///
/// `userId` is taken from the trusted `x-appwrite-user-id` header — never the
/// payload — so the entitlement is written under that user's identity and
/// owner-only per-row permissions (a user reads only their own entitlement).
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
  final store = TablesDbRedeemStore(TablesDB(client), _databaseId);

  final RedeemRequest request;
  try {
    request = RedeemRequest.fromJson(_bodyMap(context.req.bodyJson));
  } on RedeemRejection catch (e) {
    return context.res.json(<String, dynamic>{'error': e.message}, 400);
  }

  final RedeemResult result;
  try {
    result = await redeemInvite(
      store,
      userId,
      request,
      now: DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  } on Object catch (e) {
    context.error('redeem failed for $userId: $e');
    return context.res.json(<String, dynamic>{'error': 'redeem_failed'}, 500);
  }

  final entitlement = result.entitlement;
  final body = <String, dynamic>{
    'status': result.status.name,
    if (entitlement != null) ...<String, dynamic>{
      'tier': entitlement.tier,
      'cohort': entitlement.cohort,
    },
  };
  // Grants → 200; typed rejections (invalid/expired/exhausted) → 409 Conflict.
  return context.res.json(body, result.isGrant ? 200 : 409);
}

/// Read a request header, defaulting to `''`. Header keys are lowercase.
String _header(final dynamic context, final String name) {
  final Object? value = context.req.headers[name];
  return value is String ? value : '';
}

Map<String, dynamic> _bodyMap(final Object? body) =>
    body is Map ? body.cast<String, dynamic>() : <String, dynamic>{};

/// [RedeemStore] backed by Appwrite TablesDB. Entitlements are located by the
/// trusted `(userId, code)` pair (idempotency, `by_user_code` index) and written
/// under owner-only permissions so a user can only ever read their own; invites
/// are located by `code` (`by_code` index) and their `uses` counter updated.
class TablesDbRedeemStore implements RedeemStore {
  TablesDbRedeemStore(this._db, this._databaseId);

  final TablesDB _db;
  final String _databaseId;

  @override
  Future<Entitlement?> findEntitlement(
    final String userId,
    final String code,
  ) async {
    final rows = await _db.listRows(
      databaseId: _databaseId,
      tableId: _entitlementsTable,
      queries: [
        Query.equal('userId', userId),
        Query.equal('code', code),
        Query.limit(1),
      ],
    );
    if (rows.rows.isEmpty) {
      return null;
    }
    final data = rows.rows.first.data;
    return Entitlement(
      userId: userId,
      tier: data['tier'] as String,
      cohort: data['cohort'] as String,
      source: data['source'] as String,
      grantedAt: _asInt(data['grantedAt']),
      code: data['code'] as String?,
    );
  }

  @override
  Future<Invite?> findInvite(final String code) async {
    final rows = await _db.listRows(
      databaseId: _databaseId,
      tableId: _invitesTable,
      queries: [Query.equal('code', code), Query.limit(1)],
    );
    if (rows.rows.isEmpty) {
      return null;
    }
    final row = rows.rows.first;
    final data = row.data;
    return Invite(
      rowId: row.$id,
      code: data['code'] as String,
      cohort: data['cohort'] as String,
      entitlementTier: data['entitlementTier'] as String,
      maxUses: _asInt(data['maxUses']),
      uses: _asInt(data['uses']),
      expiresAt: data['expiresAt'] == null ? null : _asInt(data['expiresAt']),
    );
  }

  @override
  Future<void> writeEntitlement(final Entitlement entitlement) async {
    await _db.createRow(
      databaseId: _databaseId,
      tableId: _entitlementsTable,
      rowId: ID.unique(),
      data: entitlement.toData(),
      permissions: _ownerOnly(entitlement.userId),
    );
  }

  @override
  Future<void> setInviteUses(final String inviteRowId, final int newUses) async {
    await _db.updateRow(
      databaseId: _databaseId,
      tableId: _invitesTable,
      rowId: inviteRowId,
      data: <String, dynamic>{'uses': newUses},
    );
  }

  List<String> _ownerOnly(final String userId) => [
        Permission.read(Role.user(userId)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ];

  int _asInt(final Object? v) => v is int ? v : (v as num).toInt();
}
