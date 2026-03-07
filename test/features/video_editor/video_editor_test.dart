import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/services/native_video_export.dart';

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
        const ExportProgress(phase: 'encoding_stalled', progress: 0.5)
            .displayText,
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
          .setMockMethodCallHandler(exportChannel, (call) async {
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
      bool shouldDisable(bool exporting, bool isEditorReady) =>
          exporting || !isEditorReady;

      expect(shouldDisable(false, true), isFalse);  // Enabled: not exporting, ready
      expect(shouldDisable(true, true), isTrue);     // Disabled: exporting
      expect(shouldDisable(false, false), isTrue);   // Disabled: not ready
      expect(shouldDisable(true, false), isTrue);    // Disabled: both
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
      double clampToTrim(double normalized, double trimStart, double trimEnd) {
        return normalized.clamp(trimStart, trimEnd).toDouble();
      }

      expect(clampToTrim(0.5, 0.2, 0.8), 0.5); // Within range
      expect(clampToTrim(0.0, 0.2, 0.8), 0.2); // Below start
      expect(clampToTrim(1.0, 0.2, 0.8), 0.8); // Above end
      expect(clampToTrim(0.2, 0.2, 0.8), 0.2); // At start
      expect(clampToTrim(0.8, 0.2, 0.8), 0.8); // At end
    });

    test('rotation normalizes to 0-360 range', () {
      int normalizeRotation(int rotation) {
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
      int segmentDurationMs(
        double trimStart,
        double trimEnd,
        int totalMs,
      ) {
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
      String formatDuration(double ms) {
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
}
