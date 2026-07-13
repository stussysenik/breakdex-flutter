import 'package:breakdex/core/config/entitlement.dart';
import 'package:breakdex/core/config/remote_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const entitled = Entitlement(tier: 'crew', cohort: 'crew', source: 'invite');

  EntitlementGate gate({
    final bool gateEnabled = true,
    final bool isReleaseBuild = true,
    final bool isOwner = false,
    final bool isGrandfathered = false,
    final Entitlement? entitlement,
  }) =>
      EntitlementGate.evaluate(
        gateEnabled: gateEnabled,
        isReleaseBuild: isReleaseBuild,
        isOwner: isOwner,
        isGrandfathered: isGrandfathered,
        entitlement: entitlement,
      );

  group('EntitlementGate.evaluate — blocks only the un-exempt released case', () {
    test('released + enabled + no entitlement + no exemption → required', () {
      expect(gate(), isA<EntitlementRequired>());
    });

    test('an entitled user is always granted', () {
      expect(gate(entitlement: entitled), isA<EntitlementGranted>());
    });
  });

  group('EntitlementGate.evaluate — the gate never blocks exempt users', () {
    test('flag off → granted (the inert default)', () {
      expect(gate(gateEnabled: false), isA<EntitlementGranted>());
    });

    test('non-release / dev build → granted', () {
      expect(gate(isReleaseBuild: false), isA<EntitlementGranted>());
    });

    test('the owner account → granted', () {
      expect(gate(isOwner: true), isA<EntitlementGranted>());
    });

    test('a grandfathered existing device user → granted', () {
      expect(gate(isGrandfathered: true), isA<EntitlementGranted>());
    });
  });

  group('Entitlement.tryFrom — tolerant parsing', () {
    test('a well-formed row parses', () {
      final e = Entitlement.tryFrom(<String, Object?>{
        'tier': 'crew',
        'cohort': 'crew',
        'source': 'invite',
        'code': 'CREW-1',
      });
      expect(e?.tier, 'crew');
      expect(e?.cohort, 'crew');
      expect(e?.code, 'CREW-1');
    });

    test('a row missing tier/cohort reads as no entitlement (null)', () {
      expect(Entitlement.tryFrom(<String, Object?>{'source': 'invite'}), isNull);
    });
  });

  group('cohort → remote-config binding (the "my own versions" proof)', () {
    const config = RemoteConfig(
      version: 1,
      minSupportedBuild: 0,
      latestBuild: 0,
      updateMessage: null,
      featureFlags: <String, Object?>{'newDrillUi': false},
      killSwitches: <String, Object?>{},
      cohortProfiles: <String, Map<String, Object?>>{
        'crew': <String, Object?>{'newDrillUi': true},
      },
      updatedAt: 0,
    );

    test("a redeemed cohort's profile overrides the base flag", () {
      // Base (no cohort) sees the flag off; the crew cohort — bound by a redeemed
      // crew entitlement — sees the crew profile's override on.
      expect(config.flag('newDrillUi'), isFalse);
      expect(config.flag('newDrillUi', cohort: entitled.cohort), isTrue);
    });

    test('a cohort without an override falls back to the base flag', () {
      expect(config.flag('newDrillUi', cohort: 'beta'), isFalse);
    });
  });
}
