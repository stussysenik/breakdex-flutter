import 'package:flutter_test/flutter_test.dart';
import 'package:breakdex/features/video_editor/trim_timeline_math.dart';

void main() {
  group('snapNormalizedToDuration', () {
    test('snaps correctly with 1ms quantum', () {
      // 0.5 * 1000 = 500
      expect(snapNormalizedToDuration(0.5, 1000, quantumMs: 1), 0.5);
      // 0.5004 * 1000 = 500
      expect(snapNormalizedToDuration(0.5004, 1000, quantumMs: 1), 0.5);
      // 0.5006 * 1000 = 500.6 -> 501
      expect(snapNormalizedToDuration(0.5006, 1000, quantumMs: 1), 0.501);
    });

    test('snaps correctly with 10ms quantum', () {
      // 0.504 * 1000 = 504 -> snaps to 500
      expect(snapNormalizedToDuration(0.504, 1000, quantumMs: 10), 0.5);
      // 0.506 * 1000 = 506 -> snaps to 510
      expect(snapNormalizedToDuration(0.506, 1000, quantumMs: 10), 0.51);
    });

    test('handles boundaries', () {
      expect(snapNormalizedToDuration(-0.1, 1000, quantumMs: 1), 0.0);
      expect(snapNormalizedToDuration(1.1, 1000, quantumMs: 1), 1.0);
    });

    test('handles zero or invalid duration gracefully', () {
      expect(snapNormalizedToDuration(0.5, 0), 0.5);
      expect(snapNormalizedToDuration(0.5, -100), 0.5);
    });
  });

  group('applyRawDrag', () {
    test('updates raw drag within bounds', () {
      final res = applyRawDrag(
        currentRaw: 0.5,
        deltaDx: 10,
        timelineWidth: 100,
        verticalLiftPx: 0,
        minValue: 0.0,
        maxValue: 1.0,
      );
      // 0.5 + 10/100 = 0.6
      expect(res, closeTo(0.6, 0.001));
    });

    test('clamps to min/max', () {
      final resMax = applyRawDrag(
        currentRaw: 0.9,
        deltaDx: 20,
        timelineWidth: 100,
        verticalLiftPx: 0,
        minValue: 0.0,
        maxValue: 1.0,
      );
      expect(resMax, 1.0);

      final resMin = applyRawDrag(
        currentRaw: 0.1,
        deltaDx: -20,
        timelineWidth: 100,
        verticalLiftPx: 0,
        minValue: 0.0,
        maxValue: 1.0,
      );
      expect(resMin, 0.0);
    });

    test('reduces sensitivity when lifted', () {
      final resNormal = applyRawDrag(
        currentRaw: 0.5,
        deltaDx: 10,
        timelineWidth: 100,
        verticalLiftPx: 0,
        minValue: 0.0,
        maxValue: 1.0,
      );
      final resLifted = applyRawDrag(
        currentRaw: 0.5,
        deltaDx: 10,
        timelineWidth: 100,
        verticalLiftPx: 200, // Very lifted
        minValue: 0.0,
        maxValue: 1.0,
      );
      // Normal sensitivity should be ~1.0
      // Lifted sensitivity should be less than 1.0, so the delta is smaller.
      expect(resLifted - 0.5, lessThan(resNormal - 0.5));
    });
  });

  group('applyTrimHandleDrag', () {
    test('combines drag and snapping', () {
      final res = applyTrimHandleDrag(
        currentValue: 0.5,
        deltaDx: 10,
        timelineWidth: 100,
        verticalLiftPx: 0,
        minValue: 0.0,
        maxValue: 1.0,
        durationMs: 1000,
        quantumMs: 100, // 0.1 normalized steps
      );
      // raw = 0.5 + 10/100 = 0.6. Snaps to nearest 100ms.
      expect(res, 0.6);
    });
  });
}
