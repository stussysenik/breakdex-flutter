import 'native_bridge.dart';

/// Dart bridge to the native `VideoAlbumPlugin` — saves exported video
/// clips into a dated Photos album (e.g. "Breakdex 03-07-2026").
///
/// This uses write-only photo library access (`NSPhotoLibraryAddUsageDescription`),
/// so the user is only prompted once and we never read their existing library.
class NativeVideoAlbum extends NativeBridge {
  NativeVideoAlbum() : super('video_album', hasEventChannel: false);

  static String defaultAlbumName([DateTime? date]) {
    final now = date ?? DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return 'Breakdex $month-$day-${now.year}';
  }

  /// Save a video file to a named Photos album.
  /// Creates the album if it doesn't exist yet.
  Future<void> saveToAlbum({
    required String videoPath,
    required String albumName,
    String? assetTitle,
    String? category,
  }) async {
    final normalizedPath = videoPath.trim();
    final normalizedAlbum = albumName.trim();
    if (normalizedPath.isEmpty || normalizedAlbum.isEmpty) {
      return;
    }

    final args = <String, dynamic>{
      'videoPath': normalizedPath,
      'albumName': normalizedAlbum,
    };
    if (assetTitle != null && assetTitle.trim().isNotEmpty) {
      args['assetTitle'] = assetTitle.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      args['category'] = category.trim();
    }

    await method.invokeMethod<void>('saveToAlbum', args);
  }
}
