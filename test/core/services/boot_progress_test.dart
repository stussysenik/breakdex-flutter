import 'package:breakdex/core/services/boot_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

BootState _state({
  required final Set<BootGate> gates,
  final bool ready = false,
  final bool complete = false,
  final Duration? expectedReady,
}) {
  return BootState(
    completedGates: gates,
    startTime: DateTime.utc(2020),
    isReadyForUI: ready,
    isComplete: complete,
    expectedReady: expectedReady,
  );
}

void main() {
  group('BootState progress math', () {
    test('coreFloor reflects only core gates and hits 1.0 when ready', () {
      final half = _state(
        gates: {BootGate.recovery, BootGate.preferences, BootGate.database},
      );
      // 3 of 5 core gates cleared (Firebase gate removed for release).
      expect(half.coreFloor, closeTo(0.6, 0.0001));

      final ready = _state(gates: kCoreBootGates, ready: true);
      expect(ready.coreFloor, 1.0);
    });

    test('postFrameProgress tracks only post-frame gates', () {
      final none = _state(gates: kCoreBootGates, ready: true);
      expect(none.postFrameProgress, 0.0);

      final some = _state(
        gates: {...kCoreBootGates, BootGate.migrations, BootGate.healing},
        ready: true,
      );
      // 2 of 3 post-frame gates done.
      expect(some.postFrameProgress, closeTo(2 / 3, 0.0001));
    });

    test('interpolatedProgress blends time with the gate floor', () {
      final s = _state(
        gates: {BootGate.recovery}, // 1/5 floor = 0.2
        expectedReady: const Duration(seconds: 10),
      );

      // Early: time-based 0.5 beats the gate floor.
      expect(
        s.interpolatedProgress(const Duration(seconds: 5)),
        closeTo(0.5, 0.0001),
      );
      // Capped below 1.0 until genuinely ready, even if time overruns.
      expect(
        s.interpolatedProgress(const Duration(seconds: 30)),
        closeTo(0.95, 0.0001),
      );
    });

    test('interpolatedProgress falls back to floor without calibration', () {
      final s = _state(gates: {BootGate.recovery, BootGate.preferences});
      expect(
        s.interpolatedProgress(const Duration(seconds: 5)),
        closeTo(2 / 5, 0.0001),
      );
    });

    test('eta counts down and clamps at zero', () {
      final s = _state(
        gates: {BootGate.recovery},
        expectedReady: const Duration(seconds: 10),
      );
      expect(s.eta(const Duration(seconds: 4)), const Duration(seconds: 6));
      expect(s.eta(const Duration(seconds: 20)), Duration.zero);
    });

    test('progress is 1.0 and eta null once ready', () {
      final s = _state(
        gates: kCoreBootGates,
        ready: true,
        expectedReady: const Duration(seconds: 10),
      );
      expect(s.interpolatedProgress(const Duration(seconds: 1)), 1.0);
      expect(s.eta(const Duration(seconds: 1)), isNull);
    });
  });
}
