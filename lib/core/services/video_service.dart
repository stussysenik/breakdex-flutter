import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

enum VideoFileStatus { ready, missing, error }

typedef StatusCallback = void Function(String status);

class VideoPickResult {
  final String localPath;
  final String? thumbnailPath;

  const VideoPickResult({required this.localPath, this.thumbnailPath});
}

class VideoService {
  final _picker = ImagePicker();
  static const _uuid = Uuid();

  /// Pick from photo library (includes iCloud Photos)
  Future<VideoPickResult?> pickFromPhotos({StatusCallback? onStatus}) async {
    onStatus?.call('Opening photo library...');
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;

    onStatus?.call('Copying video...');
    final localPath = await _saveToDocuments(File(file.path));
    onStatus?.call('Generating thumbnail...');
    final thumb = await generateThumbnail(localPath);
    return VideoPickResult(localPath: localPath, thumbnailPath: thumb);
  }

  /// Pick from Files app (iCloud Drive, Dropbox, local files)
  Future<VideoPickResult?> pickFromFiles({StatusCallback? onStatus}) async {
    onStatus?.call('Opening Files...');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final filePath = result.files.single.path;
    if (filePath == null) return null;

    onStatus?.call('Downloading from iCloud...');
    final localPath = await _saveToDocuments(File(filePath));
    onStatus?.call('Generating thumbnail...');
    final thumb = await generateThumbnail(localPath);
    return VideoPickResult(localPath: localPath, thumbnailPath: thumb);
  }

  /// Record from camera
  Future<VideoPickResult?> recordVideo({StatusCallback? onStatus}) async {
    onStatus?.call('Opening camera...');
    final file = await _picker.pickVideo(source: ImageSource.camera);
    if (file == null) return null;

    onStatus?.call('Saving video...');
    final localPath = await _saveToDocuments(File(file.path));
    onStatus?.call('Generating thumbnail...');
    final thumb = await generateThumbnail(localPath);
    return VideoPickResult(localPath: localPath, thumbnailPath: thumb);
  }

  /// Check if a video file is accessible
  Future<VideoFileStatus> checkVideoFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return VideoFileStatus.missing;
      final stat = await file.stat();
      if (stat.size <= 0) return VideoFileStatus.missing;
      return VideoFileStatus.ready;
    } catch (_) {
      return VideoFileStatus.error;
    }
  }

  /// Generate thumbnail, cached in .thumbs/ folder
  Future<String?> generateThumbnail(String videoPath) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final thumbsDir = Directory(p.join(docs.path, 'Moves', '.thumbs'));
      if (!await thumbsDir.exists()) {
        await thumbsDir.create(recursive: true);
      }

      final videoName = p.basenameWithoutExtension(videoPath);
      final thumbPath = p.join(thumbsDir.path, '$videoName.jpg');

      // Return cached if exists
      if (await File(thumbPath).exists()) return thumbPath;

      final Uint8List? bytes = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 75,
      );
      if (bytes == null) return null;

      await File(thumbPath).writeAsBytes(bytes);
      return thumbPath;
    } catch (_) {
      return null;
    }
  }

  Future<String> _saveToDocuments(File source) async {
    final docs = await getApplicationDocumentsDirectory();
    final movesDir = Directory(p.join(docs.path, 'Moves'));
    if (!await movesDir.exists()) {
      await movesDir.create(recursive: true);
    }
    final ext = p.extension(source.path);
    final dest = p.join(movesDir.path, '${_uuid.v4()}$ext');
    await source.copy(dest);
    return dest;
  }

  Future<void> deleteVideo(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    // Also delete cached thumbnail
    final videoName = p.basenameWithoutExtension(path);
    final docs = await getApplicationDocumentsDirectory();
    final thumbFile = File(p.join(docs.path, 'Moves', '.thumbs', '$videoName.jpg'));
    if (await thumbFile.exists()) {
      await thumbFile.delete();
    }
  }
}
