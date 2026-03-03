import 'dart:async';
import 'package:flutter/services.dart';

/// Progress update from native AVFoundation export.
class ExportProgress {
  const ExportProgress({required this.phase, required this.progress});

  /// Current phase: "preparing", "composing", "exporting", "done"
  final String phase;

  /// 0.0 to 1.0
  final double progress;

  String get displayText {
    switch (phase) {
      case 'preparing':
        return 'Preparing...';
      case 'composing':
        return 'Composing...';
      case 'exporting':
        return 'Exporting ${(progress * 100).round()}%';
      case 'done':
        return 'Done';
      default:
        return 'Processing...';
    }
  }
}

/// Native iOS video export using AVFoundation via MethodChannel.
/// Supports trim, speed, rotation, and aspect ratio crop with hardware acceleration.
class NativeVideoExport {
  static const _method = MethodChannel('com.breakdex/video_export');
  static const _events = EventChannel('com.breakdex/video_export_progress');

  /// Stream of real-time export progress.
  static Stream<ExportProgress> get progressStream {
    return _events.receiveBroadcastStream().map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      return ExportProgress(
        phase: map['phase'] as String? ?? 'preparing',
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      );
    });
  }

  /// Export a video with the given parameters. Returns the output file path.
  ///
  /// [inputPath] — source video file
  /// [outputPath] — destination file path
  /// [trimStartMs] / [trimEndMs] — trim range in milliseconds
  /// [speed] — playback speed (1.0 = normal)
  /// [rotation] — degrees (0, 90, 180, 270)
  /// [aspectRatio] — null for original, or "9:16", "16:9", "1:1", "4:5"
  static Future<String> export({
    required String inputPath,
    required String outputPath,
    required int trimStartMs,
    required int trimEndMs,
    double speed = 1.0,
    int rotation = 0,
    String? aspectRatio,
  }) async {
    final result = await _method.invokeMethod<String>('exportVideo', {
      'inputPath': inputPath,
      'outputPath': outputPath,
      'trimStartMs': trimStartMs,
      'trimEndMs': trimEndMs,
      'speed': speed,
      'rotation': rotation,
      'aspectRatio': aspectRatio,
    });
    return result!;
  }

  /// Cancel an in-progress export.
  static Future<void> cancel() async {
    await _method.invokeMethod('cancelExport');
  }
}
