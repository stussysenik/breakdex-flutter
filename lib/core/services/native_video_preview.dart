import 'dart:typed_data';

import 'native_bridge.dart';

class NativeVideoPreview extends NativeBridge {
  NativeVideoPreview() : super('video_preview', hasEventChannel: false);

  Future<List<Uint8List?>> generateThumbnails({
    required String videoPath,
    required List<int> timesMs,
    required int maxWidth,
    required int quality,
    int toleranceMs = 200,
    bool exact = false,
  }) async {
    final normalizedPath = videoPath.trim();
    if (normalizedPath.isEmpty) {
      return List<Uint8List?>.filled(timesMs.length, null, growable: false);
    }
    if (timesMs.isEmpty) {
      return const <Uint8List?>[];
    }

    final raw = await method.invokeMethod<List<dynamic>>('generateThumbnails', {
      'videoPath': normalizedPath,
      'timesMs': timesMs,
      'maxWidth': maxWidth < 2 ? 2 : maxWidth,
      'quality': quality.clamp(1, 100),
      'toleranceMs': toleranceMs < 0 ? 0 : toleranceMs,
      'exact': exact,
    });

    return (raw ?? const <dynamic>[])
        .map((value) => value is Uint8List ? value : null)
        .toList(growable: false);
  }
}
