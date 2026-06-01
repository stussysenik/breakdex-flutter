import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../utils/diagnostics.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/failures/failure.dart';
import '../utils/filesystem_utils.dart';
import '../utils/loading_state_machine.dart';
import 'native_video_preview.dart';
import 'video_path_resolver.dart';
import 'video_storage_gate.dart';

enum VideoFileStatus { ready, missing, error }

typedef StatusCallback = void Function(String status);

class VideoPickResult {
  final String localPath;
  final String? thumbnailPath;
  final String? originalFileName;
  final DateTime? creationDate;
  final int? fileSize;
  final double? duration;

  const VideoPickResult({
    required this.localPath,
    this.thumbnailPath,
    this.originalFileName,
    this.creationDate,
    this.fileSize,
    this.duration,
  });

  @override
  String toString() {
    return 'VideoPickResult(path: $localPath, name: $originalFileName, date: $creationDate, size: $fileSize, dur: $duration)';
  }
}

class MetadataAsset {
  final String localIdentifier;
  final DateTime? creationDate;
  final double duration;
  final String originalFileName;
  final int width;
  final int height;
  final bool isLocal;

  MetadataAsset({
    required this.localIdentifier,
    this.creationDate,
    required this.duration,
    required this.originalFileName,
    required this.width,
    required this.height,
    this.isLocal = false,
  });

  factory MetadataAsset.fromMap(Map<String, dynamic> map) {
    return MetadataAsset(
      localIdentifier: map['localIdentifier'] as String,
      creationDate: map['creationDate'] != null ? DateTime.tryParse(map['creationDate'] as String) : null,
      duration: (map['duration'] as num).toDouble(),
      originalFileName: map['originalFileName'] as String,
      width: map['width'] as int,
      height: map['height'] as int,
      isLocal: false,
    );
  }
}

class VideoService {
  final _picker = ImagePicker();
  static const _uuid = Uuid();
  static const _nativeImportChannel = MethodChannel(
    'com.breakdex/native_video_import',
  );
  static const _progressChannel = EventChannel(
    'com.breakdex/native_video_import_progress',
  );
  static final _nativePreview = NativeVideoPreview();

  /// Stream of import progress (0.0–1.0) from the native iOS video picker.
  /// Emits fractional progress as iCloud/large videos materialize on disk.
  Stream<double> get importProgress => _progressChannel
      .receiveBroadcastStream()
      .map((e) => (e as num).toDouble());

  /// In-memory cache: videoPath → thumbnailPath. Avoids repeated disk checks
  /// when the grid view rebuilds (e.g. scroll, theme change, filter toggle).
  static final Map<String, String?> _thumbCache = {};
  static final LinkedHashMap<String, Uint8List?> _frameThumbCache =
      LinkedHashMap<String, Uint8List?>();
  static final Map<String, Future<Uint8List?>> _frameThumbInFlight = {};
  static const _maxFrameThumbEntries = 256;

  /// Shared iOS pick-and-thumbnail helper for native channel methods.
  Future<VideoPickResult?> _nativePickWithThumb(
    String method,
    String statusLabel, {
    StatusCallback? onStatus,
  }) async {
    final logger = StageLogger.begin('NativePick', subsystem: 'VideoService', context: {'method': method});
    try {
      onStatus?.call(statusLabel);
      logger.stage('pick_channel');
      final native = await _pickViaNativeChannel(method);
      if (native == null) {
        logger.complete('cancelled');
        return null;
      }
      onStatus?.call('Generating thumbnail...');
      logger.stage('gen_thumb');
      final thumb = await generateThumbnail(native.localPath);
      logger.complete('success');
      return VideoPickResult(
        localPath: native.localPath,
        thumbnailPath: thumb,
        originalFileName: native.originalFileName,
        creationDate: native.creationDate,
        fileSize: native.fileSize,
        duration: native.duration,
      );
    } catch (e, st) {
      logger.fail(e, st);
      rethrow;
    }
  }

  /// Record a new video using the camera
  TaskEither<AppFailure, VideoPickResult?> recordVideo({StatusCallback? onStatus}) {
    return TaskEither.tryCatch(
      () async {
        final logger = StageLogger.begin('RecordVideo', subsystem: 'VideoService');
        onStatus?.call('Opening camera...');
        logger.stage('pick_camera');
        final file = await _picker.pickVideo(source: ImageSource.camera);
        if (file == null) {
          logger.complete('cancelled');
          return null;
        }

        onStatus?.call('Saving recording...');
        logger.stage('save_docs');
        final localPath = await _saveToDocumentsWithRetry(
          File(file.path),
          onStatus: onStatus,
        );
        onStatus?.call('Generating thumbnail...');
        logger.stage('gen_thumb');
        final thumb = await generateThumbnail(localPath);
        final stat = await File(VideoPathResolver.toAbsolute(localPath)).stat();

        logger.complete('success');
        return VideoPickResult(
          localPath: localPath,
          thumbnailPath: thumb,
          originalFileName: p.basename(file.path),
          creationDate: DateTime.now(),
          fileSize: stat.size,
        );
      },
      (error, stackTrace) => AppFailure.fileSystem('Failed to record video: $error'),
    );
  }

  /// Pick from photo library (includes iCloud Photos)
  TaskEither<AppFailure, VideoPickResult?> pickFromPhotos({StatusCallback? onStatus}) {
    return TaskEither.tryCatch(
      () async {
        if (Platform.isIOS) {
          return _nativePickWithThumb(
            'pickFromPhotos',
            'Opening native iOS photo picker...',
            onStatus: onStatus,
          );
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
        final stat = await File(VideoPathResolver.toAbsolute(localPath)).stat();

        return VideoPickResult(
          localPath: localPath,
          thumbnailPath: thumb,
          originalFileName: originalName,
          creationDate: stat.changed, // Fallback for non-iOS
          fileSize: stat.size,
        );
      },
      (error, stackTrace) => AppFailure.fileSystem('Failed to pick from photos: $error'),
    );
  }

  /// Pick from Files app (iCloud Drive, Dropbox, local files)
  TaskEither<AppFailure, VideoPickResult?> pickFromFiles({StatusCallback? onStatus}) {
    return TaskEither.tryCatch(
      () async {
        if (Platform.isIOS) {
          return _nativePickWithThumb(
            'pickFromFiles',
            'Opening native iOS files picker...',
            onStatus: onStatus,
          );
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
        final stat = await File(VideoPathResolver.toAbsolute(localPath)).stat();

        return VideoPickResult(
          localPath: localPath,
          thumbnailPath: thumb,
          originalFileName: originalName,
          creationDate: stat.changed,
          fileSize: stat.size,
        );
      },
      (error, stackTrace) => AppFailure.fileSystem('Failed to pick from files: $error'),
    );
  }

  Future<VideoPickResult?> _pickViaNativeChannel(String method) async {
    try {
      final payload = await _nativeImportChannel
          .invokeMapMethod<String, dynamic>(method);
      if (payload == null) return null;
      final localPath = payload['localPath'] as String?;
      if (localPath == null || localPath.isEmpty) return null;

      DateTime? creationDate;
      if (payload['creationDate'] != null) {
        creationDate = DateTime.tryParse(payload['creationDate'] as String);
      }

      final result = VideoPickResult(
        localPath: localPath,
        originalFileName: payload['originalFileName'] as String?,
        creationDate: creationDate,
        fileSize: payload['fileSize'] as int?,
        duration: (payload['duration'] as num?)?.toDouble(),
      );

      debugPrint('[VideoService] Native pick result: $result');
      return result;
    } on PlatformException catch (e) {
      // User cancelled the picker — not an error
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('cancelled') || msg.contains('canceled')) return null;
      rethrow;
    }
  }

  Future<List<MetadataAsset>> fetchPhotoLibraryVideos() async {
    if (!Platform.isIOS) return [];
    try {
      final List<dynamic>? assets = await _nativeImportChannel.invokeMethod('fetchPhotoLibraryVideos');
      if (assets == null) return [];
      return assets.map((a) => MetadataAsset.fromMap(Map<String, dynamic>.from(a as Map))).toList();
    } catch (e) {
      debugPrint('[VideoService] Failed to fetch assets: $e');
      return [];
    }
  }

  Future<Uint8List?> getAssetThumbnail(String identifier, {int width = 200, int height = 200}) async {
    if (!Platform.isIOS) return null;
    try {
      final Uint8List? bytes = await _nativeImportChannel.invokeMethod('getAssetThumbnail', {
        'identifier': identifier,
        'width': width,
        'height': height,
      });
      return bytes;
    } catch (e) {
      debugPrint('[VideoService] Failed to get thumb: $e');
      return null;
    }
  }

  Future<VideoPickResult?> importSpecificAsset(String identifier) async {
    if (!Platform.isIOS) return null;
    final logger = StageLogger.begin('ImportSpecific', subsystem: 'VideoService', context: {'id': identifier});
    try {
      final Map<String, dynamic>? payload = await _nativeImportChannel.invokeMapMethod<String, dynamic>(
        'importSpecificAsset',
        {'identifier': identifier},
      );
      if (payload == null) {
        logger.complete('cancelled');
        return null;
      }
      
      DateTime? creationDate;
      if (payload['creationDate'] != null) {
        creationDate = DateTime.tryParse(payload['creationDate'] as String);
      }

      final result = VideoPickResult(
        localPath: payload['localPath'] as String,
        originalFileName: payload['originalFileName'] as String?,
        creationDate: creationDate,
        fileSize: payload['fileSize'] as int?,
        duration: (payload['duration'] as num?)?.toDouble(),
      );
      
      logger.complete('success');
      debugPrint('[VideoService] Specific asset import result: $result');
      return result;
    } catch (e, st) {
      logger.fail(e, st);
      return null;
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

  /// Stateful wrapper around [checkVideoFileWithRetry] that drives a
  /// [LoadingStateController] through its lifecycle: start → resolve →
  /// complete/fail. Callers can listen to [LoadingStateController.stream]
  /// for reactive UI updates without managing state transitions manually.
  LoadingStateController<void> checkVideoFileWithState(
    String path, {
    int maxRetries = 2,
  }) {
    final controller = LoadingStateController<void>(
      maxAttempts: maxRetries,
    );
    unawaited(_runFileCheck(path, controller, maxRetries));
    return controller;
  }

  Future<void> _runFileCheck(
    String path,
    LoadingStateController<void> controller,
    int maxRetries,
  ) async {
    controller.send(LoadingEvent.start);
    var status = await checkVideoFile(path);
    for (int i = 0;
        i < maxRetries && status == VideoFileStatus.error;
        i++) {
      await Future.delayed(Duration(seconds: 1 << i));
      status = await checkVideoFile(path);
    }
    switch (status) {
      case VideoFileStatus.ready:
        controller.send(LoadingEvent.complete(null));
      case VideoFileStatus.missing:
        controller.send(
          LoadingEvent.fail('Video not found', retryable: false),
        );
      case VideoFileStatus.error:
        controller.send(
          LoadingEvent.fail('Unable to access video file', retryable: true),
        );
    }
  }

  /// Validate that a saved video can actually be opened by the player.
  ///
  /// This is used after export so a corrupt or half-written file does not
  /// replace the last known-good saved video.
  Future<void> validatePlayableVideo(
    String path, {
    Duration initializeTimeout = const Duration(seconds: 12),
  }) async {
    final status = await checkVideoFileWithRetry(path, maxRetries: 3);
    if (status != VideoFileStatus.ready) {
      throw StateError('The exported video file is not ready yet.');
    }

    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize().timeout(initializeTimeout);
      final value = controller.value;
      if (!value.isInitialized) {
        throw StateError('The exported video could not be initialized.');
      }
      if (value.duration <= Duration.zero) {
        throw StateError('The exported video has no playable duration.');
      }
      if (value.size.width <= 0 || value.size.height <= 0) {
        throw StateError('The exported video has invalid dimensions.');
      }
    } finally {
      await controller.dispose();
    }
  }

  /// Resolution tiers for thumbnail generation.
  static const thumbnailWidthGrid = 200;
  static const thumbnailWidthList = 400;
  static const thumbnailWidthFull = 720;

  /// Generate thumbnail, cached in .thumbs/ folder and in-memory.
  ///
  /// Uses a two-tier cache: memory (instant) → disk (.thumbs/) → generate.
  /// File I/O for writing bytes is offloaded via `compute()` to keep the
  /// UI thread free during grid scrolls with many uncached thumbnails.
  ///
  /// [maxWidth] controls the resolution tier. Grid cells should pass
  /// [thumbnailWidthGrid] (200px) for fast decodes; detail screens use
  /// the default [thumbnailWidthFull] (720px) for sharp previews.
  Future<String?> generateThumbnail(
    String videoPath, {
    int maxWidth = thumbnailWidthFull,
  }) async {
    // Cache key uses relative path so sessions before/after migration share
    // the same cache entries. Resolution tier suffix prevents grid/detail collision.
    final cacheKey = '${VideoPathResolver.toRelative(videoPath)}@$maxWidth';

    // Tier 1: in-memory cache (survives widget rebuilds within the session)
    if (_thumbCache.containsKey(cacheKey)) return _thumbCache[cacheKey];

    try {
      final docs = await getApplicationDocumentsDirectory();
      final thumbsDir = Directory(p.join(docs.path, 'Moves', '.thumbs'));
      if (!await thumbsDir.exists()) {
        await thumbsDir.create(recursive: true);
      }

      final videoName = p.basenameWithoutExtension(videoPath);
      final thumbPath = p.join(
        thumbsDir.path,
        maxWidth == thumbnailWidthFull
            ? '$videoName.jpg'
            : '${videoName}_${maxWidth}w.jpg',
      );

      // Tier 2: disk cache
      if (await File(thumbPath).exists()) {
        _thumbCache[cacheKey] = thumbPath;
        return thumbPath;
      }

      // Generate from video (platform channel — must run on main isolate)
      final Uint8List? bytes = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        quality: maxWidth >= thumbnailWidthFull ? 95 : 85,
      );
      if (bytes == null) {
        _thumbCache[cacheKey] = null;
        return null;
      }

      // Offload file write to a background isolate
      await compute(_writeBytes, _WriteBytesArgs(thumbPath, bytes));
      _thumbCache[cacheKey] = thumbPath;
      return thumbPath;
    } catch (_) {
      _thumbCache[cacheKey] = null;
      return null;
    }
  }

  /// Load thumbnail bytes for a specific video frame.
  ///
  /// Cache keys are bucketed by [bucketMs] so timeline scrubbing produces
  /// deterministic O(1) hits after the first decode instead of hammering the
  /// platform with near-identical requests.
  Future<Uint8List?> loadFrameThumbnailData({
    required String videoPath,
    required int timeMs,
    int maxWidth = 100,
    int quality = 50,
    int bucketMs = 50,
    bool exact = false,
  }) async {
    final normalizedTimeMs = exact || bucketMs <= 1
        ? timeMs
        : ((timeMs / bucketMs).round() * bucketMs);
    final cacheKey = _frameThumbnailKey(
      videoPath: videoPath,
      timeMs: normalizedTimeMs,
      maxWidth: maxWidth,
      quality: quality,
      exact: exact,
    );

    final cached = _readFrameThumbnail(cacheKey);
    if (cached != null || _frameThumbCache.containsKey(cacheKey)) {
      return cached;
    }

    final pending = _frameThumbInFlight[cacheKey];
    if (pending != null) return pending;

    final future = _loadFrameThumbnailUncached(
      videoPath: videoPath,
      timeMs: normalizedTimeMs,
      maxWidth: maxWidth,
      quality: quality,
      exact: exact,
      bucketMs: bucketMs,
    );
    _frameThumbInFlight[cacheKey] = future;

    try {
      final bytes = await future;
      _rememberFrameThumbnail(cacheKey, bytes);
      return bytes;
    } finally {
      unawaited(_frameThumbInFlight.remove(cacheKey));
    }
  }

  Future<List<Uint8List?>> loadTimelineThumbnails({
    required String videoPath,
    required int durationMs,
    int count = 8,
    int maxWidth = 80,
    int quality = 50,
  }) async {
    if (durationMs <= 0 || count <= 0) {
      return const <Uint8List?>[];
    }

    final times = List<int>.generate(
      count,
      (index) => (durationMs * index / count).round(),
      growable: false,
    );
    final results = List<Uint8List?>.filled(
      times.length,
      null,
      growable: false,
    );
    final missingIndexes = <int>[];

    for (var i = 0; i < times.length; i++) {
      final cacheKey = _frameThumbnailKey(
        videoPath: videoPath,
        timeMs: times[i],
        maxWidth: maxWidth,
        quality: quality,
        exact: false,
      );
      final cached = _readFrameThumbnail(cacheKey);
      if (cached != null || _frameThumbCache.containsKey(cacheKey)) {
        results[i] = cached;
      } else {
        missingIndexes.add(i);
      }
    }

    if (missingIndexes.isEmpty) {
      return results;
    }

    if (Platform.isIOS) {
      try {
        final nativeResults = await _nativePreview.generateThumbnails(
          videoPath: videoPath,
          timesMs: [for (final index in missingIndexes) times[index]],
          maxWidth: maxWidth,
          quality: quality,
          toleranceMs: 200,
        );

        for (var i = 0; i < missingIndexes.length; i++) {
          final index = missingIndexes[i];
          final bytes = i < nativeResults.length ? nativeResults[i] : null;
          final cacheKey = _frameThumbnailKey(
            videoPath: videoPath,
            timeMs: times[index],
            maxWidth: maxWidth,
            quality: quality,
            exact: false,
          );
          _rememberFrameThumbnail(cacheKey, bytes);
          results[index] = bytes;
        }
        return results;
      } on MissingPluginException {
        // Fallback below.
      } on PlatformException {
        // Fallback below.
      }
    }

    final resolved = await Future.wait(
      missingIndexes.map(
        (index) => loadFrameThumbnailData(
          videoPath: videoPath,
          timeMs: times[index],
          maxWidth: maxWidth,
          quality: quality,
          bucketMs: 100,
        ),
      ),
    );

    for (var i = 0; i < missingIndexes.length; i++) {
      results[missingIndexes[i]] = resolved[i];
    }
    return results;
  }

  Future<Uint8List?> _loadFrameThumbnailUncached({
    required String videoPath,
    required int timeMs,
    required int maxWidth,
    required int quality,
    required bool exact,
    required int bucketMs,
  }) async {
    if (Platform.isIOS) {
      try {
        final batch = await _nativePreview.generateThumbnails(
          videoPath: videoPath,
          timesMs: [timeMs],
          maxWidth: maxWidth,
          quality: quality,
          toleranceMs: exact ? 0 : bucketMs,
          exact: exact,
        );
        if (batch.isNotEmpty) {
          return batch.first;
        }
      } on MissingPluginException {
        // Fall through to the plugin package below.
      } on PlatformException {
        // Fall through to the plugin package below.
      }
    }

    return VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      timeMs: timeMs,
      maxWidth: maxWidth,
      quality: quality,
    );
  }

  static String _frameThumbnailKey({
    required String videoPath,
    required int timeMs,
    required int maxWidth,
    required int quality,
    required bool exact,
  }) {
    return '${VideoPathResolver.toRelative(videoPath)}|$timeMs|$maxWidth|$quality|${exact ? '1' : '0'}';
  }

  static Uint8List? _readFrameThumbnail(String key) {
    if (!_frameThumbCache.containsKey(key)) {
      return null;
    }
    final value = _frameThumbCache.remove(key);
    _frameThumbCache[key] = value;
    return value;
  }

  static void _rememberFrameThumbnail(String key, Uint8List? value) {
    _frameThumbCache.remove(key);
    _frameThumbCache[key] = value;
    while (_frameThumbCache.length > _maxFrameThumbEntries) {
      _frameThumbCache.remove(_frameThumbCache.keys.first);
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

    VideoStorageGate.guardWrite(dest);

    await _copyFileWithTimeout(
      source: source,
      destination: File(dest),
      timeout: const Duration(seconds: 90),
    );
    return VideoPathResolver.toRelative(dest);
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
  /// Clears all resolution tiers for the given video path.
  static void invalidateThumbCache(String videoPath) {
    final normalized = VideoPathResolver.toRelative(videoPath);
    _thumbCache.removeWhere((key, _) => key.startsWith(normalized));
  }

  /// Replace a move's video: delete old file + thumbnail, invalidate caches.
  /// Call BEFORE updating the DB path so we still know the old path.
  Future<void> replaceVideo(String? oldPath) async {
    if (oldPath == null) return;
    await deleteVideo(oldPath);
  }

  Future<void> deleteVideo(String path) async {
    final absolutePath = VideoPathResolver.toAbsolute(path);
    invalidateThumbCache(absolutePath);

    final file = File(absolutePath);
    if (await file.exists()) {
      await file.delete();
    }

    final videoName = p.basenameWithoutExtension(absolutePath);
    final thumbFile = File(
      p.join(p.dirname(absolutePath), '.thumbs', '$videoName.jpg'),
    );
    if (await thumbFile.exists()) {
      await thumbFile.delete();
    }

    final docsPath = (await getApplicationDocumentsDirectory()).path;
    await FileSystemUtils.pruneEmptyParents(
      absolutePath,
      stopDir: p.join(docsPath, 'Moves'),
    );
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
