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
    final raw = await method.invokeMethod<List<dynamic>>('generateThumbnails', {
      'videoPath': videoPath,
      'timesMs': timesMs,
      'maxWidth': maxWidth,
      'quality': quality,
      'toleranceMs': toleranceMs,
      'exact': exact,
    });

    return (raw ?? const <dynamic>[])
        .map((value) => value is Uint8List ? value : null)
        .toList(growable: false);
  }
}
