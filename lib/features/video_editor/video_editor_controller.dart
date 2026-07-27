// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';
import 'package:breakdex/core/platform/native_media.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:breakdex/core/services/native_video_export.dart';
import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/core/utils/diagnostics.dart';

/// Represents the visual state of the video edits.
class VideoEditState {
  final double trimStart;
  final double trimEnd;
  final int rotation;
  final int selectedSpeedIndex;
  final int selectedAspectIndex;
  final double? customAspectRatio;
  final Rect? cropRect;

  const VideoEditState({
    required this.trimStart,
    required this.trimEnd,
    required this.rotation,
    required this.selectedSpeedIndex,
    required this.selectedAspectIndex,
    this.customAspectRatio,
    this.cropRect,
  });

  factory VideoEditState.initial() => const VideoEditState(
        trimStart: 0.0,
        trimEnd: 1.0,
        rotation: 0,
        selectedSpeedIndex: 2,
        selectedAspectIndex: 0,
      );

  VideoEditState copyWith({
    final double? trimStart,
    final double? trimEnd,
    final int? rotation,
    final int? selectedSpeedIndex,
    final int? selectedAspectIndex,
    final double? customAspectRatio,
    final Rect? cropRect,
  }) {
    return VideoEditState(
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      rotation: rotation ?? this.rotation,
      selectedSpeedIndex: selectedSpeedIndex ?? this.selectedSpeedIndex,
      selectedAspectIndex: selectedAspectIndex ?? this.selectedAspectIndex,
      customAspectRatio: customAspectRatio ?? this.customAspectRatio,
      cropRect: cropRect ?? this.cropRect,
    );
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is VideoEditState &&
          runtimeType == other.runtimeType &&
          trimStart == other.trimStart &&
          trimEnd == other.trimEnd &&
          rotation == other.rotation &&
          selectedSpeedIndex == other.selectedSpeedIndex &&
          selectedAspectIndex == other.selectedAspectIndex &&
          customAspectRatio == other.customAspectRatio &&
          cropRect == other.cropRect;

  @override
  int get hashCode =>
      trimStart.hashCode ^
      trimEnd.hashCode ^
      rotation.hashCode ^
      selectedSpeedIndex.hashCode ^
      selectedAspectIndex.hashCode ^
      customAspectRatio.hashCode ^
      cropRect.hashCode;
}

/// Explicit states for the video editor lifecycle.
sealed class EditorStatus {
  const EditorStatus();
}

class EditorIdle extends EditorStatus {
  const EditorIdle();
}

class EditorInitializing extends EditorStatus {
  const EditorInitializing();
}

class EditorEditing extends EditorStatus {
  final VideoEditState current;
  final VideoEditState committed;
  const EditorEditing({required this.current, required this.committed});
}

class EditorExporting extends EditorStatus {
  final ExportProgress? progress;
  const EditorExporting({this.progress});
}

class EditorError extends EditorStatus {
  final String message;
  const EditorError(this.message);
}

class VideoEditorController extends ChangeNotifier {
  VideoEditorController({required this.videoPath, required final VideoService videoService})
      : _videoService = videoService;

  final String videoPath;
  final VideoService _videoService;

  EditorStatus _status = const EditorIdle();
  EditorStatus get status => _status;

  VideoPlayerController? _playerController;
  VideoPlayerController? get playerController => _playerController;

  final ValueNotifier<double> playbackPosition = ValueNotifier(0.0);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);

  List<Uint8List?> thumbnails = [];
  Duration videoDuration = Duration.zero;
  Timer? _playheadTimer;

  // Shortcuts to current edit state for backward compatibility or easy access
  double get trimStart => _asEditing()?.current.trimStart ?? 0.0;
  double get trimEnd => _asEditing()?.current.trimEnd ?? 1.0;
  int get rotation => _asEditing()?.current.rotation ?? 0;
  int get selectedSpeedIndex => _asEditing()?.current.selectedSpeedIndex ?? 2;
  int get selectedAspectIndex => _asEditing()?.current.selectedAspectIndex ?? 0;
  double? get customAspectRatio => _asEditing()?.current.customAspectRatio;
  Rect? get cropRect => _asEditing()?.current.cropRect;
  
  bool get isInitialized => _status is! EditorIdle && _status is! EditorInitializing;
  bool get isExporting => _status is EditorExporting;
  String? get error => _status is EditorError ? (_status as EditorError).message : null;
  ExportProgress? get exportProgress => _status is EditorExporting ? (_status as EditorExporting).progress : null;

  bool get hasUnsavedChanges {
    final s = _asEditing();
    if (s == null) return false;
    return s.current != s.committed;
  }

  EditorEditing? _asEditing() => _status is EditorEditing ? _status as EditorEditing : null;

  Future<void> initialize() async {
    _status = const EditorInitializing();
    notifyListeners();
    DiagnosticsLog.info(
        'VideoEditor', 'Initializing controller for: $videoPath');

    try {
      final fileStatus = await _videoService.checkVideoFileWithRetry(videoPath);
      if (fileStatus != VideoFileStatus.ready) {
        DiagnosticsLog.error('VideoEditor', 'File not ready: $fileStatus');
        _status = EditorError('Video file not ready: $fileStatus');
        notifyListeners();
        return;
      }

      _playerController = fileVideoController(videoPath);
      await _playerController!.initialize();
      videoDuration = _playerController!.value.duration;
      await _playerController!.setLooping(false);
      _playerController!.addListener(_onPlayerStateChanged);

      _status = EditorEditing(
        current: VideoEditState.initial(),
        committed: VideoEditState.initial(),
      );
      DiagnosticsLog.info(
          'VideoEditor', 'Initialization complete. Duration: $videoDuration');
      notifyListeners();

      unawaited(_generateThumbnails());
    } on Object catch (e) {
      DiagnosticsLog.error('VideoEditor', 'Initialization failed: $e');
      _status = EditorError(e.toString());
      notifyListeners();
    }
  }

  void _onPlayerStateChanged() {
    final player = _playerController;
    if (player == null) return;

    final isNowPlaying = player.value.isPlaying;
    if (isNowPlaying && _playheadTimer == null) {
      _playheadTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _updatePlayhead());
    } else if (!isNowPlaying && _playheadTimer != null) {
      _playheadTimer?.cancel();
      _playheadTimer = null;
    }
    isPlaying.value = isNowPlaying;
  }

  void _updatePlayhead() {
    final player = _playerController;
    if (player == null || !player.value.isInitialized) return;

    final dur = player.value.duration.inMilliseconds;
    if (dur == 0) return;

    final pos = player.value.position.inMilliseconds / dur;
    playbackPosition.value = pos.clamp(0.0, 1.0);

    // Auto-pause at end of trim
    if (player.value.isPlaying && pos >= trimEnd) {
      unawaited(pause());
      unawaited(seekToNormalized(trimStart));
    }
  }

  void updateTrim(final double start, final double end) {
    final s = _asEditing();
    if (s == null) return;

    _status = EditorEditing(
      current: s.current.copyWith(trimStart: start, trimEnd: end),
      committed: s.committed,
    );
    notifyListeners();
    
    if (playbackPosition.value < start || playbackPosition.value > end) {
      unawaited(seekToNormalized(start));
    }
  }

  void setRotation(final int degrees) {
    final s = _asEditing();
    if (s == null) return;
    
    final normalized = ((degrees % 360) + 360) % 360;
    DiagnosticsLog.info('VideoEditor', 'Setting rotation: $normalized°');
    _status = EditorEditing(
      current: s.current.copyWith(rotation: normalized),
      committed: s.committed,
    );
    notifyListeners();
  }

  void setSpeed(final int index) {
    final s = _asEditing();
    if (s == null) return;

    const speeds = [0.25, 0.5, 1.0, 1.5, 2.0];
    final speed = speeds[index];
    DiagnosticsLog.info('VideoEditor', 'Setting speed: ${speed}x');
    unawaited(_playerController?.setPlaybackSpeed(speed));

    _status = EditorEditing(
      current: s.current.copyWith(selectedSpeedIndex: index),
      committed: s.committed,
    );
    notifyListeners();
  }

  void setAspect(final int index, {final double? custom}) {
    final s = _asEditing();
    if (s == null) return;

    DiagnosticsLog.info('VideoEditor', 'Setting aspect index: $index (custom: $custom)');
    _status = EditorEditing(
      current: s.current.copyWith(selectedAspectIndex: index, customAspectRatio: custom),
      committed: s.committed,
    );
    notifyListeners();
  }

  void updateCrop(final Rect crop) {
    final s = _asEditing();
    if (s == null) return;

    if (s.current.cropRect == crop) return;

    _status = EditorEditing(
      current: s.current.copyWith(cropRect: crop),
      committed: s.committed,
    );
    notifyListeners();
  }

  void commitEdits() {
    final s = _asEditing();
    if (s == null) return;

    _status = EditorEditing(
      current: s.current,
      committed: s.current,
    );
    notifyListeners();
  }

  void revertToCommitted() {
    final s = _asEditing();
    if (s == null) return;

    _status = EditorEditing(
      current: s.committed,
      committed: s.committed,
    );
    notifyListeners();
    unawaited(seekToNormalized(s.committed.trimStart));
  }

  Future<void> seekToNormalized(final double normalized) async {
    final player = _playerController;
    if (player == null || !player.value.isInitialized) return;
    final ms = (normalized * videoDuration.inMilliseconds).round();
    await player.seekTo(Duration(milliseconds: ms));
    playbackPosition.value = normalized.clamp(0.0, 1.0);
  }

  Future<void> play() async {
    final player = _playerController;
    if (player == null || !player.value.isInitialized) return;
    if (playbackPosition.value >= trimEnd - 0.01) {
      await seekToNormalized(trimStart);
    }
    await player.play();
  }

  Future<void> pause() async {
    final player = _playerController;
    if (player == null || !player.value.isInitialized) return;
    await player.pause();
  }

  Future<void> togglePlay() async {
    final player = _playerController;
    if (player == null || !player.value.isInitialized) return;
    if (player.value.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> _generateThumbnails() async {
    final thumbs = <Uint8List?>[];
    for (int i = 0; i < 8; i++) {
      try {
        final ms = (videoDuration.inMilliseconds * i / 8).round();
        final data = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: ms,
          maxWidth: 160,
          quality: 50,
        );
        thumbs.add(data);
      } on Object catch (_) {
        thumbs.add(null);
      }
    }
    thumbnails = thumbs;
    notifyListeners();
  }

  Future<String?> export() async {
    final s = _asEditing();
    if (s == null) return null;

    final originalStatus = _status;
    _status = const EditorExporting();
    notifyListeners();

    unawaited(pause());

    final log = StageLogger.begin('export', subsystem: 'VideoEditor', context: {
      'input': videoPath,
      'trimStart': s.current.trimStart,
      'trimEnd': s.current.trimEnd,
      'rotation': s.current.rotation,
      'aspectIndex': s.current.selectedAspectIndex,
      'cropRect': s.current.cropRect?.toString(),
    });

    final progressSub = NativeVideoExport.progressStream.listen((final p) {
      if (_status is EditorExporting) {
        _status = EditorExporting(progress: p);
        notifyListeners();
      }
    });

    try {
      final speeds = [0.25, 0.5, 1.0, 1.5, 2.0];
      // Index 0 (Original) and 1 (Free Form) impose no aspect constraint.
      final aspectStrings = <String?>[
        null,
        null,
        '9:16',
        '16:9',
        '1:1',
        '4:5',
        'Custom'
      ];

      final docs = await _videoService.getMovesDirectory();
      final outputPath = p.join(docs.path, '${const Uuid().v4()}.mp4');

      // WYSIWYG: the crop window already encodes the chosen aspect ratio, so a
      // real crop is always exported via cropRect (preview == output). Only a
      // genuinely untouched full frame falls back to the aspect string, which
      // is null unless a fixed ratio was picked without any reframing.
      final crop = s.current.cropRect;
      final isFullFrame = crop == null ||
          (crop.left <= 0.001 &&
              crop.top <= 0.001 &&
              crop.right >= 0.999 &&
              crop.bottom >= 0.999);

      log.stage('startingNativeExport', {'output': outputPath, 'fullFrame': isFullFrame});
      final result = await NativeVideoExport.export(
        inputPath: videoPath,
        outputPath: outputPath,
        trimStartMs:
            (s.current.trimStart * videoDuration.inMilliseconds).round(),
        trimEndMs: (s.current.trimEnd * videoDuration.inMilliseconds).round(),
        speed: speeds[s.current.selectedSpeedIndex],
        rotation: s.current.rotation,
        aspectRatio: isFullFrame ? aspectStrings[s.current.selectedAspectIndex] : null,
        cropRect: isFullFrame ? null : crop,
      ).timeout(const Duration(seconds: 120));

      log.complete(result);
      _status = originalStatus; // Return to editing or wait for pop
      notifyListeners();
      return result;
    } on Object catch (e, stack) {
      log.fail(e, stack);
      _status = EditorError('Export failed: $e');
      notifyListeners();
      return null;
    } finally {
      await progressSub.cancel();
    }
  }

  @override
  void dispose() {
    _playheadTimer?.cancel();
    if (_playerController != null) {
      _playerController!.removeListener(_onPlayerStateChanged);
      _playerController!.dispose();
    }
    playbackPosition.dispose();
    isPlaying.dispose();
    super.dispose();
  }
}
