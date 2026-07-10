import 'package:breakdex/core/config/remote_config.dart';
import 'package:breakdex/core/config/update_gate.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture config with only the gate-relevant bounds set; everything else inert.
RemoteConfig _config({
  final int minSupportedBuild = 0,
  final int latestBuild = 0,
  final String? updateMessage,
}) => RemoteConfig(
  version: 1,
  minSupportedBuild: minSupportedBuild,
  latestBuild: latestBuild,
  updateMessage: updateMessage,
  featureFlags: const {},
  killSwitches: const {},
  cohortProfiles: const {},
  updatedAt: 0,
);

void main() {
  group('UpdateGate.evaluate', () {
    test('defaults are inert — no gate for any non-negative build', () {
      const config = RemoteConfig.defaults();
      for (final build in [0, 1, 3, 9999]) {
        expect(
          UpdateGate.evaluate(config: config, currentBuild: build),
          isA<UpdateGateNone>(),
          reason: 'build $build against defaults must not gate',
        );
      }
    });

    test('hard block when build is strictly below minSupportedBuild', () {
      final gate = UpdateGate.evaluate(
        config: _config(minSupportedBuild: 5),
        currentBuild: 4,
      );
      expect(gate, isA<UpdateGateHardBlock>());
    });

    test('never blocks while minSupportedBuild <= currentBuild (boundary)', () {
      // Equal build: the acceptance invariant — the floor is inclusive.
      expect(
        UpdateGate.evaluate(
          config: _config(minSupportedBuild: 5),
          currentBuild: 5,
        ),
        isA<UpdateGateNone>(),
      );
      // Above the floor: also never a hard block.
      expect(
        UpdateGate.evaluate(
          config: _config(minSupportedBuild: 5),
          currentBuild: 6,
        ),
        isNot(isA<UpdateGateHardBlock>()),
      );
    });

    test('soft nag when supported but a newer build exists', () {
      final gate = UpdateGate.evaluate(
        config: _config(minSupportedBuild: 1, latestBuild: 8),
        currentBuild: 5,
      );
      expect(gate, isA<UpdateGateSoftNag>());
    });

    test('no nag when running the latest build', () {
      final gate = UpdateGate.evaluate(
        config: _config(minSupportedBuild: 1, latestBuild: 5),
        currentBuild: 5,
      );
      expect(gate, isA<UpdateGateNone>());
    });

    test('hard block takes precedence over a soft nag', () {
      // Below floor AND behind latest — must block, not merely nag.
      final gate = UpdateGate.evaluate(
        config: _config(minSupportedBuild: 5, latestBuild: 9),
        currentBuild: 3,
      );
      expect(gate, isA<UpdateGateHardBlock>());
    });

    group('messaging', () {
      test('uses the owner-authored updateMessage when present', () {
        final gate = UpdateGate.evaluate(
          config: _config(minSupportedBuild: 5, updateMessage: 'Reinstall from the invite link.'),
          currentBuild: 1,
        );
        expect(
          (gate as UpdateGateHardBlock).message,
          'Reinstall from the invite link.',
        );
      });

      test('falls back to default copy when updateMessage is null', () {
        final gate = UpdateGate.evaluate(
          config: _config(minSupportedBuild: 5),
          currentBuild: 1,
        );
        expect((gate as UpdateGateHardBlock).message, isNotEmpty);
      });

      test('falls back to default copy when updateMessage is blank', () {
        final gate = UpdateGate.evaluate(
          config: _config(minSupportedBuild: 5, updateMessage: '   '),
          currentBuild: 1,
        );
        final message = (gate as UpdateGateHardBlock).message;
        expect(message.trim(), isNotEmpty);
        expect(message.contains('no longer supported'), isTrue);
      });

      test('trims surrounding whitespace from a real message', () {
        final gate = UpdateGate.evaluate(
          config: _config(minSupportedBuild: 1, latestBuild: 8, updateMessage: '  New drills await  '),
          currentBuild: 5,
        );
        expect((gate as UpdateGateSoftNag).message, 'New drills await');
      });
    });
  });
}
