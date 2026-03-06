import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  final String? originalFileName;

  const VideoPickResult({
    required this.localPath,
    this.thumbnailPath,
    this.originalFileName,
  });
}

class VideoService {
  final _picker = ImagePicker();
  static const _uuid = Uuid();
  static const _nativeImportChannel =
      MethodChannel('com.breakdex/native_video_import');
  static const _progressChannel =
      EventChannel('com.breakdex/native_video_import_progress');

  /// Stream of import progress (0.0–1.0) from the native iOS video picker.
  /// Emits fractional progress as iCloud/large videos materialize on disk.
  Stream<double> get importProgress =>
      _progressChannel.receiveBroadcastStream().map((e) => (e as num).toDouble());

  /// In-memory cache: videoPath → thumbnailPath. Avoids repeated disk checks
  /// when the grid view rebuilds (e.g. scroll, theme change, filter toggle).
  static final Map<String, String?> _thumbCache = {};

  /// Shared iOS pick-and-thumbnail helper for native channel methods.
  Future<VideoPickResult?> _nativePickWithThumb(
      String method, String statusLabel, {StatusCallback? onStatus}) async {
    onStatus?.call(statusLabel);
    final native = await _pickViaNativeChannel(method);
    if (native == null) return null;
    onStatus?.call('Generating thumbnail...');
    final thumb = await generateThumbnail(native.localPath);
    return VideoPickResult(
      localPath: native.localPath,
      thumbnailPath: thumb,
      originalFileName: native.originalFileName,
    );
  }

  /// Pick from photo library (includes iCloud Photos)
  Future<VideoPickResult?> pickFromPhotos({StatusCallback? onStatus}) async {
    if (Platform.isIOS) {
      return _nativePickWithThumb('pickFromPhotos',
          'Opening native iOS photo picker...', onStatus: onStatus);
    }

    onStatus?.call('Opening photo library...');
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;

    final originalName = file.name;
    onStatus?.call('Preparing selected video...');
    final localPath = await _saveToDocumentsWithRetry(
      File(file.path),
      onStatus: onStatus,
    );
    onStatus?.call('Generating thumbnail...');
    final thumb = await generateThumbnail(localPath);
    return VideoPickResult(
      localPath: localPath,
      thumbnailPath: thumb,
      originalFileName: originalName,
    );
  }

  /// Pick from Files app (iCloud Drive, Dropbox, local files)
  Future<VideoPickResult?> pickFromFiles({StatusCallback? onStatus}) async {
    if (Platform.isIOS) {
      return _nativePickWithThumb('pickFromFiles',
          'Opening native iOS files picker...', onStatus: onStatus);
    }

    onStatus?.call('Opening Files...');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final filePath = result.files.single.path;
    if (filePath == null) return null;

    final originalName = result.files.single.name;
    onStatus?.call('Preparing file from iCloud/Files...');
    final localPath = await _saveToDocumentsWithRetry(
      File(filePath),
      onStatus: onStatus,
    );
    onStatus?.call('Generating thumbnail...');
    final thumb = await generateThumbnail(localPath);
    return VideoPickResult(
      localPath: localPath,
      thumbnailPath: thumb,
      originalFileName: originalName,
    );
  }

  /// Record from camera
  Future<VideoPickResult?> recordVideo({StatusCallback? onStatus}) async {
    onStatus?.call('Opening camera...');
    final file = await _picker.pickVideo(source: ImageSource.camera);
    if (file == null) return null;

    onStatus?.call('Saving video...');
    final localPath = await _saveToDocumentsWithRetry(
      File(file.path),
      onStatus: onStatus,
    );
    onStatus?.call('Generating thumbnail...');
    final thumb = await generateThumbnail(localPath);
    return VideoPickResult(
      localPath: localPath,
      thumbnailPath: thumb,
      originalFileName: 'Camera Recording',
    );
  }

  Future<VideoPickResult?> _pickViaNativeChannel(String method) async {
    try {
      final payload = await _nativeImportChannel.invokeMapMethod<String, dynamic>(method);
      if (payload == null) return null;
      final localPath = payload['localPath'] as String?;
      if (localPath == null || localPath.isEmpty) return null;
      return VideoPickResult(
        localPath: localPath,
        originalFileName: payload['originalFileName'] as String?,
      );
    } on PlatformException catch (e) {
      // User cancelled the picker — not an error
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('cancelled') || msg.contains('canceled')) return null;
      rethrow;
    }
  }

  /// Check if a video file is accessible.
  ///
  /// Applies a 5-second timeout to guard against iCloud files that stall
  /// during download — `File.exists()` can hang indefinitely when the OS
  /// is fetching from a cloud provider.
  Future<VideoFileStatus> checkVideoFile(String path) async {
    try {
      final file = File(path);
      final exists = await file.exists().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      if (!exists) return VideoFileStatus.missing;
      final stat = await file.stat().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('stat timed out'),
      );
      if (stat.size <= 0) return VideoFileStatus.missing;
      return VideoFileStatus.ready;
    } on TimeoutException {
      return VideoFileStatus.error;
    } catch (_) {
      return VideoFileStatus.error;
    }
  }

  /// Retry-aware wrapper around [checkVideoFile].
  ///
  /// Retries up to [maxRetries] times with exponential backoff (1s, 2s).
  /// Useful for the video player where transient iCloud errors resolve
  /// after the OS finishes a background download.
  Future<VideoFileStatus> checkVideoFileWithRetry(
    String path, {
    int maxRetries = 2,
  }) async {
    var status = await checkVideoFile(path);
    for (int i = 0; i < maxRetries && status == VideoFileStatus.error; i++) {
      await Future.delayed(Duration(seconds: 1 << i));
      status = await checkVideoFile(path);
    }
    return status;
  }

  /// Generate thumbnail, cached in .thumbs/ folder and in-memory.
  ///
  /// Uses a two-tier cache: memory (instant) → disk (.thumbs/) → generate.
  /// File I/O for writing bytes is offloaded via `compute()` to keep the
  /// UI thread free during grid scrolls with many uncached thumbnails.
  Future<String?> generateThumbnail(String videoPath) async {
    // Tier 1: in-memory cache (survives widget rebuilds within the session)
    if (_thumbCache.containsKey(videoPath)) return _thumbCache[videoPath];

    try {
      final docs = await getApplicationDocumentsDirectory();
      final thumbsDir = Directory(p.join(docs.path, 'Moves', '.thumbs'));
      if (!await thumbsDir.exists()) {
        await thumbsDir.create(recursive: true);
      }

      final videoName = p.basenameWithoutExtension(videoPath);
      final thumbPath = p.join(thumbsDir.path, '$videoName.jpg');

      // Tier 2: disk cache
      if (await File(thumbPath).exists()) {
        _thumbCache[videoPath] = thumbPath;
        return thumbPath;
      }

      // Generate from video (platform channel — must run on main isolate)
      final Uint8List? bytes = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 75,
      );
      if (bytes == null) {
        _thumbCache[videoPath] = null;
        return null;
      }

      // Offload file write to a background isolate
      await compute(_writeBytes, _WriteBytesArgs(thumbPath, bytes));
      _thumbCache[videoPath] = thumbPath;
      return thumbPath;
    } catch (_) {
      _thumbCache[videoPath] = null;
      return null;
    }
  }

  /// Top-level function for `compute()` — writes bytes to disk in an isolate.
  static void _writeBytes(_WriteBytesArgs args) {
    File(args.path).writeAsBytesSync(args.bytes);
  }

  Future<String> _saveToDocumentsWithRetry(
    File source, {
    StatusCallback? onStatus,
    int maxRetries = 2,
  }) async {
    Object? lastError;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await _saveToDocuments(source);
      } catch (e) {
        lastError = e;
        if (attempt == maxRetries) break;
        onStatus?.call(
          'Waiting for iCloud download... (retry ${attempt + 1}/${maxRetries + 1})',
        );
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }
    throw lastError ?? Exception('Video copy failed');
  }

  Future<String> _saveToDocuments(File source) async {
    final docs = await getApplicationDocumentsDirectory();
    final movesDir = Directory(p.join(docs.path, 'Moves'));
    if (!await movesDir.exists()) {
      await movesDir.create(recursive: true);
    }
    final ext = p.extension(source.path).isNotEmpty
        ? p.extension(source.path)
        : '.mp4';
    final dest = p.join(movesDir.path, '${_uuid.v4()}$ext');
    await _copyFileWithTimeout(
      source: source,
      destination: File(dest),
      timeout: const Duration(seconds: 90),
    );
    return dest;
  }

  Future<void> _copyFileWithTimeout({
    required File source,
    required File destination,
    required Duration timeout,
  }) async {
    final exists = await source.exists().timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );
    if (!exists) {
      throw FileSystemException('Source file does not exist', source.path);
    }

    final sink = destination.openWrite();
    StreamSubscription<List<int>>? subscription;
    Timer? inactivityTimer;
    final completer = Completer<void>();

    void fail(Object error) {
      if (completer.isCompleted) return;
      completer.completeError(error);
    }

    void resetTimer() {
      inactivityTimer?.cancel();
      inactivityTimer = Timer(
        timeout,
        () => fail(TimeoutException('File copy stalled', timeout)),
      );
    }

    try {
      resetTimer();
      subscription = source.openRead().listen(
        (chunk) {
          sink.add(chunk);
          resetTimer();
        },
        onError: fail,
        onDone: () async {
          await sink.flush();
          await sink.close();
          inactivityTimer?.cancel();
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );

      await completer.future;
    } catch (e) {
      await subscription?.cancel();
      await sink.close();
      if (await destination.exists()) {
        await destination.delete();
      }
      rethrow;
    } finally {
      inactivityTimer?.cancel();
    }
  }

  /// Invalidate the in-memory thumbnail cache (e.g. after video deletion).
  static void invalidateThumbCache(String videoPath) {
    _thumbCache.remove(videoPath);
  }

  /// Replace a move's video: delete old file + thumbnail, invalidate caches.
  /// Call BEFORE updating the DB path so we still know the old path.
  Future<void> replaceVideo(String? oldPath) async {
    if (oldPath == null) return;
    await deleteVideo(oldPath);
  }

  Future<void> deleteVideo(String path) async {
    invalidateThumbCache(path);
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

/// Serializable arguments for `compute()` — must be a top-level class
/// because `compute()` requires the function and args to be sendable
/// across isolate boundaries.
class _WriteBytesArgs {
  final String path;
  final Uint8List bytes;
  const _WriteBytesArgs(this.path, this.bytes);
}
