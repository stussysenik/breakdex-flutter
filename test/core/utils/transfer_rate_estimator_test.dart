import 'package:breakdex/core/utils/app_clock.dart';
import 'package:breakdex/core/utils/transfer_rate_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controllable clock so rate/ETA math is deterministic under test.
class _FakeClock implements AppClock {
  Duration t = Duration.zero;

  @override
  Duration get monotonic => t;

  @override
  DateTime nowUtc() => DateTime.utc(2020);
}

void main() {
  group('TransferRateEstimator', () {
    late _FakeClock clock;
    late TransferRateEstimator estimator;

    setUp(() {
      clock = _FakeClock();
      estimator = TransferRateEstimator(clock: clock);
    });

    test('no rate or ETA before a second sample', () {
      estimator.record(0, 1000);
      expect(estimator.bytesPerSecond, 0);
      expect(estimator.etaRemaining, isNull);
      expect(estimator.isStalled, isFalse);
    });

    test('computes a steady rate and ETA', () {
      estimator.record(0, 1000);
      clock.t = const Duration(seconds: 1);
      estimator.record(100, 1000); // 100 B in 1s -> 100 B/s

      expect(estimator.bytesPerSecond, closeTo(100, 0.001));
      // 900 bytes remaining at 100 B/s -> ~9s.
      expect(estimator.etaRemaining!.inSeconds, 9);
    });

    test('ETA is zero once complete', () {
      estimator.record(0, 1000);
      clock.t = const Duration(seconds: 1);
      estimator.record(1000, 1000);
      expect(estimator.etaRemaining, Duration.zero);
      expect(estimator.isStalled, isFalse);
    });

    test('detects a stall when no forward progress passes the threshold', () {
      estimator.record(0, 1000);
      clock.t = const Duration(seconds: 1);
      estimator.record(100, 1000);

      // No more progress; advance well past the default 6s stall window.
      clock.t = const Duration(seconds: 8);
      expect(estimator.isStalled, isTrue);
    });

    test('reset clears all state', () {
      estimator.record(0, 1000);
      clock.t = const Duration(seconds: 1);
      estimator.record(500, 1000);
      estimator.reset();

      expect(estimator.bytesPerSecond, 0);
      expect(estimator.etaRemaining, isNull);
      expect(estimator.isStalled, isFalse);
    });
  });

  group('formatting helpers', () {
    test('formatTransferEta', () {
      expect(formatTransferEta(const Duration(seconds: 0)), 'almost done');
      expect(formatTransferEta(const Duration(seconds: 9)), '9s left');
      expect(formatTransferEta(const Duration(seconds: 90)), '1m 30s left');
    });

    test('formatBytes uses binary units', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(2048), '2 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    });
  });
}
