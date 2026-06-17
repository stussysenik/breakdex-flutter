import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/utils/app_clock.dart';
import 'package:breakdex/core/utils/diagnostics.dart';
import 'package:breakdex/core/utils/stall_detector.dart';

/// Controllable clock: tests advance it in lockstep with `tester.pump` so the
/// detector's periodic timer and its elapsed-time math agree without real waits.
class _FakeClock implements AppClock {
  Duration _monotonic = Duration.zero;

  void advance(final Duration d) => _monotonic += d;

  @override
  DateTime nowUtc() => DateTime.utc(2026, 1, 1).add(_monotonic);

  @override
  Duration get monotonic => _monotonic;
}

void main() {
  const subsystem = 'StallDetectorTest';
  const tick = Duration(milliseconds: 500);

  /// Runs [body] with DiagnosticsLog output captured into the returned list
  /// (StageLogger.stage logs at debug level, below the default threshold).
  Future<List<String>> capturingLogs(
    final Future<void> Function(_FakeClock clock, StallDetector detector) body,
  ) async {
    DiagnosticsLog.setSubsystemThreshold(subsystem, LogLevel.trace);
    final lines = <String>[];
    final original = debugPrint;
    debugPrint = (final String? message, {final int? wrapWidth}) {
      lines.add(message ?? '');
    };
    try {
      final clock = _FakeClock();
      final detector = StallDetector(
        log: StageLogger.begin('Import', subsystem: subsystem),
        clock: clock,
      )..start();
      try {
        await body(clock, detector);
      } finally {
        detector.stop();
      }
    } finally {
      debugPrint = original;
    }
    return lines;
  }

  Future<void> elapse(
    final WidgetTester tester,
    final _FakeClock clock,
    final int ticks,
  ) async {
    for (var i = 0; i < ticks; i++) {
      clock.advance(tick);
      await tester.pump(tick);
    }
  }

  group('StallDetector', () {
    testWidgets('steady progress never logs a stall', (final tester) async {
      final lines = await capturingLogs((final clock, final detector) async {
        for (var i = 1; i <= 8; i++) {
          await elapse(tester, clock, 1);
          detector.note(i * 0.1);
        }
      });

      expect(lines.where((final l) => l.contains('stalled')), isEmpty);
      expect(lines.where((final l) => l.contains('recovered')), isEmpty);
    });

    testWidgets('logs one stalled entry after 2s without advance',
        (final tester) async {
      final lines = await capturingLogs((final clock, final detector) async {
        detector.note(0.3);
        await elapse(tester, clock, 6); // 3s frozen
      });

      final stalls =
          lines.where((final l) => l.contains('stalled')).toList();
      expect(stalls, hasLength(1));
      expect(stalls.single, contains('progress=0.3'));
      expect(stalls.single, contains('frozenMs=2000'));
    });

    testWidgets('logs recovery when progress advances after a stall',
        (final tester) async {
      final lines = await capturingLogs((final clock, final detector) async {
        detector.note(0.3);
        await elapse(tester, clock, 5); // 2.5s frozen → stalled
        detector.note(0.4); // advance → recovered
        await elapse(tester, clock, 1); // no second stall right away
      });

      expect(lines.where((final l) => l.contains('stalled ')).length, 1);
      final recoveries =
          lines.where((final l) => l.contains('recovered')).toList();
      expect(recoveries, hasLength(1));
      expect(recoveries.single, contains('progress=0.4'));
      expect(recoveries.single, contains('stalledMs=2500'));
    });

    testWidgets('repeated identical values do not reset the stall window',
        (final tester) async {
      final lines = await capturingLogs((final clock, final detector) async {
        detector.note(0.5);
        await elapse(tester, clock, 2);
        detector.note(0.5); // same value — not an advance
        await elapse(tester, clock, 2); // 2s since the real advance
      });

      expect(lines.where((final l) => l.contains('stalled')), hasLength(1));
      expect(lines.where((final l) => l.contains('recovered')), isEmpty);
    });
  });
}
