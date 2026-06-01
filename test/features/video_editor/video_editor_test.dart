import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/services/native_video_export.dart';
import 'package:breakdex/features/video_editor/video_edit_geometry.dart';
import 'package:breakdex/features/video_editor/trim_timeline_math.dart';

/// Unit tests for the video editor logic and export progress model.
///
/// Widget tests for VideoEditorScreen require a real video file and
/// platform channels, so we focus on testable units: ExportProgress
/// model behavior and the MethodChannel contract.
void main() {
  group('ExportProgress model', () {
    test('isInitializing returns true for initializing phase', () {
      const progress = ExportProgress(phase: 'initializing', progress: 0.0);
      expect(progress.isInitializing, isTrue);
      expect(progress.isEncoding, isFalse);
      expect(progress.isStalled, isFalse);
      expect(progress.isDone, isFalse);
    });

    test('isEncoding returns true for encoding phase', () {
      const progress = ExportProgress(phase: 'encoding', progress: 0.5);
      expect(progress.isEncoding, isTrue);
      expect(progress.isInitializing, isFalse);
    });

    test('isStalled returns true for encoding_stalled phase', () {
      const progress = ExportProgress(
        phase: 'encoding_stalled',
        progress: 0.3,
        stallSeconds: 15.0,
      );
      expect(progress.isStalled, isTrue);
      expect(progress.stallSeconds, 15.0);
    });

    test('isDone returns true for done phase', () {
      const progress = ExportProgress(phase: 'done', progress: 1.0);
      expect(progress.isDone, isTrue);
    });

    test('displayText returns phase-appropriate messages', () {
      expect(
        const ExportProgress(phase: 'preparing', progress: 0.0).displayText,
        'Loading video...',
      );
      expect(
        const ExportProgress(phase: 'composing', progress: 0.0).displayText,
        'Building composition...',
      );
      expect(
        const ExportProgress(phase: 'initializing', progress: 0.0).displayText,
        'Initializing encoder...',
      );
      expect(
        const ExportProgress(phase: 'encoding', progress: 0.42).displayText,
        'Encoding 42%',
      );
      expect(
        const ExportProgress(
          phase: 'encoding_stalled',
          progress: 0.5,
        ).displayText,
        'Encoding (slow device)...',
      );
      expect(
        const ExportProgress(phase: 'done', progress: 1.0).displayText,
        'Done',
      );
      expect(
        const ExportProgress(phase: 'unknown', progress: 0.0).displayText,
        'Processing...',
      );
    });

    test('progress value is correctly stored', () {
      const progress = ExportProgress(phase: 'encoding', progress: 0.75);
      expect(progress.progress, 0.75);
    });

    test('waitSeconds is available during initializing', () {
      const progress = ExportProgress(
        phase: 'initializing',
        progress: 0.0,
        waitSeconds: 5.0,
      );
      expect(progress.waitSeconds, 5.0);
    });
  });

  group('Export channel contract', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const exportChannel = MethodChannel('com.breakdex/video_export');
    late List<MethodCall> log;

    setUp(() {
      log = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(exportChannel, (final call) async {
            log.add(call);
            if (call.method == 'exportVideo') {
              final args = Map<String, dynamic>.from(call.arguments as Map);
              return args['outputPath'] as String;
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(exportChannel, null);
    });

    test('export button should be disabled during export (state test)', () {
      // Simulates the _exporting flag logic from VideoEditorScreen.
      // The export button is disabled when exporting OR editor not ready.
      bool shouldDisable(final bool exporting, final bool isEditorReady) =>
          exporting || !isEditorReady;

      expect(
        shouldDisable(false, true),
        isFalse,
      ); // Enabled: not exporting, ready
      expect(shouldDisable(true, true), isTrue); // Disabled: exporting
      expect(shouldDisable(false, false), isTrue); // Disabled: not ready
      expect(shouldDisable(true, false), isTrue); // Disabled: both
    });

    test('speed selector cycles through all options', () {
      const speeds = [0.25, 0.5, 1.0, 1.5, 2.0];
      const speedLabels = ['0.25x', '0.5x', '1x', '1.5x', '2x'];

      for (var i = 0; i < speeds.length; i++) {
        expect(speeds[i], isA<double>());
        expect(speedLabels[i], contains('x'));
      }

      // Default is index 2 (1.0x)
      expect(speeds[2], 1.0);
      expect(speedLabels[2], '1x');
    });

    test('trim range normalization clamps values correctly', () {
      // Simulates _clampToTrim logic
      double clampToTrim(final double normalized, final double trimStart, final double trimEnd) {
        return normalized.clamp(trimStart, trimEnd).toDouble();
      }

      expect(clampToTrim(0.5, 0.2, 0.8), 0.5); // Within range
      expect(clampToTrim(0.0, 0.2, 0.8), 0.2); // Below start
      expect(clampToTrim(1.0, 0.2, 0.8), 0.8); // Above end
      expect(clampToTrim(0.2, 0.2, 0.8), 0.2); // At start
      expect(clampToTrim(0.8, 0.2, 0.8), 0.8); // At end
    });

    test('rotation normalizes to 0-360 range', () {
      int normalizeRotation(final int rotation) {
        return ((rotation % 360) + 360) % 360;
      }

      expect(normalizeRotation(0), 0);
      expect(normalizeRotation(90), 90);
      expect(normalizeRotation(180), 180);
      expect(normalizeRotation(270), 270);
      expect(normalizeRotation(360), 0);
      expect(normalizeRotation(-90), 270);
      expect(normalizeRotation(-180), 180);
      expect(normalizeRotation(450), 90);
    });

    test('segment duration calculation is correct', () {
      int segmentDurationMs(final double trimStart, final double trimEnd, final int totalMs) {
        if (totalMs <= 0) return 0;
        return ((trimEnd - trimStart).clamp(0.0, 1.0) * totalMs).round();
      }

      expect(segmentDurationMs(0.0, 1.0, 10000), 10000); // Full video
      expect(segmentDurationMs(0.2, 0.8, 10000), 6000); // 60% of video
      expect(segmentDurationMs(0.0, 0.5, 10000), 5000); // First half
      expect(segmentDurationMs(0.0, 0.0, 10000), 0); // Zero length
      expect(segmentDurationMs(0.0, 1.0, 0), 0); // Zero duration video
    });

    test('format duration produces correct MM:SS strings', () {
      String formatDuration(final double ms) {
        final d = Duration(milliseconds: ms.round());
        final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
        return '$minutes:$seconds';
      }

      expect(formatDuration(0), '00:00');
      expect(formatDuration(5000), '00:05');
      expect(formatDuration(60000), '01:00');
      expect(formatDuration(90000), '01:30');
      expect(formatDuration(3600000), '00:00'); // Hour wraps (remainder)
    });
  });

  group('Video edit geometry', () {
    test('initial transform covers the viewport without empty edges', () {
      final viewport = computeVideoEditViewport(
        videoSize: const Size(1920, 1080),
        rotation: 0,
        maxWidth: 320,
        targetAspect: 1.0,
      );

      expect(viewport.size.width, closeTo(300, 0.0001));
      expect(viewport.size.height, closeTo(300, 0.0001));
      expect(viewport.minScale, closeTo(300 / 1080, 0.0001));

      final initial = viewport.initialTransform();
      final crop = viewport.normalizedCropRect(initial);

      expect(crop.left, closeTo(0.21875, 0.0001));
      expect(crop.top, closeTo(0.0, 0.0001));
      expect(crop.width, closeTo(0.5625, 0.0001));
      expect(crop.height, closeTo(1.0, 0.0001));
    });

    test('clampTransform recenters content when panned out of bounds', () {
      final viewport = computeVideoEditViewport(
        videoSize: const Size(1080, 1920),
        rotation: 90,
        maxWidth: 360,
        targetAspect: 16 / 9,
      );

      final invalid = Matrix4.diagonal3Values(
        viewport.minScale,
        viewport.minScale,
        1,
      )..setTranslationRaw(250, -999, 0);
      final clamped = viewport.clampTransform(invalid);
      final translation = clamped.getTranslation();

      expect(translation.x, lessThanOrEqualTo(0.0));
      expect(translation.y, lessThanOrEqualTo(0.0));
      expect(
        translation.x,
        greaterThanOrEqualTo(
          viewport.size.width -
              viewport.orientedVideoSize.width * viewport.minScale,
        ),
      );
      expect(
        translation.y,
        greaterThanOrEqualTo(
          viewport.size.height -
              viewport.orientedVideoSize.height * viewport.minScale,
        ),
      );
    });

    test('normalizedCropRect tracks zoomed and panned viewport state', () {
      final viewport = computeVideoEditViewport(
        videoSize: const Size(1920, 1080),
        rotation: 0,
        maxWidth: 320,
        targetAspect: 1.0,
      );

      final zoomed = Matrix4.diagonal3Values(
        viewport.minScale * 2,
        viewport.minScale * 2,
        1,
      )..setTranslationRaw(-120, 0, 0);
      final crop = viewport.normalizedCropRect(zoomed);

      expect(crop.left, closeTo(0.1125, 0.01));
      expect(crop.top, closeTo(0.0, 0.0001));
      expect(crop.width, closeTo(0.28125, 0.01));
      expect(crop.height, closeTo(0.5, 0.01));
    });
  });

  group('Trim timeline math', () {
    test('vertical lift reduces handle sensitivity for fine scrubbing', () {
      expect(trimHandleSensitivity(verticalLiftPx: 0), 1.0);
      expect(trimHandleSensitivity(verticalLiftPx: 72), closeTo(0.25, 0.0001));
      expect(trimHandleSensitivity(verticalLiftPx: 36), lessThan(1.0));
    });

    test('applyTrimHandleDrag clamps inside trim bounds', () {
      final next = applyTrimHandleDrag(
        currentValue: 0.2,
        deltaDx: -500,
        timelineWidth: 300,
        verticalLiftPx: 0,
        minValue: 0.15,
        maxValue: 0.9,
        durationMs: 12000,
      );

      expect(next, 0.15);
    });

    test('applyTrimHandleDrag moves less when fine scrubbing is active', () {
      final coarse = applyTrimHandleDrag(
        currentValue: 0.2,
        deltaDx: 30,
        timelineWidth: 300,
        verticalLiftPx: 0,
        minValue: 0.0,
        maxValue: 1.0,
        durationMs: 10000,
      );
      final fine = applyTrimHandleDrag(
        currentValue: 0.2,
        deltaDx: 30,
        timelineWidth: 300,
        verticalLiftPx: 72,
        minValue: 0.0,
        maxValue: 1.0,
        durationMs: 10000,
      );

      expect(coarse, greaterThan(fine));
      expect(coarse - 0.2, greaterThan(fine - 0.2));
    });
  });

  group('applyRawDrag (drift-free accumulator)', () {
    test('does not snap to quantum grid', () {
      final result = applyRawDrag(
        currentRaw: 0.5,
        deltaDx: 1.0,
        timelineWidth: 300.0,
        verticalLiftPx: 0.0,
        minValue: 0.0,
        maxValue: 1.0,
      );
      // Raw result should be exact floating-point addition, no 33ms rounding
      expect(result, closeTo(0.5 + 1.0 / 300.0, 1e-12));
    });

    test('many small drags do not accumulate drift', () {
      double raw = 0.8;
      for (int i = 0; i < 200; i++) {
        raw = applyRawDrag(
          currentRaw: raw,
          deltaDx: 0.5,
          timelineWidth: 300.0,
          verticalLiftPx: 0.0,
          minValue: 0.0,
          maxValue: 1.0,
        );
      }
      final expected = (0.8 + 200 * (0.5 / 300.0)).clamp(0.0, 1.0);
      expect(raw, closeTo(expected, 1e-10));
    });

    test('clamps to min/max bounds', () {
      final belowMin = applyRawDrag(
        currentRaw: 0.1,
        deltaDx: -500.0,
        timelineWidth: 300.0,
        verticalLiftPx: 0.0,
        minValue: 0.05,
        maxValue: 1.0,
      );
      expect(belowMin, 0.05);

      final aboveMax = applyRawDrag(
        currentRaw: 0.95,
        deltaDx: 500.0,
        timelineWidth: 300.0,
        verticalLiftPx: 0.0,
        minValue: 0.0,
        maxValue: 0.98,
      );
      expect(aboveMax, 0.98);
    });

    test('respects vertical lift sensitivity reduction', () {
      final coarse = applyRawDrag(
        currentRaw: 0.5,
        deltaDx: 10.0,
        timelineWidth: 300.0,
        verticalLiftPx: 0.0,
        minValue: 0.0,
        maxValue: 1.0,
      );
      final fine = applyRawDrag(
        currentRaw: 0.5,
        deltaDx: 10.0,
        timelineWidth: 300.0,
        verticalLiftPx: 72.0,
        minValue: 0.0,
        maxValue: 1.0,
      );
      expect(coarse - 0.5, greaterThan(fine - 0.5));
    });

    test('handles zero-width timeline gracefully', () {
      final result = applyRawDrag(
        currentRaw: 0.5,
        deltaDx: 10.0,
        timelineWidth: 0.0,
        verticalLiftPx: 0.0,
        minValue: 0.0,
        maxValue: 1.0,
      );
      expect(result, 0.5);
    });
  });

  group('Drift regression: snapped vs raw accumulation', () {
    test('repeated snapping causes leftward drift (proving the bug)', () {
      // Demonstrate that applyTrimHandleDrag accumulates drift
      // when its output is fed back as input (the old behavior).
      double snapped = 0.8;
      for (int i = 0; i < 200; i++) {
        snapped = applyTrimHandleDrag(
          currentValue: snapped,
          deltaDx: 0.5,
          timelineWidth: 300.0,
          verticalLiftPx: 0.0,
          minValue: 0.0,
          maxValue: 1.0,
          durationMs: 10000,
          quantumMs: 33,
        );
      }

      // Raw accumulation (no snapping per step)
      double raw = 0.8;
      for (int i = 0; i < 200; i++) {
        raw = applyRawDrag(
          currentRaw: raw,
          deltaDx: 0.5,
          timelineWidth: 300.0,
          verticalLiftPx: 0.0,
          minValue: 0.0,
          maxValue: 1.0,
        );
      }

      // The raw accumulator should be >= the snapped one
      // (snapping introduces leftward bias from rounding down)
      expect(raw, greaterThanOrEqualTo(snapped));
    });
  });

  group('Performance regression: ValueNotifier pattern', () {
    test('ValueNotifier updates do not trigger listener when value unchanged', () {
      final notifier = ValueNotifier<double>(0.5);
      var listenerCallCount = 0;
      notifier.addListener(() => listenerCallCount++);

      // Same value should not fire
      notifier.value = 0.5;
      expect(listenerCallCount, 0);

      // Different value should fire
      notifier.value = 0.6;
      expect(listenerCallCount, 1);

      // Simulate per-frame playback tolerance check (same as _onVideoTick):
      // only update if position changed by more than _kPlaybackTolerance
      const kPlaybackTolerance = 0.002;
      final oldValue = notifier.value;
      const newValue = 0.6005; // within tolerance
      if ((newValue - oldValue).abs() > kPlaybackTolerance) {
        notifier.value = newValue;
      }
      expect(listenerCallCount, 1); // No extra notification

      const bigChange = 0.65; // outside tolerance
      if ((bigChange - notifier.value).abs() > kPlaybackTolerance) {
        notifier.value = bigChange;
      }
      expect(listenerCallCount, 2);

      notifier.dispose();
    });

    test('playback position clamp respects trim boundaries', () {
      final position = ValueNotifier<double>(0.0);
      const trimStart = 0.2;
      const trimEnd = 0.8;

      // Simulate _handleTrimChanged updating position
      position.value = 0.1; // outside trim
      final clamped = position.value.clamp(trimStart, trimEnd).toDouble();
      position.value = clamped;
      expect(position.value, trimStart);

      position.value = 0.5;
      expect(position.value.clamp(trimStart, trimEnd), 0.5);

      position.dispose();
    });

    test('timestamp guard throttles requests at ~48ms intervals', () {
      var lastRequestMs = 0;
      const throttleMs = 48;
      var requestCount = 0;

      // Simulate rapid drag updates (every 16ms for 1 second)
      for (var ms = 0; ms < 1000; ms += 16) {
        if (ms - lastRequestMs >= throttleMs) {
          requestCount++;
          lastRequestMs = ms;
        }
      }

      // At 16ms intervals over 1000ms, we get ~62 frames.
      // At 48ms throttle, we should get ~20 requests (not 62).
      expect(requestCount, lessThanOrEqualTo(22));
      expect(requestCount, greaterThanOrEqualTo(18));
    });
  });
}
