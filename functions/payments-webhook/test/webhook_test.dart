import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:payments_webhook/webhook.dart';
import 'package:test/test.dart';

/// In-memory [PaymentsStore] double — mirrors the TablesDB store's `orderId`
/// lookup, grant, and revoke with no live backend.
class FakePaymentsStore implements PaymentsStore {
  final List<PurchaseEntitlement> entitlements = <PurchaseEntitlement>[];

  @override
  Future<PurchaseEntitlement?> findByOrder(final String orderId) async {
    for (final e in entitlements) {
      if (e.orderId == orderId) {
        return e;
      }
    }
    return null;
  }

  @override
  Future<void> grant(final PurchaseEntitlement entitlement) async {
    entitlements.add(entitlement);
  }

  @override
  Future<void> revoke(final String orderId) async {
    final i = entitlements.indexWhere((final e) => e.orderId == orderId);
    if (i < 0) {
      return;
    }
    final old = entitlements[i];
    entitlements[i] = PurchaseEntitlement(
      userId: old.userId,
      tier: old.tier,
      orderId: old.orderId,
      grantedAt: old.grantedAt,
      status: 'revoked',
    );
  }
}

const int _now = 1_700_000_000_000;

String? _tierFor(final String variantId) =>
    variantId == 'v-patron' ? 'patron' : null;

Map<String, dynamic> _body({
  final String eventName = 'order_created',
  final String userId = 'user-1',
  final String orderId = 'ord-1',
  final String variantId = 'v-patron',
}) =>
    <String, dynamic>{
      'meta': <String, dynamic>{
        'event_name': eventName,
        'custom_data': <String, dynamic>{'user_id': userId},
      },
      'data': <String, dynamic>{
        'id': orderId,
        'attributes': <String, dynamic>{
          'first_order_item': <String, dynamic>{'variant_id': variantId},
        },
      },
    };

WebhookEvent _event(final Map<String, dynamic> body) =>
    WebhookEvent.fromJson(body);

void main() {
  group('verifySignature — HMAC gate', () {
    const secret = 'whsec_test';
    final raw = jsonEncode(_body());
    final good = Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode(raw))
        .toString();

    test('accepts a correct signature', () {
      expect(
        verifySignature(rawBody: raw, signature: good, secret: secret),
        isTrue,
      );
    });

    test('rejects a forged signature', () {
      expect(
        verifySignature(rawBody: raw, signature: 'deadbeef', secret: secret),
        isFalse,
      );
    });

    test('rejects a tampered body (same signature, changed payload)', () {
      final tampered = jsonEncode(_body(userId: 'attacker'));
      expect(
        verifySignature(rawBody: tampered, signature: good, secret: secret),
        isFalse,
      );
    });

    test('fails closed on an empty secret or signature', () {
      expect(verifySignature(rawBody: raw, signature: good, secret: ''), isFalse);
      expect(verifySignature(rawBody: raw, signature: '', secret: secret), isFalse);
    });
  });

  group('applyWebhook — grant + idempotency', () {
    test('order_created grants the mapped-tier purchase entitlement', () async {
      final store = FakePaymentsStore();
      final outcome = await applyWebhook(
        store,
        _event(_body()),
        tierForVariant: _tierFor,
        now: _now,
      );

      expect(outcome, WebhookOutcome.granted);
      expect(store.entitlements, hasLength(1));
      final e = store.entitlements.single;
      expect(e.tier, 'patron');
      expect(e.orderId, 'ord-1');
      expect(e.status, 'active');
    });

    test('a replayed order is alreadyProcessed (no duplicate grant)', () async {
      final store = FakePaymentsStore();
      final e = _event(_body());
      await applyWebhook(store, e, tierForVariant: _tierFor, now: _now);
      final replay =
          await applyWebhook(store, e, tierForVariant: _tierFor, now: _now + 1000);

      expect(replay, WebhookOutcome.alreadyProcessed);
      expect(store.entitlements, hasLength(1));
    });

    test('an unmapped variant is ignored (not one of our offerings)', () async {
      final store = FakePaymentsStore();
      final outcome = await applyWebhook(
        store,
        _event(_body(variantId: 'v-unknown')),
        tierForVariant: _tierFor,
        now: _now,
      );

      expect(outcome, WebhookOutcome.ignored);
      expect(store.entitlements, isEmpty);
    });
  });

  group('applyWebhook — refund downgrades, never deletes', () {
    test('order_refunded revokes the entitlement but preserves the row', () async {
      final store = FakePaymentsStore();
      await applyWebhook(store, _event(_body()),
          tierForVariant: _tierFor, now: _now);

      final outcome = await applyWebhook(
        store,
        _event(_body(eventName: 'order_refunded')),
        tierForVariant: _tierFor,
        now: _now + 5000,
      );

      expect(outcome, WebhookOutcome.revoked);
      // Lockout not loss: the row still exists, only its status changed.
      expect(store.entitlements, hasLength(1));
      expect(store.entitlements.single.status, 'revoked');
      expect(store.entitlements.single.tier, 'patron'); // tier untouched
    });

    test('refunding an unknown order is ignored', () async {
      final store = FakePaymentsStore();
      final outcome = await applyWebhook(
        store,
        _event(_body(eventName: 'order_refunded', orderId: 'ord-none')),
        tierForVariant: _tierFor,
        now: _now,
      );
      expect(outcome, WebhookOutcome.ignored);
    });
  });

  group('WebhookEvent.fromJson — envelope validation', () {
    test('rejects a body with no event_name', () {
      expect(
        () => WebhookEvent.fromJson(<String, dynamic>{'data': <String, dynamic>{}}),
        throwsA(isA<WebhookRejection>()),
      );
    });

    test('rejects a body with no custom user_id', () {
      final body = _body()..['meta'] = <String, dynamic>{'event_name': 'order_created'};
      expect(
        () => WebhookEvent.fromJson(body),
        throwsA(isA<WebhookRejection>()),
      );
    });
  });
}
