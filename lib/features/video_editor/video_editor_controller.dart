import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/services/native_video_export.dart';
import '../../core/services/video_service.dart';

class VideoEditorController extends ChangeNotifier {
  VideoEditorController({required this.videoPath, required VideoService videoService})
      : _videoService = videoService;

  final String videoPath;
  final VideoService _videoService;

  VideoPlayerController? _playerController;
  VideoPlayerController? get playerController => _playerController;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _error;
  String? get error => _error;

  double _trimStart = 0.0;
  double get trimStart => _trimStart;

  double _trimEnd = 1.0;
  double get trimEnd => _trimEnd;

  int _rotation = 0;
  int get rotation => _rotation;

  int _selectedSpeedIndex = 2; // 1x
  int get selectedSpeedIndex => _selectedSpeedIndex;

  int _selectedAspectIndex = 0;
  int get selectedAspectIndex => _selectedAspectIndex;

  double? _customAspectRatio;
  double? get customAspectRatio => _customAspectRatio;

  final ValueNotifier<double> playbackPosition = ValueNotifier(0.0);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);

  List<Uint8List?> thumbnails = [];
  Duration videoDuration = Duration.zero;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  ExportProgress? _exportProgress;
  ExportProgress? get exportProgress => _exportProgress;

  Future<void> initialize() async {
    try {
      final status = await _videoService.checkVideoFileWithRetry(videoPath);
      if (status != VideoFileStatus.ready) {
        _error = 'Video file not ready: $status';
        notifyListeners();
        return;
      }

      _playerController = VideoPlayerController.file(File(videoPath));
      await _playerController!.initialize();
      videoDuration = _playerController!.value.duration;
      _playerController!.setLooping(false);
      _playerController!.addListener(_onTick);

      _isInitialized = true;
      notifyListeners();

      unawaited(_generateThumbnails());
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }


  void _onTick() {
    if (_playerController == null) return;
    final dur = videoDuration.inMilliseconds.clamp(1, 999999999);
    final pos = _playerController!.value.position.inMilliseconds / dur;
    playbackPosition.value = pos.clamp(0.0, 1.0);
    isPlaying.value = _playerController!.value.isPlaying;
    
    // Auto-loop within trim range
    if (_playerController!.value.isPlaying && pos >= _trimEnd) {
      seekToNormalized(_trimStart);
    }
  }

  void updateTrim(double start, double end) {
    _trimStart = start;
    _trimEnd = end;
    notifyListeners();
    
    // Seek to start if playhead is out of range
    if (playbackPosition.value < _trimStart || playbackPosition.value > _trimEnd) {
      seekToNormalized(_trimStart);
    }
  }

  void setRotation(int degrees) {
    _rotation = ((degrees % 360) + 360) % 360;
    notifyListeners();
  }

  void setSpeed(int index) {
    _selectedSpeedIndex = index;
    notifyListeners();
  }

  void setAspect(int index, {double? custom}) {
    _selectedAspectIndex = index;
    if (custom != null) _customAspectRatio = custom;
    notifyListeners();
  }

  Future<void> seekToNormalized(double normalized) async {
    if (!_isInitialized || _playerController == null) return;
    final ms = (normalized * videoDuration.inMilliseconds).round();
    await _playerController!.seekTo(Duration(milliseconds: ms));
    playbackPosition.value = normalized.clamp(0.0, 1.0);
  }

  Future<void> togglePlay() async {
    if (!_isInitialized || _playerController == null) return;
    if (_playerController!.value.isPlaying) {
      await _playerController!.pause();
    } else {
      if (playbackPosition.value >= _trimEnd - 0.01) {
        await seekToNormalized(_trimStart);
      }
      await _playerController!.play();
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
      } catch (_) {
        thumbs.add(null);
      }
    }
    thumbnails = thumbs;
    notifyListeners();
  }

  Future<String?> export() async {
    _isExporting = true;
    _error = null;
    notifyListeners();

    _playerController?.pause();

    final progressSub = NativeVideoExport.progressStream.listen((p) {
      _exportProgress = p;
      notifyListeners();
    });

    try {
      final speeds = [0.25, 0.5, 1.0, 1.5, 2.0];
      final aspectStrings = <String?>[null, 'Free Form', '9:16', '16:9', '1:1', '4:5', 'Custom'];
      
      final docs = await _videoService.getMovesDirectory();
      final outputPath = p.join(docs.path, '${const Uuid().v4()}.mp4');

      final result = await NativeVideoExport.export(
        inputPath: videoPath,
        outputPath: outputPath,
        trimStartMs: (_trimStart * videoDuration.inMilliseconds).round(),
        trimEndMs: (_trimEnd * videoDuration.inMilliseconds).round(),
        speed: speeds[_selectedSpeedIndex],
        rotation: _rotation,
        aspectRatio: aspectStrings[_selectedAspectIndex],
      ).timeout(const Duration(seconds: 120));

      _isExporting = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isExporting = false;
      _error = 'Export failed: $e';
      notifyListeners();
      return null;
    } finally {
      await progressSub.cancel();
    }
  }

  @override
  void dispose() {
    _playerController?.removeListener(_onTick);
    _playerController?.dispose();
    playbackPosition.dispose();
    isPlaying.dispose();
    super.dispose();
  }
}
