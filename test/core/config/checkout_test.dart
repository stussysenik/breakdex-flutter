import 'package:breakdex/core/config/checkout.dart';
import 'package:breakdex/core/config/entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kOfferings — the three one-time tiers (0.2 ruling)', () {
    test('are supporter/standard/patron at 4.20/6.99/9.99', () {
      expect(kOfferings.map((final o) => o.tier),
          containsAll(<String>['supporter', 'standard', 'patron']));
      expect(kOfferings.firstWhere((final o) => o.tier == 'supporter').priceUsd,
          '4.20');
      expect(kOfferings.firstWhere((final o) => o.tier == 'standard').priceUsd,
          '6.99');
      expect(kOfferings.firstWhere((final o) => o.tier == 'patron').priceUsd,
          '9.99');
    });
  });

  group('checkoutUrlFor — pure URL builder', () {
    test('returns null when the store/variant is unconfigured (default build)', () {
      // No --dart-define in the test build ⇒ no buy links (rather than dead ones).
      expect(checkoutUrlFor('patron', userId: 'user-1'), isNull);
    });
  });

  group('Entitlement.tryFrom — a revoked purchase re-locks (lockout not loss)', () {
    test('status: revoked reads as no entitlement', () {
      final revoked = Entitlement.tryFrom(<String, Object?>{
        'tier': 'patron',
        'cohort': 'patron',
        'source': 'purchase',
        'status': 'revoked',
      });
      expect(revoked, isNull); // gated again, but the row/data still exist server-side
    });

    test('status: active (or absent) still parses', () {
      final active = Entitlement.tryFrom(<String, Object?>{
        'tier': 'patron',
        'cohort': 'patron',
        'source': 'purchase',
        'status': 'active',
      });
      expect(active?.tier, 'patron');
      final legacy = Entitlement.tryFrom(<String, Object?>{
        'tier': 'crew',
        'cohort': 'crew',
        'source': 'invite',
      });
      expect(legacy?.tier, 'crew'); // no status column ⇒ active
    });
  });
}
