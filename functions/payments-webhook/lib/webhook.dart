/// Pure, provider-neutral core for the `payments-webhook` Appwrite Function.
/// Imports only `crypto` (deterministic) — no `dart_appwrite` — so signature
/// verification, Lemon Squeezy event parsing, idempotent grant, and refund
/// downgrade are unit-testable against an in-memory [PaymentsStore] with no live
/// backend, mirroring `invites-redeem`/`reviews-append`.
///
/// **Data safety (the "lockout not loss" rule).** A refund/chargeback NEVER
/// deletes a user's data. It flips their purchase entitlement's `status` to
/// `revoked` — the gate then treats them as un-entitled (locked out until they
/// re-purchase), but every move/combo/review they own is untouched. There is no
/// delete path in this Function.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A purchase entitlement — the same shape a redeemed invite grants, plus the
/// Lemon Squeezy `orderId` (idempotency key) and a `status`.
class PurchaseEntitlement {
  const PurchaseEntitlement({
    required this.userId,
    required this.tier,
    required this.orderId,
    required this.grantedAt,
    this.status = 'active',
  });

  final String userId;
  final String tier;
  final String orderId;
  final int grantedAt;
  final String status; // 'active' | 'revoked'

  /// Row data for the `entitlements` table. `cohort` mirrors the `tier` so a
  /// purchase tier can carry its own remote-config profile; `source` marks it a
  /// purchase (distinct from invite grants).
  Map<String, dynamic> toData() => <String, dynamic>{
        'userId': userId,
        'tier': tier,
        'cohort': tier,
        'source': 'purchase',
        'orderId': orderId,
        'status': status,
        'grantedAt': grantedAt,
      };
}

/// A parsed, relevant Lemon Squeezy webhook event.
class WebhookEvent {
  const WebhookEvent({
    required this.eventName,
    required this.userId,
    required this.orderId,
    required this.variantId,
  });

  /// Parse the LS webhook envelope. Throws [WebhookRejection] (→ 400) on a
  /// structurally invalid body. LS shape:
  /// `{ meta: { event_name, custom_data: { user_id } }, data: { id, attributes: { first_order_item: { variant_id } } } }`.
  factory WebhookEvent.fromJson(final Map<String, dynamic> body) {
    final meta = _asMap(body['meta']);
    final data = _asMap(body['data']);
    final eventName = meta['event_name'];
    if (eventName is! String || eventName.isEmpty) {
      throw const WebhookRejection('missing "meta.event_name".');
    }
    final custom = _asMap(meta['custom_data']);
    final userId = custom['user_id'];
    if (userId is! String || userId.isEmpty) {
      throw const WebhookRejection('missing "meta.custom_data.user_id".');
    }
    final orderId = data['id'];
    if (orderId is! String && orderId is! int) {
      throw const WebhookRejection('missing "data.id".');
    }
    final attrs = _asMap(data['attributes']);
    final item = _asMap(attrs['first_order_item']);
    final variant = item['variant_id'] ?? attrs['variant_id'];
    return WebhookEvent(
      eventName: eventName,
      userId: userId,
      orderId: '$orderId',
      variantId: variant == null ? '' : '$variant',
    );
  }

  final String eventName;
  final String userId;
  final String orderId;
  final String variantId;

  /// LS emits `order_refunded` for a refund/chargeback.
  bool get isRefund => eventName == 'order_refunded';

  /// A completed purchase worth granting on.
  bool get isPurchase => eventName == 'order_created';
}

/// The outcome of [applyWebhook], each mapped to an HTTP status in `main.dart`.
enum WebhookOutcome { granted, alreadyProcessed, revoked, ignored }

/// Raised on a malformed body (→ 400) — distinct from an invalid signature,
/// which `main.dart` rejects with 401 before parsing.
class WebhookRejection implements Exception {
  const WebhookRejection(this.message);

  final String message;

  @override
  String toString() => 'WebhookRejection: $message';
}

/// Storage seam the pure core drives (in-memory in tests, TablesDB in main).
abstract class PaymentsStore {
  /// The entitlement previously written for this `orderId`, or null.
  Future<PurchaseEntitlement?> findByOrder(final String orderId);

  /// Create the purchase entitlement under owner-only permissions.
  Future<void> grant(final PurchaseEntitlement entitlement);

  /// Flip the entitlement for `orderId` to `revoked` (data preserved).
  Future<void> revoke(final String orderId);
}

/// Verify a Lemon Squeezy `X-Signature` — HMAC-SHA256 hex of the raw body with
/// the webhook secret — in constant time. An empty secret or signature never
/// verifies (fail closed), so a misconfigured live secret rejects rather than
/// silently accepts.
bool verifySignature({
  required final String rawBody,
  required final String signature,
  required final String secret,
}) {
  if (secret.isEmpty || signature.isEmpty) {
    return false;
  }
  final digest = Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(rawBody));
  final expected = digest.toString(); // lowercase hex
  return _constantTimeEquals(expected, signature.toLowerCase());
}

/// Apply a [event] to the [store], resolving the variant to a tier via
/// [tierForVariant] (returns null for an unknown variant → ignored). Idempotent
/// per `orderId`: a replayed purchase whose active entitlement already exists is
/// [WebhookOutcome.alreadyProcessed]. A refund revokes (never deletes).
Future<WebhookOutcome> applyWebhook(
  final PaymentsStore store,
  final WebhookEvent event, {
  required final String? Function(String variantId) tierForVariant,
  required final int now,
}) async {
  if (event.isRefund) {
    final existing = await store.findByOrder(event.orderId);
    if (existing == null || existing.status == 'revoked') {
      return WebhookOutcome.ignored; // nothing to revoke / already revoked
    }
    await store.revoke(event.orderId);
    return WebhookOutcome.revoked;
  }

  if (!event.isPurchase) {
    return WebhookOutcome.ignored; // unrelated event (subscription pings, etc.)
  }

  final existing = await store.findByOrder(event.orderId);
  if (existing != null && existing.status == 'active') {
    return WebhookOutcome.alreadyProcessed; // idempotent replay
  }

  final tier = tierForVariant(event.variantId);
  if (tier == null || tier.isEmpty) {
    return WebhookOutcome.ignored; // unmapped variant — not one of our offerings
  }

  await store.grant(PurchaseEntitlement(
    userId: event.userId,
    tier: tier,
    orderId: event.orderId,
    grantedAt: now,
  ));
  return WebhookOutcome.granted;
}

Map<String, dynamic> _asMap(final Object? v) =>
    v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

bool _constantTimeEquals(final String a, final String b) {
  if (a.length != b.length) {
    return false;
  }
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
