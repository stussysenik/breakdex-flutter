import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/services/native_video_export.dart';
import '../../core/services/video_service.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key, required this.videoPath});

  final String videoPath;

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

enum _EditorVideoLoadState { loading, retrying, ready, missing, error }

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  double _playbackPosition = 0.0;
  bool _isPlaying = false;
  int _selectedSpeedIndex = 2; // 1x default
  int _rotation = 0; // 0, 90, 180, 270
  int _selectedAspectIndex = 0; // Original
  bool _matrixInitialized = false;
  double _viewW = 300.0;
  double _viewH = 300.0;

  final VideoService _videoService = VideoService();
  final TransformationController _transformController =
      TransformationController();
  bool _exporting = false;
  ExportProgress? _exportProgress;
  StreamSubscription<ExportProgress>? _progressSub;

  Duration _videoDuration = Duration.zero;
  VideoPlayerController? _controller;
  List<Uint8List?> _thumbnails = [];
  _EditorVideoLoadState _loadState = _EditorVideoLoadState.loading;
  String? _loadErrorMessage;
  int _loadToken = 0;
  bool _isInternallySeeking = false;

  static const _speeds = [0.25, 0.5, 1.0, 1.5, 2.0];
  static const _speedLabels = ['0.25x', '0.5x', '1x', '1.5x', '2x'];
  static const _kVideoInitTimeout = Duration(seconds: 12);
  static const _kVideoInitRetryDelay = Duration(milliseconds: 350);
  static const _kPlaybackTolerance = 0.002;

  static const _aspectLabels = [
    'Original',
    'Free Form',
    '9:16',
    '16:9',
    '1:1',
    '4:5',
  ];
  static const _aspectRatios = <double?>[
    null, // Original
    null, // Free Form (uses dynamic bounding rect)
    9 / 16,
    16 / 9,
    1.0,
    4 / 5,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadVideo());
  }

  @override
  void didUpdateWidget(covariant VideoEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _trimStart = 0.0;
      _trimEnd = 1.0;
      _playbackPosition = 0.0;
      _isPlaying = false;
      _matrixInitialized = false;
      unawaited(_loadVideo());
    }
  }

  bool get _isEditorReady =>
      _loadState == _EditorVideoLoadState.ready &&
      _controller != null &&
      _controller!.value.isInitialized;

  Future<void> _loadVideo({bool isRetry = false}) async {
    final loadToken = ++_loadToken;
    await _disposeController();
    if (!mounted || loadToken != _loadToken) return;

    setState(() {
      _loadState = isRetry
          ? _EditorVideoLoadState.retrying
          : _EditorVideoLoadState.loading;
      _loadErrorMessage = null;
      _videoDuration = Duration.zero;
      _thumbnails = [];
      _playbackPosition = _trimStart.clamp(0.0, 1.0);
      _isPlaying = false;
    });

    final status = await _videoService.checkVideoFileWithRetry(
      widget.videoPath,
      maxRetries: 3,
    );
    if (!mounted || loadToken != _loadToken) return;

    if (status != VideoFileStatus.ready) {
      setState(() {
        _loadState = switch (status) {
          VideoFileStatus.missing => _EditorVideoLoadState.missing,
          VideoFileStatus.error => _EditorVideoLoadState.error,
          VideoFileStatus.ready => _EditorVideoLoadState.ready,
        };
        _loadErrorMessage = switch (status) {
          VideoFileStatus.missing =>
            'The video is missing or still being downloaded.',
          VideoFileStatus.error =>
            'The video file could not be accessed safely.',
          VideoFileStatus.ready => null,
        };
      });
      return;
    }

    try {
      final controller = await _initializeControllerWithRetry(widget.videoPath);
      if (!mounted || loadToken != _loadToken) {
        await controller.dispose();
        return;
      }

      controller.addListener(_onVideoTick);
      await controller.setLooping(false);

      final duration = controller.value.duration;
      await controller.seekTo(
        _normalizedPositionToDuration(_trimStart, duration: duration),
      );
      if (!mounted || loadToken != _loadToken) {
        controller.removeListener(_onVideoTick);
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _videoDuration = duration;
        _playbackPosition = _trimStart.clamp(0.0, 1.0);
        _isPlaying = false;
        _loadState = _EditorVideoLoadState.ready;
      });
      unawaited(_generateThumbnails());
    } catch (error) {
      if (!mounted || loadToken != _loadToken) return;
      setState(() {
        _loadState = _EditorVideoLoadState.error;
        _loadErrorMessage = error is TimeoutException
            ? 'The video took too long to initialize.'
            : 'Could not load the selected video.';
      });
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_onVideoTick);
    await controller.dispose();
  }

  Future<VideoPlayerController> _initializeControllerWithRetry(
    String videoPath,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      final controller = VideoPlayerController.file(File(videoPath));
      try {
        await controller.initialize().timeout(_kVideoInitTimeout);
        return controller;
      } catch (error) {
        lastError = error;
        await controller.dispose();
        if (attempt == 1) break;
        await Future.delayed(_kVideoInitRetryDelay);
      }
    }
    throw lastError ?? Exception('Video initialization failed');
  }

  double _clampToTrim(double normalized) {
    return normalized.clamp(_trimStart, _trimEnd).toDouble();
  }

  Duration _normalizedPositionToDuration(
    double normalized, {
    Duration? duration,
  }) {
    final totalMs = (duration ?? _videoDuration).inMilliseconds;
    if (totalMs <= 0) return Duration.zero;
    return Duration(
      milliseconds: (normalized.clamp(0.0, 1.0) * totalMs).round(),
    );
  }

  int get _segmentDurationMs {
    final totalMs = _videoDuration.inMilliseconds;
    if (totalMs <= 0) return 0;
    return ((_trimEnd - _trimStart).clamp(0.0, 1.0) * totalMs).round();
  }

  int get _segmentPlaybackMs {
    final totalMs = _videoDuration.inMilliseconds;
    if (totalMs <= 0) return 0;
    final position = _clampToTrim(_playbackPosition);
    return ((position - _trimStart).clamp(0.0, _trimEnd - _trimStart) * totalMs)
        .round();
  }

  Future<void> _seekToNormalized(
    double normalized, {
    bool resumeAfterSeek = false,
  }) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final target = _clampToTrim(normalized);
    _isInternallySeeking = true;
    try {
      await controller.seekTo(_normalizedPositionToDuration(target));
      if (!mounted) return;
      setState(() {
        _playbackPosition = target;
        if (!resumeAfterSeek) {
          _isPlaying = controller.value.isPlaying;
        }
      });
      if (resumeAfterSeek) {
        await controller.play();
        if (mounted) {
          setState(() => _isPlaying = true);
        }
      }
    } finally {
      _isInternallySeeking = false;
    }
  }

  Future<void> _pauseAndSeekToNormalized(double normalized) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
    await _seekToNormalized(normalized);
  }

  void _handleTrimChanged(double start, double end) {
    setState(() {
      _trimStart = start;
      _trimEnd = end;
      _playbackPosition = _playbackPosition.clamp(start, end).toDouble();
    });
  }

  void _handlePlayheadChanged(double position) {
    final clamped = position.clamp(_trimStart, _trimEnd).toDouble();
    setState(() {
      _playbackPosition = clamped;
      _isPlaying = false;
    });
    unawaited(_pauseAndSeekToNormalized(clamped));
  }

  /// Called on every video controller tick — syncs playhead position and
  /// enforces trim-constrained looping (like CapCut/iMovie).
  void _onVideoTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final value = c.value;
    if (value.hasError) {
      if (mounted) {
        setState(() {
          _loadState = _EditorVideoLoadState.error;
          _loadErrorMessage =
              value.errorDescription ?? 'Playback failed unexpectedly.';
          _isPlaying = false;
        });
      }
      return;
    }

    final durationMs = value.duration.inMilliseconds;
    if (durationMs <= 0) return;

    final normalized = (value.position.inMilliseconds / durationMs)
        .clamp(0.0, 1.0)
        .toDouble();
    final reachedTrimEnd = normalized >= (_trimEnd - _kPlaybackTolerance);
    final shouldLoopSegment =
        !_isInternallySeeking &&
        (_isPlaying || value.isPlaying) &&
        (value.isCompleted || reachedTrimEnd);

    if (shouldLoopSegment) {
      unawaited(_seekToNormalized(_trimStart, resumeAfterSeek: true));
      return;
    }

    final clampedPosition = _clampToTrim(normalized);
    final shouldUpdatePosition =
        (clampedPosition - _playbackPosition).abs() > _kPlaybackTolerance;

    if (mounted) {
      if (shouldUpdatePosition || _isPlaying != value.isPlaying) {
        setState(() {
          _playbackPosition = clampedPosition;
          _isPlaying = value.isPlaying;
        });
      }
    }
  }

  /// Toggles play/pause with trim-aware seeking — if the current position
  /// is outside the trim region or at the end, jumps to trim start first.
  Future<void> _togglePlayPause() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
      return;
    }

    final clampedPosition = _clampToTrim(_playbackPosition);
    if (clampedPosition >= (_trimEnd - _kPlaybackTolerance) ||
        clampedPosition < (_trimStart - _kPlaybackTolerance)) {
      await _seekToNormalized(_trimStart);
    } else if ((clampedPosition - _playbackPosition).abs() >
        _kPlaybackTolerance) {
      await _seekToNormalized(clampedPosition);
    }

    await c.play();
    if (mounted) {
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _generateThumbnails() async {
    final currentPath = widget.videoPath;
    final durationMs = _videoDuration.inMilliseconds;
    if (durationMs <= 0) {
      if (mounted) {
        setState(() => _thumbnails = []);
      }
      return;
    }

    final thumbs = <Uint8List?>[];
    for (int i = 0; i < 8; i++) {
      try {
        final ms = (durationMs * i / 8).round();
        final data = await VideoThumbnail.thumbnailData(
          video: widget.videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: ms,
          maxWidth: 80,
          quality: 50,
        );
        thumbs.add(data);
      } catch (_) {
        thumbs.add(null);
      }
    }
    if (mounted && currentPath == widget.videoPath) {
      setState(() => _thumbnails = thumbs);
    }
  }

  @override
  void dispose() {
    _loadToken++;
    _progressSub?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_onVideoTick);
      unawaited(controller.dispose());
    }
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Semantics(
                        label: _exporting ? 'Cancel export' : 'Cancel',
                        button: true,
                        child: GestureDetector(
                          onTap: _exporting
                              ? () async {
                                  await NativeVideoExport.cancel();
                                  if (mounted) {
                                    setState(() => _exporting = false);
                                  }
                                }
                              : () => context.pop(),
                          child: Text(
                            _exporting ? 'Cancel Export' : 'Cancel',
                            style: AppTypography.bodyMedium.copyWith(
                              color: _exporting
                                  ? AppColors.actionAgain
                                  : colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Export video',
                        button: true,
                        enabled: !_exporting && _isEditorReady,
                        child: GestureDetector(
                          onTap: _exporting || !_isEditorReady ? null : _export,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: _exporting || !_isEditorReady
                                  ? colorScheme.surfaceContainerHighest
                                  : AppColors.accent,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              'Export',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _exporting || !_isEditorReady
                                    ? colorScheme.secondary
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Video preview
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge,
                  ),
                  child: _buildVideoPreview(colorScheme),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Scrollable controls
                Expanded(
                  child: _isEditorReady
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: Column(
                            children: [
                              // Trim timeline
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screenEdge,
                                ),
                                child: _TrimTimeline(
                                  trimStart: _trimStart,
                                  trimEnd: _trimEnd,
                                  thumbnails: _thumbnails,
                                  videoPath: widget.videoPath,
                                  videoDurationMs:
                                      _videoDuration.inMilliseconds,
                                  playbackPosition: _playbackPosition,
                                  isPlaying: _isPlaying,
                                  onChanged: (start, end) {
                                    HapticFeedback.selectionClick();
                                    _handleTrimChanged(start, end);
                                  },
                                  onPlayheadChanged: _handlePlayheadChanged,
                                ),
                              ),

                              // Play/pause control + timestamp (like CapCut)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screenEdge,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Semantics(
                                      label: _isPlaying ? 'Pause' : 'Play',
                                      button: true,
                                      child: GestureDetector(
                                        onTap: _togglePlayPause,
                                        child: Icon(
                                          _isPlaying
                                              ? Icons.pause_circle_filled
                                              : Icons.play_circle_filled,
                                          color: AppColors.accent,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      '${_formatDuration(_segmentPlaybackMs.toDouble())} / ${_formatDuration(_segmentDurationMs.toDouble())}',
                                      style: AppTypography.caption.copyWith(
                                        color: colorScheme.secondary,
                                        fontFeatures: [
                                          const FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Speed + Rotation — unified row
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screenEdge,
                                ),
                                child: Row(
                                  children: [
                                    // Speed pills (takes available space)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SPEED',
                                            style: AppTypography.sectionHeader
                                                .copyWith(
                                                  color: colorScheme.secondary,
                                                ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Row(
                                            children: List.generate(
                                                _speedLabels.length, (i) {
                                              final isSelected =
                                                  i == _selectedSpeedIndex;
                                              return Expanded(
                                                child: Semantics(
                                                  label:
                                                      'SPEED ${_speedLabels[i]}',
                                                  button: true,
                                                  selected: isSelected,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      HapticFeedback
                                                          .selectionClick();
                                                      setState(() =>
                                                          _selectedSpeedIndex =
                                                              i);
                                                      _controller
                                                          ?.setPlaybackSpeed(
                                                              _speeds[i]);
                                                    },
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                        left: i > 0
                                                            ? AppSpacing.xs
                                                            : 0,
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        vertical: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? AppColors.accent
                                                            : colorScheme
                                                                .surfaceContainerHighest,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    AppRadius
                                                                        .sm),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          _speedLabels[i],
                                                          style: AppTypography
                                                              .caption
                                                              .copyWith(
                                                            color: isSelected
                                                                ? Colors.white
                                                                : colorScheme
                                                                    .onSurface,
                                                            fontWeight:
                                                                isSelected
                                                                    ? FontWeight
                                                                        .w600
                                                                    : FontWeight
                                                                        .w400,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    // Rotate buttons (fixed width, right-aligned)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          _rotation != 0
                                              ? '$_rotation°'
                                              : 'ROTATE',
                                          style: AppTypography.sectionHeader
                                              .copyWith(
                                            color: _rotation != 0
                                                ? AppColors.accent
                                                : colorScheme.secondary,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _TransformButton(
                                              icon: Icons.rotate_left,
                                              active: _rotation != 0,
                                              onTap: () {
                                                HapticFeedback.mediumImpact();
                                                setState(() {
                                                  _rotation =
                                                      (_rotation - 90) % 360;
                                                  _matrixInitialized = false;
                                                });
                                              },
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.xs),
                                            _TransformButton(
                                              icon: Icons.rotate_right,
                                              active: _rotation != 0,
                                              onTap: () {
                                                HapticFeedback.mediumImpact();
                                                setState(() {
                                                  _rotation =
                                                      (_rotation + 90) % 360;
                                                  _matrixInitialized = false;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Aspect Ratio
                              _buildPillSelector(
                                context,
                                label: 'ASPECT RATIO',
                                items: _aspectLabels,
                                selectedIndex: _selectedAspectIndex,
                                onSelected: (i) {
                                  setState(() {
                                    _selectedAspectIndex = i;
                                    _matrixInitialized = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),

            // Export overlay with real-time progress
            if (_exporting)
              Positioned.fill(
                child: Semantics(
                  label: 'Export in progress',
                  liveRegion: true,
                  child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              // Indeterminate when initializing, determinate when encoding
                              value: (_exportProgress?.isInitializing ?? true)
                                  ? null
                                  : _exportProgress?.progress,
                              color: _exportProgress?.isStalled == true
                                  ? AppColors.actionHard
                                  : AppColors.accent,
                              strokeWidth: 4,
                              backgroundColor: Colors.white24,
                            ),
                            if (_exportProgress != null &&
                                !_exportProgress!.isInitializing)
                              Center(
                                child: Text(
                                  '${(_exportProgress!.progress * 100).round()}%',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _exportProgress?.displayText ?? 'Preparing...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      if (_exportProgress?.isStalled == true) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Export may be slow on this device',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.actionHard,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Using Apple AVFoundation',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillSelector(
    BuildContext context, {
    required String label,
    required List<String> items,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(items.length, (i) {
              final isSelected = i == selectedIndex;
              return Expanded(
                child: Semantics(
                  label: '$label ${items[i]}',
                  button: true,
                  selected: isSelected,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelected(i);
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: i > 0 ? AppSpacing.sm : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Center(
                        child: Text(
                          items[i],
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(ColorScheme colorScheme) {
    if (_loadState == _EditorVideoLoadState.loading ||
        _loadState == _EditorVideoLoadState.retrying) {
      return _buildPreviewStatusCard(
        colorScheme,
        icon: null,
        title: _loadState == _EditorVideoLoadState.retrying
            ? 'Retrying video load...'
            : 'Loading video...',
        subtitle: 'Preparing the editor and syncing the first frame.',
        showSpinner: true,
      );
    }

    if (_loadState == _EditorVideoLoadState.missing ||
        _loadState == _EditorVideoLoadState.error) {
      return _buildPreviewStatusCard(
        colorScheme,
        icon: _loadState == _EditorVideoLoadState.missing
            ? Icons.cloud_off_rounded
            : Icons.error_outline_rounded,
        title: _loadState == _EditorVideoLoadState.missing
            ? 'Video unavailable'
            : 'Video failed to load',
        subtitle: _loadErrorMessage,
        actionLabel: 'Retry',
        onAction: () => unawaited(_loadVideo(isRetry: true)),
      );
    }

    if (!_isEditorReady) {
      return _buildPreviewStatusCard(
        colorScheme,
        icon: Icons.hourglass_bottom_rounded,
        title: 'Preparing editor...',
        subtitle: 'One more moment while the preview becomes available.',
      );
    }

    const playOverlay = Center(
      child: Icon(Icons.play_circle_filled, color: Colors.white70, size: 64),
    );

    final targetAspect = _aspectRatios[_selectedAspectIndex];
    final isFreeForm = _aspectLabels[_selectedAspectIndex] == 'Free Form';
    final isCropMode = targetAspect != null || isFreeForm;
    final videoSize = _controller!.value.size;
    final isRotated = _rotation == 90 || _rotation == 270;
    final orientedWidth = isRotated ? videoSize.height : videoSize.width;
    final orientedHeight = isRotated ? videoSize.width : videoSize.height;

    Widget rawVideo = SizedBox(
      width: videoSize.width,
      height: videoSize.height,
      child: VideoPlayer(_controller!),
    );
    if (_rotation != 0) {
      rawVideo = Transform.rotate(
        angle: _rotation * 3.14159265 / 180,
        child: rawVideo,
      );
    }

    final videoContent = SizedBox(
      width: orientedWidth,
      height: orientedHeight,
      child: Center(
        child: FittedBox(fit: BoxFit.contain, child: rawVideo),
      ),
    );

    if (isCropMode) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          const maxH = 300.0;

          if (targetAspect != null) {
            if (maxW / maxH > targetAspect) {
              _viewH = maxH;
              _viewW = _viewH * targetAspect;
            } else {
              _viewW = maxW;
              _viewH = _viewW / targetAspect;
            }
          } else {
            // Free Form uses full available space for the crop window initially
            _viewW = maxW;
            _viewH = maxH;
          }

          final minScale = math.max(
            _viewW / orientedWidth,
            _viewH / orientedHeight,
          );

          if (!_matrixInitialized) {
            final dx = (_viewW - orientedWidth * minScale) / 2;
            final dy = (_viewH - orientedHeight * minScale) / 2;
            _transformController.value = Matrix4.identity()
              ..translateByDouble(dx, dy, 0, 1)
              ..scaleByDouble(minScale, minScale, 1, 1);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _matrixInitialized = true);
            });
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              height: 300,
              width: double.infinity,
              color: AppColors.darkBg,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: SizedBox(
                      width: _viewW,
                      height: _viewH,
                      child: ClipRect(
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: isFreeForm ? minScale * 0.5 : minScale,
                          maxScale: minScale * 4.0,
                          boundaryMargin: isFreeForm
                              ? const EdgeInsets.all(double.infinity)
                              : EdgeInsets.zero,
                          constrained: false,
                          onInteractionEnd: (_) => setState(() {}),
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: videoContent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_isPlaying) playOverlay,
                  if (isCropMode)
                    IgnorePointer(
                      child: Container(
                        width: _viewW,
                        height: _viewH,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.accent, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            height: 300,
            width: double.infinity,
            color: AppColors.darkBg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: orientedWidth / orientedHeight,
                    child: FittedBox(fit: BoxFit.contain, child: rawVideo),
                  ),
                ),
                if (!_isPlaying)
                  const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white70,
                      size: 64,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPreviewStatusCard(
    ColorScheme colorScheme, {
    required IconData? icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    bool showSpinner = false,
  }) {
    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const CircularProgressIndicator(color: AppColors.accent)
            else if (icon != null)
              Icon(icon, color: Colors.white70, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(color: Colors.white70),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    actionLabel,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            if (!showSpinner && !_exporting) ...[
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'Back',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(double ms) {
    final d = Duration(milliseconds: ms.round());
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$millis';
  }

  Future<void> _export() async {
    if (!_isEditorReady) return;

    setState(() {
      _exporting = true;
      _exportProgress = null;
    });

    // Pause video during export
    _controller?.pause();

    // Listen to progress stream
    _progressSub = NativeVideoExport.progressStream.listen((progress) {
      if (mounted) {
        setState(() => _exportProgress = progress);
      }
    });

    String? outputPath;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final movesDir = Directory(p.join(docs.path, 'Moves'));
      if (!await movesDir.exists()) {
        await movesDir.create(recursive: true);
      }

      outputPath = p.join(movesDir.path, '${const Uuid().v4()}.mp4');

      final trimStartMs = (_trimStart * _videoDuration.inMilliseconds).round();
      final trimEndMs = (_trimEnd * _videoDuration.inMilliseconds).round();
      final speed = _speeds[_selectedSpeedIndex];
      final normalizedRotation = ((_rotation % 360) + 360) % 360;
      final isCropMode =
          _aspectRatios[_selectedAspectIndex] != null ||
          _aspectLabels[_selectedAspectIndex] == 'Free Form';

      Rect? finalCrop;
      if (isCropMode) {
        final matrix = _transformController.value;
        final s = matrix.getMaxScaleOnAxis();
        final tx = matrix.getTranslation().x;
        final ty = matrix.getTranslation().y;

        final videoSize = _controller!.value.size;
        final isRotated = _rotation == 90 || _rotation == 270;
        final orientedWidth = isRotated ? videoSize.height : videoSize.width;
        final orientedHeight = isRotated ? videoSize.width : videoSize.height;

        final left = -tx / s;
        final top = -ty / s;
        final width = _viewW / s;
        final height = _viewH / s;

        final normLeft = (left / orientedWidth).clamp(0.0, 1.0);
        final normTop = (top / orientedHeight).clamp(0.0, 1.0);
        final normWidth = (width / orientedWidth).clamp(0.0, 1.0);
        final normHeight = (height / orientedHeight).clamp(0.0, 1.0);

        finalCrop = Rect.fromLTWH(normLeft, normTop, normWidth, normHeight);
      }

      final result = await NativeVideoExport.export(
        inputPath: widget.videoPath,
        outputPath: outputPath,
        trimStartMs: trimStartMs,
        trimEndMs: trimEndMs,
        speed: speed,
        rotation: normalizedRotation,
        aspectRatio: null,
        cropRect: finalCrop,
      );

      // Wait for iOS to flush the exported file to disk (up to 2s).
      // Without this, the video player may try to load before the file
      // is fully written, causing a black screen with an error icon.
      final exported = File(result);
      var retries = 0;
      while (retries < 20) {
        if (await exported.exists() && await exported.length() > 0) {
          // Additional buffer time for the OS to finalize the file descriptor
          await Future.delayed(const Duration(milliseconds: 300));
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }

      await _videoService.validatePlayableVideo(result);
      await _videoService.generateThumbnail(result);

      // Detach from the main isolate briefly using Future.microtask
      // to ensure UI frames can clear before popping.
      await Future.microtask(() {});

      HapticFeedback.heavyImpact();
      if (mounted) context.pop(result);
    } catch (e) {
      if (outputPath != null) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          await outputFile.delete();
        }
      }
      if (mounted) {
        setState(() {
          _exporting = false;
          _exportProgress = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      _progressSub?.cancel();
      _progressSub = null;
    }
  }
}

class _TrimTimeline extends StatefulWidget {
  const _TrimTimeline({
    required this.trimStart,
    required this.trimEnd,
    required this.thumbnails,
    required this.onChanged,
    required this.videoPath,
    required this.videoDurationMs,
    required this.playbackPosition,
    required this.isPlaying,
    this.onPlayheadChanged,
  });

  final double trimStart;
  final double trimEnd;
  final List<Uint8List?> thumbnails;
  final void Function(double start, double end) onChanged;
  final String videoPath;
  final int videoDurationMs;
  final double playbackPosition; // 0-1 normalized, updated every frame
  final bool isPlaying;
  final ValueChanged<double>? onPlayheadChanged;

  @override
  State<_TrimTimeline> createState() => _TrimTimelineState();
}

class _TrimTimelineState extends State<_TrimTimeline> {
  String? _activeHandle; // 'start', 'end', 'playhead'
  double _playheadPosition = 0.0; // normalized within trim range
  Uint8List? _previewThumbnail;
  double? _previewPosition; // normalized 0-1 for positioning
  final Map<int, Uint8List> _thumbnailCache = {};
  Timer? _thumbnailDebounce;

  @override
  void initState() {
    super.initState();
    _playheadPosition = widget.playbackPosition
        .clamp(widget.trimStart, widget.trimEnd)
        .toDouble();
  }

  void _requestThumbnail(double normalizedPosition) {
    _thumbnailDebounce?.cancel();
    _thumbnailDebounce = Timer(const Duration(milliseconds: 16), () async {
      if (widget.videoDurationMs <= 0) return;
      final ms = (normalizedPosition * widget.videoDurationMs).round();
      final key = (ms / 50).round(); // round to 50ms buckets

      if (_thumbnailCache.containsKey(key)) {
        if (mounted) {
          setState(() => _previewThumbnail = _thumbnailCache[key]);
        }
        return;
      }

      try {
        final data = await VideoThumbnail.thumbnailData(
          video: widget.videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: ms,
          maxWidth: 80,
          quality: 50,
        );
        if (data != null) {
          // LRU eviction at 50 entries
          if (_thumbnailCache.length >= 50) {
            _thumbnailCache.remove(_thumbnailCache.keys.first);
          }
          _thumbnailCache[key] = data;
          if (mounted) {
            setState(() => _previewThumbnail = data);
          }
        }
      } catch (_) {
        // Fallback: no preview
      }
    });
  }

  void _clearDragState() {
    _thumbnailDebounce?.cancel();
    setState(() {
      _activeHandle = null;
      _previewThumbnail = null;
      _previewPosition = null;
      _playheadPosition = widget.playbackPosition
          .clamp(widget.trimStart, widget.trimEnd)
          .toDouble();
    });
  }

  @override
  void didUpdateWidget(_TrimTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeHandle == null) {
      _playheadPosition = widget.playbackPosition
          .clamp(widget.trimStart, widget.trimEnd)
          .toDouble();
      return;
    }

    _playheadPosition = _playheadPosition
        .clamp(widget.trimStart, widget.trimEnd)
        .toDouble();
  }

  @override
  void dispose() {
    _thumbnailDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timelineWidth =
        MediaQuery.of(context).size.width - AppSpacing.screenEdge * 2;

    return SizedBox(
      height: 90, // extra space for floating preview above
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Timeline base (positioned at bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Stack(
                children: [
                  // Thumbnail strip with active highlight
                  Row(
                    children: List.generate(8, (i) {
                      final thumbStart = i / 8;
                      final thumbEnd = (i + 1) / 8;
                      final playhead = _effectivePlayheadPosition;
                      final isActive =
                          playhead >= thumbStart && playhead < thumbEnd;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.darkFill,
                            borderRadius: BorderRadius.circular(4),
                            border: isActive
                                ? Border.all(
                                    color: AppColors.accent,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child:
                              (i < widget.thumbnails.length &&
                                  widget.thumbnails[i] != null)
                              ? Opacity(
                                  opacity: isActive ? 1.0 : 0.6,
                                  child: Image.memory(
                                    widget.thumbnails[i]!,
                                    fit: BoxFit.cover,
                                    height: 52,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  ),

                  // Left dim overlay (before trim start)
                  if (widget.trimStart > 0)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: widget.trimStart * timelineWidth,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  // Right dim overlay (after trim end)
                  if (widget.trimEnd < 1)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: (1 - widget.trimEnd) * timelineWidth,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),

                  // Start handle — 24px hit area, 16px visual
                  Positioned(
                    left: widget.trimStart * timelineWidth - 4,
                    top: 0,
                    bottom: 0,
                    child: Semantics(
                      label: 'Trim start handle',
                      child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) {
                        setState(() {
                          _activeHandle = 'start';
                          _previewPosition = widget.trimStart;
                          _playheadPosition = widget.trimStart;
                        });
                        widget.onPlayheadChanged?.call(widget.trimStart);
                        _requestThumbnail(widget.trimStart);
                      },
                      onHorizontalDragUpdate: (d) {
                        final newStart =
                            (widget.trimStart + d.delta.dx / timelineWidth)
                                .clamp(
                                  0.0,
                                  widget.trimEnd - _minTrimGapNormalized,
                                )
                                .toDouble();
                        widget.onChanged(newStart, widget.trimEnd);
                        setState(() {
                          _playheadPosition = newStart;
                          _previewPosition = newStart;
                        });
                        widget.onPlayheadChanged?.call(newStart);
                        _requestThumbnail(newStart);
                      },
                      onHorizontalDragEnd: (_) => _clearDragState(),
                      child: SizedBox(
                        width: 24,
                        child: Center(
                          child: Container(
                            width: 16,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(6),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.drag_indicator,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ),
                  ),

                  // End handle — 24px hit area, 16px visual
                  Positioned(
                    right: (1 - widget.trimEnd) * timelineWidth - 4,
                    top: 0,
                    bottom: 0,
                    child: Semantics(
                      label: 'Trim end handle',
                      child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) {
                        setState(() {
                          _activeHandle = 'end';
                          _previewPosition = widget.trimEnd;
                          _playheadPosition = widget.trimEnd;
                        });
                        widget.onPlayheadChanged?.call(widget.trimEnd);
                        _requestThumbnail(widget.trimEnd);
                      },
                      onHorizontalDragUpdate: (d) {
                        final newEnd =
                            (widget.trimEnd + d.delta.dx / timelineWidth)
                                .clamp(
                                  widget.trimStart + _minTrimGapNormalized,
                                  1.0,
                                )
                                .toDouble();
                        widget.onChanged(widget.trimStart, newEnd);
                        setState(() {
                          _playheadPosition = newEnd;
                          _previewPosition = newEnd;
                        });
                        widget.onPlayheadChanged?.call(newEnd);
                        _requestThumbnail(newEnd);
                      },
                      onHorizontalDragEnd: (_) => _clearDragState(),
                      child: SizedBox(
                        width: 24,
                        child: Center(
                          child: Container(
                            width: 16,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(6),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.drag_indicator,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ),
                  ),

                  // Playhead (draggable)
                  Positioned(
                    left: _effectivePlayheadPosition * timelineWidth - 1.5,
                    top: 0,
                    bottom: 0,
                    child: Semantics(
                      label: 'Playhead',
                      child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        setState(() {
                          _activeHandle = 'playhead';
                          _previewPosition = _effectivePlayheadPosition;
                          _playheadPosition = _effectivePlayheadPosition;
                        });
                        _requestThumbnail(_effectivePlayheadPosition);
                      },
                      onHorizontalDragUpdate: (d) {
                        final newPos =
                            (_playheadPosition + d.delta.dx / timelineWidth)
                                .clamp(widget.trimStart, widget.trimEnd);
                        setState(() {
                          _playheadPosition = newPos;
                          _previewPosition = newPos;
                        });
                        widget.onPlayheadChanged?.call(newPos);
                        _requestThumbnail(newPos);
                      },
                      onHorizontalDragEnd: (_) => _clearDragState(),
                      child: Container(width: 3, color: Colors.white),
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating preview thumbnail
          if (_activeHandle != null && _previewPosition != null)
            Positioned(
              left: (_previewPosition! * timelineWidth - 40).clamp(
                0.0,
                timelineWidth - 80,
              ),
              top: 0,
              child: Container(
                width: 80,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.darkFill,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _previewThumbnail != null
                    ? Image.memory(_previewThumbnail!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          _formatPreviewTime(),
                          style: AppTypography.caption.copyWith(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  double get _minTrimGapNormalized {
    if (widget.videoDurationMs <= 0) return 0.02;
    return (250 / widget.videoDurationMs).clamp(0.01, 0.5).toDouble();
  }

  double get _effectivePlayheadPosition {
    if (_activeHandle != null) {
      return _playheadPosition.clamp(widget.trimStart, widget.trimEnd);
    }
    if (widget.isPlaying) {
      return widget.playbackPosition.clamp(widget.trimStart, widget.trimEnd);
    }
    return _playheadPosition.clamp(widget.trimStart, widget.trimEnd);
  }

  String _formatPreviewTime() {
    if (_previewPosition == null || widget.videoDurationMs <= 0) return '--:--.--';
    final ms = (_previewPosition! * widget.videoDurationMs).round();
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$millis';
  }
}

class _TransformButton extends StatelessWidget {
  const _TransformButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fill = active
        ? AppColors.accent.withValues(alpha: 0.15)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: icon == Icons.rotate_left ? 'Rotate left' : 'Rotate right',
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: active
              ? Border.all(color: AppColors.accent, width: 1.5)
              : null,
        ),
        child: Icon(
          icon,
          color: active
              ? AppColors.accent
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
    );
  }
}
