import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Progress update from native AVFoundation export.
class ExportProgress {
  const ExportProgress({
    required this.phase,
    required this.progress,
    this.waitSeconds,
    this.stallSeconds,
  });

  /// Current phase: "preparing", "composing", "initializing", "encoding",
  /// "encoding_stalled", "done"
  final String phase;

  /// 0.0 to 1.0
  final double progress;

  /// Seconds spent waiting for encoder to initialize (only during "initializing")
  final double? waitSeconds;

  /// Seconds the encoder has been stalled (only during "encoding_stalled")
  final double? stallSeconds;

  bool get isInitializing => phase == 'initializing';
  bool get isStalled => phase == 'encoding_stalled';
  bool get isEncoding => phase == 'encoding';
  bool get isDone => phase == 'done';

  String get displayText {
    switch (phase) {
      case 'preparing':
        return 'Loading video...';
      case 'composing':
        return 'Building composition...';
      case 'initializing':
        return 'Initializing encoder...';
      case 'encoding':
        return 'Encoding ${(progress * 100).round()}%';
      case 'encoding_stalled':
        return 'Encoding (slow device)...';
      case 'finalizing':
        return 'Finalizing...';
      case 'done':
        return 'Done';
      default:
        return 'Processing...';
    }
  }
}

/// Native iOS video export using AVFoundation via MethodChannel.
/// Supports trim, speed, rotation, aspect ratio crop, and free-form crop
/// with hardware acceleration.
class NativeVideoExport {
  static const _method = MethodChannel('com.breakdex/video_export');
  static const _events = EventChannel('com.breakdex/video_export_progress');

  /// Stream of real-time export progress.
  static Stream<ExportProgress> get progressStream {
    // Web has no AVFoundation export, so no progress is ever emitted. Return an
    // empty stream — a session on web must not surface the platform channel's
    // MissingPluginException as an uncaught stream error (task 1.3).
    if (kIsWeb) return const Stream<ExportProgress>.empty();
    return _events.receiveBroadcastStream().map((final event) {
      final map = Map<String, dynamic>.from(event as Map);
      return ExportProgress(
        phase: map['phase'] as String? ?? 'preparing',
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        waitSeconds: (map['waitSeconds'] as num?)?.toDouble(),
        stallSeconds: (map['stallSeconds'] as num?)?.toDouble(),
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
  /// [cropRect] — optional free-form crop (normalized 0.0-1.0 Rect)
  static Future<String> export({
    required final String inputPath,
    required final String outputPath,
    required final int trimStartMs,
    required final int trimEndMs,
    final double speed = 1.0,
    final int rotation = 0,
    final String? aspectRatio,
    final Rect? cropRect,
  }) async {
    if (kIsWeb) {
      // Honest failure instead of an opaque MissingPluginException. The video
      // editor's export affordance is hidden on web (task 1.3), so this is
      // defense-in-depth for any path that reaches the seam anyway.
      throw UnsupportedError(
        'Video export is unavailable on web — AVFoundation is iOS-only.',
      );
    }
    final args = <String, dynamic>{
      'inputPath': inputPath,
      'outputPath': outputPath,
      'trimStartMs': trimStartMs,
      'trimEndMs': trimEndMs,
      'speed': speed,
      'rotation': rotation,
      'aspectRatio': aspectRatio,
    };

    if (cropRect != null) {
      args['cropLeft'] = cropRect.left;
      args['cropTop'] = cropRect.top;
      args['cropWidth'] = cropRect.width;
      args['cropHeight'] = cropRect.height;
    }

    final result = await _method.invokeMethod<String>('exportVideo', args);
    return result!;
  }

  /// Cancel an in-progress export.
  static Future<void> cancel() async {
    if (kIsWeb) return;
    await _method.invokeMethod('cancelExport');
  }
}
