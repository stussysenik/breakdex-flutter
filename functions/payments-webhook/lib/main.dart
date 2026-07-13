import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'webhook.dart';

/// Database id — matches the `breakdex` TablesDB in `appwrite.config.json`.
const String _databaseId = 'breakdex';

/// Per-user entitlement table (`$id` authored in task 2.1).
const String _entitlementsTable = 'entitlements';

/// `payments-webhook` Appwrite Function entrypoint (Dart runtime).
///
/// Receives Lemon Squeezy webhooks (0.1 ruling: LS as merchant-of-record).
/// Verifies the `X-Signature` HMAC over the raw body (fail-closed), parses the
/// event, and via [applyWebhook]: grants a purchase entitlement (idempotent per
/// LS order id) on `order_created`, or downgrades it to `revoked` on
/// `order_refunded` — never deleting user data ("lockout not loss"). The verify
/// + apply core is pure and separately unit-tested; this is the thin IO glue.
///
/// Owner-gated live config (env vars, set at provision time): the webhook secret
/// and the variant→tier map. Absent them, signatures fail closed and every
/// variant is unmapped (ignored) — so an unconfigured deploy is inert, not open.
Future<dynamic> main(final dynamic context) async {
  final rawBody = _rawBody(context);
  final signature = _header(context, 'x-signature');
  final secret = Platform.environment['LEMON_SQUEEZY_WEBHOOK_SECRET'] ?? '';

  if (!verifySignature(rawBody: rawBody, signature: signature, secret: secret)) {
    context.error('payments-webhook: signature verification failed');
    return context.res.json(<String, dynamic>{'error': 'invalid_signature'}, 401);
  }

  final WebhookEvent event;
  try {
    event = WebhookEvent.fromJson(_parse(rawBody));
  } on WebhookRejection catch (e) {
    return context.res.json(<String, dynamic>{'error': e.message}, 400);
  }

  final client = Client()
      .setEndpoint(Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT'] ?? '')
      .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'] ?? '')
      .setKey(_header(context, 'x-appwrite-key'));
  final store = TablesDbPaymentsStore(TablesDB(client), _databaseId);

  final WebhookOutcome outcome;
  try {
    outcome = await applyWebhook(
      store,
      event,
      tierForVariant: _variantToTier,
      now: DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  } on Object catch (e) {
    context.error('payments-webhook apply failed for order ${event.orderId}: $e');
    return context.res.json(<String, dynamic>{'error': 'apply_failed'}, 500);
  }

  // Always 200 to a validly-signed, well-formed event so LS does not retry a
  // successfully-handled (or intentionally-ignored) event; the outcome is logged.
  return context.res.json(<String, dynamic>{'outcome': outcome.name});
}

/// Resolve an LS variant id to one of our offering tiers, from env set at
/// provision time. Empty/unset → null (unmapped → ignored).
String? _variantToTier(final String variantId) {
  const mapping = <String, String>{
    'LEMON_SQUEEZY_VARIANT_SUPPORTER': 'supporter',
    'LEMON_SQUEEZY_VARIANT_STANDARD': 'standard',
    'LEMON_SQUEEZY_VARIANT_PATRON': 'patron',
  };
  for (final entry in mapping.entries) {
    final id = Platform.environment[entry.key];
    if (id != null && id.isNotEmpty && id == variantId) {
      return entry.value;
    }
  }
  return null;
}

String _rawBody(final dynamic context) {
  final Object? raw = context.req.bodyRaw;
  if (raw is String) {
    return raw;
  }
  final Object? text = context.req.bodyText;
  return text is String ? text : '';
}

String _header(final dynamic context, final String name) {
  final Object? value = context.req.headers[name];
  return value is String ? value : '';
}

Map<String, dynamic> _parse(final String raw) {
  if (raw.isEmpty) {
    return <String, dynamic>{};
  }
  final decoded = jsonDecode(raw);
  return decoded is Map ? decoded.cast<String, dynamic>() : <String, dynamic>{};
}

/// [PaymentsStore] backed by Appwrite TablesDB. Entitlements are located by the
/// LS `orderId` (`by_order` index) for idempotency; grants are written under
/// owner-only permissions for the purchasing user.
class TablesDbPaymentsStore implements PaymentsStore {
  TablesDbPaymentsStore(this._db, this._databaseId);

  final TablesDB _db;
  final String _databaseId;

  @override
  Future<PurchaseEntitlement?> findByOrder(final String orderId) async {
    final rows = await _db.listRows(
      databaseId: _databaseId,
      tableId: _entitlementsTable,
      queries: [Query.equal('orderId', orderId), Query.limit(1)],
    );
    if (rows.rows.isEmpty) {
      return null;
    }
    final data = rows.rows.first.data;
    return PurchaseEntitlement(
      userId: data['userId'] as String,
      tier: data['tier'] as String,
      orderId: orderId,
      grantedAt: _asInt(data['grantedAt']),
      status: (data['status'] as String?) ?? 'active',
    );
  }

  @override
  Future<void> grant(final PurchaseEntitlement entitlement) async {
    await _db.createRow(
      databaseId: _databaseId,
      tableId: _entitlementsTable,
      rowId: ID.unique(),
      data: entitlement.toData(),
      permissions: _ownerOnly(entitlement.userId),
    );
  }

  @override
  Future<void> revoke(final String orderId) async {
    final rows = await _db.listRows(
      databaseId: _databaseId,
      tableId: _entitlementsTable,
      queries: [Query.equal('orderId', orderId), Query.limit(1)],
    );
    if (rows.rows.isEmpty) {
      return;
    }
    // Data-safety: flip status only. No row/user data is ever deleted here.
    await _db.updateRow(
      databaseId: _databaseId,
      tableId: _entitlementsTable,
      rowId: rows.rows.first.$id,
      data: <String, dynamic>{'status': 'revoked'},
    );
  }

  List<String> _ownerOnly(final String userId) => [
        Permission.read(Role.user(userId)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ];

  int _asInt(final Object? v) => v is int ? v : (v as num).toInt();
}
