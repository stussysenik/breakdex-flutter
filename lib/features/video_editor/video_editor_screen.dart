import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/navigation/app_route_observer.dart';
import '../../core/services/media_playback_coordinator.dart';
import '../../core/services/native_video_export.dart';
import '../../core/services/video_service.dart';
import '../../core/utils/pid_controller.dart';
import 'video_edit_geometry.dart';
import 'trim_timeline_math.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key, required this.videoPath});

  final String videoPath;

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

enum _EditorVideoLoadState { loading, retrying, ready, missing, error }

class _VideoEditorScreenState extends State<VideoEditorScreen>
    with RouteAware, WidgetsBindingObserver {
  double _trimStart = 0.0;
  double _trimEnd = 1.0;

  /// Per-frame playback position as a ValueNotifier — only the playhead and
  /// timestamp widgets listen via ValueListenableBuilder, avoiding full-tree
  /// rebuilds at 30-60fps.
  final ValueNotifier<double> _playbackPosition = ValueNotifier(0.0);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  bool _isDragging = false;
  int _selectedSpeedIndex = 2; // 1x default
  int _rotation = 0; // 0, 90, 180, 270
  int _selectedAspectIndex = 0; // Original
  bool _matrixInitialized = false;
  Size? _previewViewportSize;
  double? _previewAvailableWidth;

  final VideoService _videoService = VideoService();
  final TransformationController _transformController =
      TransformationController();
  final PidController _pidController = PidController();
  double _gestureBaseScale = 1.0;
  final Stopwatch _scaleStopwatch = Stopwatch();
  bool _exporting = false;
  ExportProgress? _exportProgress;
  StreamSubscription<ExportProgress>? _progressSub;
  DateTime? _exportStartedAt;
  Timer? _exportHangTimer;

  Duration _videoDuration = Duration.zero;
  VideoPlayerController? _controller;
  List<Uint8List?> _thumbnails = [];
  _EditorVideoLoadState _loadState = _EditorVideoLoadState.loading;
  String? _loadErrorMessage;
  int _loadToken = 0;
  bool _isInternallySeeking = false;
  final String _playbackId = UniqueKey().toString();
  ModalRoute<dynamic>? _route;

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
    WidgetsBinding.instance.addObserver(this);
    MediaPlaybackCoordinator.shared.attach(
      playbackId: _playbackId,
      onPause: _pausePlayback,
    );
    _scaleStopwatch.start();
    unawaited(_loadVideo());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextRoute = ModalRoute.of(context);
    if (_route != nextRoute) {
      if (_route is ModalRoute<dynamic>) {
        appRouteObserver.unsubscribe(this);
      }
      _route = nextRoute;
      if (nextRoute is ModalRoute<dynamic>) {
        appRouteObserver.subscribe(this, nextRoute);
      }
    }
  }

  @override
  void didUpdateWidget(covariant VideoEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _trimStart = 0.0;
      _trimEnd = 1.0;
      _playbackPosition.value = 0.0;
      _isPlaying.value = false;
      _matrixInitialized = false;
      _previewViewportSize = null;
      _previewAvailableWidth = null;
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

    _playbackPosition.value = _trimStart.clamp(0.0, 1.0);
    _isPlaying.value = false;
    setState(() {
      _loadState = isRetry
          ? _EditorVideoLoadState.retrying
          : _EditorVideoLoadState.loading;
      _loadErrorMessage = null;
      _videoDuration = Duration.zero;
      _thumbnails = [];
      _matrixInitialized = false;
      _previewViewportSize = null;
      _previewAvailableWidth = null;
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

      _playbackPosition.value = _trimStart.clamp(0.0, 1.0);
      _isPlaying.value = false;
      setState(() {
        _controller = controller;
        _videoDuration = duration;
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
    MediaPlaybackCoordinator.shared.release(_playbackId);
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
    final position = _clampToTrim(_playbackPosition.value);
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
      _playbackPosition.value = target;
      if (!resumeAfterSeek) {
        _isPlaying.value = controller.value.isPlaying;
      }
      if (resumeAfterSeek) {
        await controller.play();
        if (mounted) {
          _isPlaying.value = true;
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
        _isPlaying.value = false;
      }
    }
    await _seekToNormalized(normalized);
  }

  void _handleTrimChanged(double start, double end) {
    _trimStart = start;
    _trimEnd = end;
    _playbackPosition.value = _playbackPosition.value
        .clamp(start, end)
        .toDouble();
    // During active drag, skip the parent setState — the _TrimTimeline manages
    // its own display via internal state. Only rebuild on drag end.
    if (!_isDragging) {
      setState(() {});
    }
  }

  void _handlePlayheadChanged(double position) {
    final clamped = position.clamp(_trimStart, _trimEnd).toDouble();
    _playbackPosition.value = clamped;
    _isPlaying.value = false;
    unawaited(_pauseAndSeekToNormalized(clamped));
  }

  /// Called on every video controller tick — syncs playhead position and
  /// enforces trim-constrained looping (like CapCut/iMovie).
  ///
  /// Updates ValueNotifiers instead of calling setState, so only the playhead
  /// and timestamp widgets rebuild (~3 lightweight widgets) rather than the
  /// entire 2000+ line widget tree at 30-60fps.
  void _onVideoTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final value = c.value;
    if (value.hasError) {
      if (mounted) {
        _isPlaying.value = false;
        setState(() {
          _loadState = _EditorVideoLoadState.error;
          _loadErrorMessage =
              value.errorDescription ?? 'Playback failed unexpectedly.';
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
        (_isPlaying.value || value.isPlaying) &&
        (value.isCompleted || reachedTrimEnd);

    if (shouldLoopSegment) {
      unawaited(_seekToNormalized(_trimStart, resumeAfterSeek: true));
      return;
    }

    final clampedPosition = _clampToTrim(normalized);
    final shouldUpdatePosition =
        (clampedPosition - _playbackPosition.value).abs() > _kPlaybackTolerance;

    if (mounted) {
      if (shouldUpdatePosition) {
        _playbackPosition.value = clampedPosition;
      }
      if (_isPlaying.value != value.isPlaying) {
        _isPlaying.value = value.isPlaying;
      }
    }
  }

  /// Toggles play/pause with trim-aware seeking — if the current position
  /// is outside the trim region or at the end, jumps to trim start first.
  Future<void> _togglePlayPause() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      _pausePlayback();
      return;
    }

    final clampedPosition = _clampToTrim(_playbackPosition.value);
    if (clampedPosition >= (_trimEnd - _kPlaybackTolerance) ||
        clampedPosition < (_trimStart - _kPlaybackTolerance)) {
      await _seekToNormalized(_trimStart);
    } else if ((clampedPosition - _playbackPosition.value).abs() >
        _kPlaybackTolerance) {
      await _seekToNormalized(clampedPosition);
    }

    MediaPlaybackCoordinator.shared.claimPrimary(_playbackId);
    await c.play();
    if (mounted) {
      _isPlaying.value = true;
      setState(() {}); // Rebuild to update play overlay
    }
  }

  void _pausePlayback() {
    final controller = _controller;
    MediaPlaybackCoordinator.shared.release(_playbackId);
    if (controller != null && controller.value.isPlaying) {
      unawaited(controller.pause());
    }
    if (_isPlaying.value) {
      _isPlaying.value = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// Generates 8 evenly-spaced thumbnails across the video duration.
  /// Loads one at a time so the timeline progressively fills in — each
  /// thumbnail appears as soon as it's decoded rather than all popping
  /// in after a multi-second wait.
  Future<void> _generateThumbnails() async {
    final currentPath = widget.videoPath;
    final durationMs = _videoDuration.inMilliseconds;
    if (durationMs <= 0) {
      if (mounted) setState(() => _thumbnails = []);
      return;
    }

    const count = 8;
    if (mounted) {
      setState(() => _thumbnails = List<Uint8List?>.filled(count, null));
    }

    final times = List<int>.generate(
      count,
      (i) => (durationMs * i / count).round(),
    );
    for (var i = 0; i < count; i++) {
      if (!mounted || currentPath != widget.videoPath) return;
      final thumb = await _videoService.loadFrameThumbnailData(
        videoPath: currentPath,
        timeMs: times[i],
        maxWidth: 80,
        quality: 50,
        bucketMs: 100,
      );
      if (mounted && currentPath == widget.videoPath) {
        setState(() => _thumbnails[i] = thumb);
      }
    }
  }

  void _applyClampedPreviewTransform(
    VideoEditViewport viewport, {
    bool force = false,
  }) {
    final next = force
        ? viewport.initialTransform()
        : viewport.clampTransform(_transformController.value);
    if (force || !matrixCloseTo(_transformController.value, next)) {
      _transformController.value = next;
    }
  }

  bool _hasViewportChanged(Size next) {
    final current = _previewViewportSize;
    if (current == null) return true;
    return (current.width - next.width).abs() > 0.5 ||
        (current.height - next.height).abs() > 0.5;
  }

  @override
  void dispose() {
    _loadToken++;
    WidgetsBinding.instance.removeObserver(this);
    if (_route is ModalRoute<dynamic>) {
      appRouteObserver.unsubscribe(this);
    }
    MediaPlaybackCoordinator.shared.detach(_playbackId);
    _progressSub?.cancel();
    _exportHangTimer?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_onVideoTick);
      unawaited(controller.dispose());
    }
    _playbackPosition.dispose();
    _isPlaying.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() => _pausePlayback();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _pausePlayback();
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
                                  : colorScheme.primary,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
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
                                  onChanged: _handleTrimChanged,
                                  onPlayheadChanged: _handlePlayheadChanged,
                                  onDragStart: () => _isDragging = true,
                                  onDragEnd: () {
                                    _isDragging = false;
                                    setState(() {});
                                  },
                                ),
                              ),

                              // Play/pause control + timestamp (like CapCut)
                              // Wrapped in ValueListenableBuilder so these
                              // update per-frame without rebuilding the tree.
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screenEdge,
                                  vertical: AppSpacing.sm,
                                ),
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: _isPlaying,
                                  builder: (context, isPlaying, _) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Semantics(
                                          label: isPlaying ? 'Pause' : 'Play',
                                          button: true,
                                          child: GestureDetector(
                                            onTap: _togglePlayPause,
                                            child: Icon(
                                              isPlaying
                                                  ? Icons.pause_circle_filled
                                                  : Icons.play_circle_filled,
                                              color: colorScheme.primary,
                                              size: 36,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        ValueListenableBuilder<double>(
                                          valueListenable: _playbackPosition,
                                          builder: (context, _, _) {
                                            return Text(
                                              '${_formatDuration(_segmentPlaybackMs.toDouble())} / ${_formatDuration(_segmentDurationMs.toDouble())}',
                                              style: AppTypography.caption.copyWith(
                                                color: colorScheme.secondary,
                                                fontFeatures: [
                                                  const FontFeature.tabularFigures(),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
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
                                            children: List.generate(_speedLabels.length, (
                                              i,
                                            ) {
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
                                                      HapticFeedback.selectionClick();
                                                      setState(
                                                        () =>
                                                            _selectedSpeedIndex =
                                                                i,
                                                      );
                                                      _controller
                                                          ?.setPlaybackSpeed(
                                                            _speeds[i],
                                                          );
                                                    },
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                        left: i > 0
                                                            ? AppSpacing.xs
                                                            : 0,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? colorScheme
                                                                  .primary
                                                            : colorScheme
                                                                  .surfaceContainerHighest,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              AppRadius.sm,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          _speedLabels[i],
                                                          style: AppTypography
                                                              .caption
                                                              .copyWith(
                                                                color:
                                                                    isSelected
                                                                    ? Colors
                                                                          .white
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
                                                    ? colorScheme.primary
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
                                                  _previewViewportSize = null;
                                                });
                                              },
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.xs,
                                            ),
                                            _TransformButton(
                                              icon: Icons.rotate_right,
                                              active: _rotation != 0,
                                              onTap: () {
                                                HapticFeedback.mediumImpact();
                                                setState(() {
                                                  _rotation =
                                                      (_rotation + 90) % 360;
                                                  _matrixInitialized = false;
                                                  _previewViewportSize = null;
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
                                    _previewViewportSize = null;
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
                                    : colorScheme.primary,
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
                        if (_exportProgress != null &&
                            !_exportProgress!.isEncoding &&
                            !_exportProgress!.isDone &&
                            _exportStartedAt != null &&
                            DateTime.now()
                                    .difference(_exportStartedAt!)
                                    .inSeconds >
                                5) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Taking longer than expected...',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white54,
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
                            ? colorScheme.primary
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
          _previewAvailableWidth = maxW;
          final viewport = computeVideoEditViewport(
            videoSize: videoSize,
            rotation: _rotation,
            maxWidth: maxW,
            targetAspect: targetAspect,
          );
          final viewportSize = viewport.size;

          // Guard transform mutations with addPostFrameCallback to avoid
          // mutating _transformController.value during the build phase.
          if (!_matrixInitialized || _hasViewportChanged(viewportSize)) {
            _previewViewportSize = viewportSize;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _applyClampedPreviewTransform(viewport, force: true);
              setState(() => _matrixInitialized = true);
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _applyClampedPreviewTransform(viewport);
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
                      width: viewportSize.width,
                      height: viewportSize.height,
                      child: ClipRect(
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: viewport.minScale,
                          maxScale: viewport.maxScale,
                          boundaryMargin: EdgeInsets.zero,
                          constrained: false,
                          onInteractionStart: (_) {
                            _gestureBaseScale = _transformController.value
                                .getMaxScaleOnAxis();
                          },
                          onInteractionUpdate: (details) {
                            final dt =
                                _scaleStopwatch.elapsedMilliseconds / 1000.0;
                            _scaleStopwatch.reset();
                            final currentScale = _transformController
                                .value
                                .getMaxScaleOnAxis();

                            // Map gesture-relative scale to absolute viewport scale
                            final rawTarget = (_gestureBaseScale *
                                    details.scale)
                                .clamp(viewport.minScale, viewport.maxScale);

                            // Zoom-in-only: never retreat below current scale
                            final target =
                                rawTarget.clamp(currentScale, viewport.maxScale);

                            // Dead zone: ignore micro-twitches (senior-friendly)
                            if ((target - currentScale).abs() < 0.008) return;

                            // PID computes a correction delta (not absolute scale)
                            final delta = _pidController.update(
                              target,
                              currentScale,
                              dt > 0 ? dt : 0.016,
                            );

                            // Rate limit: prevent jarring jumps, allow tiny back-off
                            final clampedDelta = delta.clamp(-0.004, 0.06);

                            final newScale = (currentScale + clampedDelta)
                                .clamp(viewport.minScale, viewport.maxScale);

                            _transformController.value =
                                Matrix4.identity()..scale(newScale);
                            _applyClampedPreviewTransform(viewport);
                          },
                          onInteractionEnd: (_) {
                            _pidController.reset();
                            _applyClampedPreviewTransform(viewport);
                            setState(() {});
                          },
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: videoContent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_isPlaying.value) playOverlay,
                  if (isCropMode)
                    IgnorePointer(
                      child: Container(
                        width: viewportSize.width,
                        height: viewportSize.height,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
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
                if (!_isPlaying.value)
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
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              )
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
                    color: Theme.of(context).colorScheme.primary,
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
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$seconds.$millis';
  }

  Future<void> _export() async {
    if (!_isEditorReady) return;

    setState(() {
      _exporting = true;
      _exportProgress = null;
      _exportStartedAt = DateTime.now();
    });

    // Pause video during export
    _pausePlayback();

    // Listen to progress stream
    _progressSub = NativeVideoExport.progressStream.listen((progress) {
      if (mounted) {
        setState(() => _exportProgress = progress);
      }
    });

    // Hang detector — if pre-encoding takes >6s, trigger a rebuild so the
    // overlay can show a "taking longer than expected" hint.
    _exportHangTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _exporting) setState(() {});
    });

    String? outputPath;
    try {
      final fallbackPreviewWidth =
          MediaQuery.of(context).size.width - AppSpacing.screenEdge * 2;
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
        final targetAspect = _aspectRatios[_selectedAspectIndex];
        final previewMaxWidth = _previewAvailableWidth ?? fallbackPreviewWidth;
        final viewport = computeVideoEditViewport(
          videoSize: _controller!.value.size,
          rotation: _rotation,
          maxWidth: previewMaxWidth,
          targetAspect: targetAspect,
        );
        final cropRect = viewport.normalizedCropRect(
          _transformController.value,
        );
        final normWidth = cropRect.width;
        final normHeight = cropRect.height;

        if (normWidth < 0.01 || normHeight < 0.01) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Crop region is out of bounds. Pan the video back into view.',
                ),
              ),
            );
            setState(() {
              _exporting = false;
              _exportProgress = null;
            });
          }
          return;
        }

        finalCrop = cropRect;
      }

      // 120-second safety timeout — if the native AVFoundation export
      // hangs (e.g. GPU stall, corrupt asset), the overlay won't stay
      // forever.  The user sees an error and can retry.
      final result = await NativeVideoExport.export(
        inputPath: widget.videoPath,
        outputPath: outputPath,
        trimStartMs: trimStartMs,
        trimEndMs: trimEndMs,
        speed: speed,
        rotation: normalizedRotation,
        aspectRatio: null,
        cropRect: finalCrop,
      ).timeout(const Duration(seconds: 120));

      // The native export returns the path only after AVAssetExportSession
      // completes, so the file is guaranteed to exist on disk.
      final exported = File(result);
      if (!await exported.exists() || await exported.length() == 0) {
        throw Exception('Export completed but output file is missing or empty');
      }

      // Fire-and-forget — don't block the UI waiting for a thumbnail.
      unawaited(_videoService.generateThumbnail(result));

      // Detach from the main isolate briefly using Future.microtask
      // to ensure UI frames can clear before popping.
      await Future.microtask(() {});

      unawaited(HapticFeedback.heavyImpact());
      if (mounted) context.pop(result);
    } catch (e) {
      debugPrint('Export failed: $e');
      if (outputPath != null) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          await outputFile.delete();
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      unawaited(_progressSub?.cancel());
      _progressSub = null;
      _exportHangTimer?.cancel();
      _exportHangTimer = null;
      if (mounted && _exporting) {
        setState(() {
          _exporting = false;
          _exportProgress = null;
          _exportStartedAt = null;
        });
      }
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
    this.onDragStart,
    this.onDragEnd,
  });

  final double trimStart;
  final double trimEnd;
  final List<Uint8List?> thumbnails;
  final void Function(double start, double end) onChanged;
  final String videoPath;
  final int videoDurationMs;

  /// Per-frame playback position as a ValueListenable — the playhead and
  /// active-tile highlight listen via ListenableBuilder to avoid rebuilding
  /// the entire timeline (8 thumbnails + handles) every frame.
  final ValueListenable<double> playbackPosition;
  final ValueListenable<bool> isPlaying;
  final ValueChanged<double>? onPlayheadChanged;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  @override
  State<_TrimTimeline> createState() => _TrimTimelineState();
}

class _TrimTimelineState extends State<_TrimTimeline> {
  final VideoService _videoService = VideoService();
  static const _kHandleVisualWidth = 22.0;
  static const _kFineScrubIndicatorLiftPx = 18.0;

  /// Maximum pixel distance from a touch point to a handle center
  /// for the handle to be "grabbed". Prevents accidental grabs from
  /// taps in the middle of the timeline.
  static const _kGrabRadiusPx = 30.0;

  String? _activeHandle; // 'start', 'end', 'playhead'
  double _playheadPosition = 0.0; // normalized within trim range
  double? _dragValue;
  double?
  _dragRawValue; // unsnapped accumulator — prevents drift from repeated snapping
  Offset? _dragOrigin;
  double _dragVerticalLiftPx = 0.0;

  /// Throttle gates for expensive platform-channel calls during drag.
  /// Video seek and haptic at 60fps overwhelm the native bridge and
  /// cause visible handle lag. ~12Hz (80ms) is the sweet spot — fast
  /// enough to feel responsive, slow enough to avoid queue buildup.
  int _lastSeekMs = 0;
  int _lastHapticMs = 0;
  static const _kSeekThrottleMs = 80;
  static const _kHapticThrottleMs = 80;

  // Single floating preview thumbnail — only shown during handle drag.
  Uint8List? _previewThumbnail;
  double? _previewPosition; // normalized position for the floating preview

  final Map<int, Uint8List> _thumbnailCache = {};

  /// Timestamp of the last thumbnail request — used as a throttle gate at
  /// ~48ms (≈20fps) to avoid Timer allocation churn during drag.
  int _lastThumbRequestMs = 0;

  // Persistent keyframe thumbnails shown inside each trim handle so the user
  // can see exactly which frame the handle is positioned at.
  Uint8List? _startHandleThumb;
  Uint8List? _endHandleThumb;

  @override
  void initState() {
    super.initState();
    _playheadPosition = widget.playbackPosition.value
        .clamp(widget.trimStart, widget.trimEnd)
        .toDouble();
    _loadHandleThumbnails();
  }

  /// Loads keyframe thumbnails for both trim handles.
  void _loadHandleThumbnails() {
    _fetchHandleThumb(widget.trimStart, isStart: true);
    _fetchHandleThumb(widget.trimEnd, isStart: false);
  }

  /// Fetches an exact keyframe thumbnail for a trim handle position.
  /// Uses the shared `_thumbnailCache` for O(1) cache hits.
  Future<void> _fetchHandleThumb(
    double position, {
    required bool isStart,
  }) async {
    if (widget.videoDurationMs <= 0) return;
    final ms = (position * widget.videoDurationMs).round();
    final key = (ms / 50).round();

    if (_thumbnailCache.containsKey(key)) {
      if (mounted) {
        setState(() {
          if (isStart) {
            _startHandleThumb = _thumbnailCache[key];
          } else {
            _endHandleThumb = _thumbnailCache[key];
          }
        });
      }
      return;
    }

    try {
      final data = await _videoService.loadFrameThumbnailData(
        videoPath: widget.videoPath,
        timeMs: ms,
        maxWidth: 60,
        quality: 50,
        exact: true,
      );
      if (data != null && mounted) {
        if (_thumbnailCache.length >= 50) {
          _thumbnailCache.remove(_thumbnailCache.keys.first);
        }
        _thumbnailCache[key] = data;
        setState(() {
          if (isStart) {
            _startHandleThumb = data;
          } else {
            _endHandleThumb = data;
          }
        });
      }
    } catch (_) {}
  }

  /// Returns the closest pre-generated thumbnail for a normalized position.
  /// Used as an instant fallback while exact keyframes load asynchronously.
  Uint8List? _closestThumbnail(double position) {
    if (widget.thumbnails.isEmpty) return null;
    final idx = (position * widget.thumbnails.length).floor().clamp(
      0,
      widget.thumbnails.length - 1,
    );
    return widget.thumbnails[idx];
  }

  /// Fetches a thumbnail for the currently dragged handle position.
  /// Uses `_thumbnailCache` for O(1) cache hits and a timestamp guard
  /// capped at ~48ms (≈20fps) to avoid Timer allocation churn.
  void _requestThumbnail(double normalizedPosition) {
    if (widget.videoDurationMs <= 0) return;
    final ms = (normalizedPosition * widget.videoDurationMs).round();
    final key = (ms / 50).round(); // 50ms buckets

    // Synchronous cache hit — update immediately, no throttle.
    if (_thumbnailCache.containsKey(key)) {
      if (mounted) {
        setState(() {
          _previewThumbnail = _thumbnailCache[key];
          _previewPosition = normalizedPosition;
          if (_activeHandle == 'start') {
            _startHandleThumb = _thumbnailCache[key];
          }
          if (_activeHandle == 'end') {
            _endHandleThumb = _thumbnailCache[key];
          }
        });
      }
      return;
    }

    // Timestamp guard: skip async fetch if we requested one <48ms ago.
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastThumbRequestMs < 48) return;
    _lastThumbRequestMs = now;

    _fetchThumbnailAsync(normalizedPosition, ms, key);
  }

  Future<void> _fetchThumbnailAsync(
    double normalizedPosition,
    int ms,
    int key,
  ) async {
    try {
      final data = await _videoService.loadFrameThumbnailData(
        videoPath: widget.videoPath,
        timeMs: ms,
        maxWidth: 100,
        quality: 50,
        bucketMs: 50,
      );
      if (data != null) {
        if (_thumbnailCache.length >= 50) {
          _thumbnailCache.remove(_thumbnailCache.keys.first);
        }
        _thumbnailCache[key] = data;
        if (mounted) {
          setState(() {
            _previewThumbnail = data;
            _previewPosition = normalizedPosition;
            if (_activeHandle == 'start') _startHandleThumb = data;
            if (_activeHandle == 'end') _endHandleThumb = data;
          });
        }
      }
    } catch (_) {}
  }

  void _clearDragState() {
    // Fire a final seek to land on the exact frame the user released at.
    // The throttle may have skipped the last drag update's position.
    if ((_activeHandle == 'start' || _activeHandle == 'end') &&
        _dragValue != null) {
      widget.onPlayheadChanged?.call(_dragValue!);
    }
    setState(() {
      _activeHandle = null;
      _dragValue = null;
      _dragRawValue = null;
      _dragOrigin = null;
      _dragVerticalLiftPx = 0.0;
      _previewThumbnail = null;
      _previewPosition = null;
      _playheadPosition = widget.playbackPosition.value
          .clamp(widget.trimStart, widget.trimEnd)
          .toDouble();
    });
    widget.onDragEnd?.call();
  }

  // ── Unified gesture handlers ──
  // A single gesture layer covers the whole 56px timeline strip.
  // On drag start we pick the closest target (start handle, end handle,
  // or playhead) within _kGrabRadiusPx. This eliminates the overlap
  // bug where two separate GestureDetectors could steal each other's
  // drag when handles were close together.

  void _handleUnifiedDragStart(
    DragStartDetails details, {
    required double timelineWidth,
    required double displayedTrimStart,
    required double displayedTrimEnd,
  }) {
    // Convert global touch X to local timeline X.
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localX = box.globalToLocal(details.globalPosition).dx;

    // Compute pixel center of each target.
    final startCenterPx = displayedTrimStart * timelineWidth;
    final endCenterPx = displayedTrimEnd * timelineWidth;
    final playheadPx = _effectivePlayheadPosition * timelineWidth;

    final dStart = (localX - startCenterPx).abs();
    final dEnd = (localX - endCenterPx).abs();
    final dPlayhead = (localX - playheadPx).abs();

    // Find closest target within grab radius.
    String? target;
    double best = _kGrabRadiusPx;

    if (dStart < best) {
      best = dStart;
      target = 'start';
    }
    if (dEnd < best) {
      best = dEnd;
      target = 'end';
    }
    // Tie-break: if both handles are equidistant (or within 2px),
    // prefer the one closer to its respective edge. This prevents
    // the "stuck in the middle" feel.
    if (target != null && (dStart - dEnd).abs() < 2.0) {
      target = startCenterPx <= (timelineWidth - endCenterPx) ? 'start' : 'end';
    }
    // Playhead only wins if it's closer than both handles.
    if (dPlayhead < best) {
      target = 'playhead';
    }

    if (target == null) return; // touch too far from any target

    if (target == 'start') {
      widget.onDragStart?.call();
      _lastSeekMs = 0;
      _lastHapticMs = 0;
      setState(() {
        _activeHandle = 'start';
        _dragValue = widget.trimStart;
        _dragRawValue = widget.trimStart;
        _dragOrigin = details.globalPosition;
        _dragVerticalLiftPx = 0.0;
        _playheadPosition = widget.trimStart;
      });
      HapticFeedback.selectionClick();
      widget.onPlayheadChanged?.call(widget.trimStart);
      _requestThumbnail(widget.trimStart);
    } else if (target == 'end') {
      widget.onDragStart?.call();
      _lastSeekMs = 0;
      _lastHapticMs = 0;
      setState(() {
        _activeHandle = 'end';
        _dragValue = widget.trimEnd;
        _dragRawValue = widget.trimEnd;
        _dragOrigin = details.globalPosition;
        _dragVerticalLiftPx = 0.0;
        _playheadPosition = widget.trimEnd;
      });
      HapticFeedback.selectionClick();
      widget.onPlayheadChanged?.call(widget.trimEnd);
      _requestThumbnail(widget.trimEnd);
    } else {
      // playhead
      setState(() {
        _activeHandle = 'playhead';
        _dragValue = _effectivePlayheadPosition;
        _playheadPosition = _effectivePlayheadPosition;
      });
      _requestThumbnail(_effectivePlayheadPosition);
    }
  }

  void _handleUnifiedDragUpdate(
    DragUpdateDetails d, {
    required double timelineWidth,
    required double displayedTrimStart,
    required double displayedTrimEnd,
  }) {
    if (_activeHandle == null) return;

    if (_activeHandle == 'start') {
      final origin = _dragOrigin;
      final lift = origin == null ? 0.0 : (origin.dy - d.globalPosition.dy);
      _dragVerticalLiftPx = lift > 0 ? lift : 0.0;

      _dragRawValue = applyRawDrag(
        currentRaw: _dragRawValue ?? widget.trimStart,
        deltaDx: d.delta.dx,
        timelineWidth: timelineWidth,
        verticalLiftPx: _dragVerticalLiftPx,
        minValue: 0.0,
        maxValue: displayedTrimEnd - _minTrimGapNormalized,
      );

      // Snap with 1ms quantum — sub-frame precision for smooth movement
      final newStart = snapNormalizedToDuration(
        _dragRawValue!,
        widget.videoDurationMs,
        quantumMs: 1,
      ).clamp(0.0, displayedTrimEnd - _minTrimGapNormalized).toDouble();

      final now = DateTime.now().millisecondsSinceEpoch;
      if (newStart != _dragValue && now - _lastHapticMs >= _kHapticThrottleMs) {
        _lastHapticMs = now;
        HapticFeedback.selectionClick();
      }

      _dragValue = newStart;
      widget.onChanged(newStart, widget.trimEnd);
      setState(() => _playheadPosition = newStart);

      if (now - _lastSeekMs >= _kSeekThrottleMs) {
        _lastSeekMs = now;
        widget.onPlayheadChanged?.call(newStart);
      }
      _requestThumbnail(newStart);
    } else if (_activeHandle == 'end') {
      final origin = _dragOrigin;
      final lift = origin == null ? 0.0 : (origin.dy - d.globalPosition.dy);
      _dragVerticalLiftPx = lift > 0 ? lift : 0.0;

      _dragRawValue = applyRawDrag(
        currentRaw: _dragRawValue ?? widget.trimEnd,
        deltaDx: d.delta.dx,
        timelineWidth: timelineWidth,
        verticalLiftPx: _dragVerticalLiftPx,
        minValue: displayedTrimStart + _minTrimGapNormalized,
        maxValue: 1.0,
      );

      // Snap with 1ms quantum — sub-frame precision for smooth movement
      final newEnd = snapNormalizedToDuration(
        _dragRawValue!,
        widget.videoDurationMs,
        quantumMs: 1,
      ).clamp(displayedTrimStart + _minTrimGapNormalized, 1.0).toDouble();

      final now = DateTime.now().millisecondsSinceEpoch;
      if (newEnd != _dragValue && now - _lastHapticMs >= _kHapticThrottleMs) {
        _lastHapticMs = now;
        HapticFeedback.selectionClick();
      }

      _dragValue = newEnd;
      widget.onChanged(widget.trimStart, newEnd);
      setState(() => _playheadPosition = newEnd);

      if (now - _lastSeekMs >= _kSeekThrottleMs) {
        _lastSeekMs = now;
        widget.onPlayheadChanged?.call(newEnd);
      }
      _requestThumbnail(newEnd);
    } else if (_activeHandle == 'playhead') {
      final newPos = applyTrimHandleDrag(
        currentValue: _dragValue ?? _playheadPosition,
        deltaDx: d.delta.dx,
        timelineWidth: timelineWidth,
        verticalLiftPx: 0,
        minValue: displayedTrimStart,
        maxValue: displayedTrimEnd,
        durationMs: widget.videoDurationMs,
      );
      _dragValue = newPos;
      setState(() => _playheadPosition = newPos);
      widget.onPlayheadChanged?.call(newPos);
      _requestThumbnail(newPos);
    }
  }

  /// Build the two visual-only trim handles in z-order: the *active*
  /// handle renders last (on top) with a subtle scale + shadow lift,
  /// giving the "3D layer" feel that the grabbed handle sits above.
  List<Widget> _buildOrderedHandles({
    required ColorScheme colorScheme,
    required double timelineWidth,
    required double displayedTrimStart,
    required double displayedTrimEnd,
  }) {
    Widget startHandle({bool elevated = false}) {
      // Both handles use left: positioning for consistent coordinate space.
      final leftPx =
          displayedTrimStart * timelineWidth - _kHandleVisualWidth / 2;
      Widget handle = Positioned(
        left: leftPx,
        top: 0,
        bottom: 0,
        child: IgnorePointer(
          child: Semantics(
            label: 'Trim start handle',
            child: SizedBox(
              width: _kHandleVisualWidth,
              child: _HandleWithKeyframe(
                thumbnail:
                    _startHandleThumb ?? _closestThumbnail(displayedTrimStart),
                color: colorScheme.primary,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.xs),
                ),
              ),
            ),
          ),
        ),
      );
      if (elevated) {
        handle = Positioned(
          left: leftPx,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Transform.scale(
              scale: 1.08,
              child: Container(
                width: _kHandleVisualWidth,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _HandleWithKeyframe(
                  thumbnail:
                      _startHandleThumb ??
                      _closestThumbnail(displayedTrimStart),
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.xs),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return handle;
    }

    Widget endHandle({bool elevated = false}) {
      // End handle uses left: positioning (same coordinate space as start).
      final leftPx = displayedTrimEnd * timelineWidth - _kHandleVisualWidth / 2;
      Widget handle = Positioned(
        left: leftPx,
        top: 0,
        bottom: 0,
        child: IgnorePointer(
          child: Semantics(
            label: 'Trim end handle',
            child: SizedBox(
              width: _kHandleVisualWidth,
              child: _HandleWithKeyframe(
                thumbnail:
                    _endHandleThumb ?? _closestThumbnail(displayedTrimEnd),
                color: colorScheme.primary,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(AppRadius.xs),
                ),
              ),
            ),
          ),
        ),
      );
      if (elevated) {
        handle = Positioned(
          left: leftPx,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Transform.scale(
              scale: 1.08,
              child: Container(
                width: _kHandleVisualWidth,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _HandleWithKeyframe(
                  thumbnail:
                      _endHandleThumb ?? _closestThumbnail(displayedTrimEnd),
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(AppRadius.xs),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return handle;
    }

    // Active handle renders last (on top) in the Stack.
    if (_activeHandle == 'start') {
      return [endHandle(), startHandle(elevated: true)];
    } else if (_activeHandle == 'end') {
      return [startHandle(), endHandle(elevated: true)];
    }
    // Default: start first, end second (no elevation).
    return [startHandle(), endHandle()];
  }

  @override
  void didUpdateWidget(_TrimTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeHandle == 'start') {
      _dragRawValue = (_dragRawValue ?? widget.trimStart)
          .clamp(0.0, widget.trimEnd - _minTrimGapNormalized)
          .toDouble();
      _dragValue = (_dragValue ?? widget.trimStart)
          .clamp(0.0, widget.trimEnd - _minTrimGapNormalized)
          .toDouble();
    } else if (_activeHandle == 'end') {
      _dragRawValue = (_dragRawValue ?? widget.trimEnd)
          .clamp(widget.trimStart + _minTrimGapNormalized, 1.0)
          .toDouble();
      _dragValue = (_dragValue ?? widget.trimEnd)
          .clamp(widget.trimStart + _minTrimGapNormalized, 1.0)
          .toDouble();
    } else if (_activeHandle == 'playhead') {
      _dragValue = (_dragValue ?? _playheadPosition)
          .clamp(widget.trimStart, widget.trimEnd)
          .toDouble();
    }

    if (_activeHandle == null) {
      _playheadPosition = widget.playbackPosition.value
          .clamp(widget.trimStart, widget.trimEnd)
          .toDouble();
    } else {
      _playheadPosition = _playheadPosition
          .clamp(widget.trimStart, widget.trimEnd)
          .toDouble();
    }
    // Reload handle keyframes when trim positions change externally
    if (oldWidget.trimStart != widget.trimStart && _activeHandle != 'start') {
      _fetchHandleThumb(widget.trimStart, isStart: true);
    }
    if (oldWidget.trimEnd != widget.trimEnd && _activeHandle != 'end') {
      _fetchHandleThumb(widget.trimEnd, isStart: false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timelineWidth =
        MediaQuery.of(context).size.width - AppSpacing.screenEdge * 2;
    final displayedTrimStart = _displayedTrimStart;
    final displayedTrimEnd = _displayedTrimEnd;
    final isFineScrubbing =
        (_activeHandle == 'start' || _activeHandle == 'end') &&
        _dragVerticalLiftPx >= _kFineScrubIndicatorLiftPx;

    // Timecode values — O(1) arithmetic from existing state
    final startTime = _formatTimeAtPosition(displayedTrimStart);
    final endTime = _formatTimeAtPosition(displayedTrimEnd);

    return SizedBox(
      height: 84, // timecode (20) + gap (8) + strip (56)
      child: Stack(
        clipBehavior: Clip.none, // allow floating preview above
        children: [
          Column(
            children: [
              // ── Timecode row (always visible, above strip) ──
              SizedBox(
                height: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Trim start time — accent when dragging start handle
                    Text(
                      startTime,
                      style: AppTypography.caption.copyWith(
                        color: _activeHandle == 'start'
                            ? colorScheme.primary
                            : Colors.white54,
                        fontSize: 11,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    // Current playhead time — updates per frame via
                    // ListenableBuilder without rebuilding the full timeline.
                    ListenableBuilder(
                      listenable: Listenable.merge([
                        widget.playbackPosition,
                        widget.isPlaying,
                      ]),
                      builder: (context, _) {
                        return Text(
                          _formatTimeAtPosition(_effectivePlayheadPosition),
                          style: AppTypography.caption.copyWith(
                            color: _activeHandle == 'playhead'
                                ? colorScheme.primary
                                : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        );
                      },
                    ),
                    // Trim end time — accent when dragging end handle
                    Text(
                      endTime,
                      style: AppTypography.caption.copyWith(
                        color: _activeHandle == 'end'
                            ? colorScheme.primary
                            : Colors.white54,
                        fontSize: 11,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // ── Timeline strip (56px) ──
              SizedBox(
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Stack(
                    children: [
                      // Static thumbnail strip — wrapped in RepaintBoundary
                      // so the 8 Image.memory tiles never repaint during
                      // playback or drag. Active tile highlight is overlaid
                      // separately via ListenableBuilder.
                      RepaintBoundary(
                        child: Row(
                          children: List.generate(8, (i) {
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: AppColors.darkFill,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child:
                                    (i < widget.thumbnails.length &&
                                        widget.thumbnails[i] != null)
                                    ? Opacity(
                                        opacity: 0.6,
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
                      ),

                      // Left dim overlay (before trim start)
                      if (displayedTrimStart > 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: displayedTrimStart * timelineWidth,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                            ).copyWith(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(AppRadius.xs),
                              ),
                            ),
                          ),
                        ),
                      // Right dim overlay (after trim end)
                      if (displayedTrimEnd < 1)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: (1 - displayedTrimEnd) * timelineWidth,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                            ).copyWith(
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(AppRadius.xs),
                              ),
                            ),
                          ),
                        ),

                      // ── Visual-only handles ──
                      // Rendered as IgnorePointer so they don't intercept
                      // touches. The unified gesture layer below determines
                      // which handle (or playhead) a drag belongs to based
                      // on proximity, eliminating the overlap bug where
                      // Flutter's Stack hit testing would give the gesture
                      // to whichever widget was painted last.

                      // Start handle — rendered first (below) when end is active,
                      // or second (on top) when start is active, for z-elevation.
                      ..._buildOrderedHandles(
                        colorScheme: colorScheme,
                        timelineWidth: timelineWidth,
                        displayedTrimStart: displayedTrimStart,
                        displayedTrimEnd: displayedTrimEnd,
                      ),

                      // Dynamic layer: playhead + active tile highlight.
                      // Only this ListenableBuilder rebuilds per frame —
                      // everything above (thumbnails, handles, overlays)
                      // is static during playback.
                      ListenableBuilder(
                        listenable: Listenable.merge([
                          widget.playbackPosition,
                          widget.isPlaying,
                        ]),
                        builder: (context, _) {
                          final playhead = _effectivePlayheadPosition;
                          final activeIndex = (playhead * 8).floor().clamp(
                            0,
                            7,
                          );
                          final tileWidth = timelineWidth / 8;
                          return SizedBox.expand(
                            child: Stack(
                              children: [
                                // Active tile highlight overlay
                                Positioned(
                                  left: activeIndex * tileWidth + 2,
                                  top: 2,
                                  width: tileWidth - 4,
                                  height: 52,
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        border: Border.all(
                                          color: colorScheme.primary,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                // Playhead (visual only — gesture handled below)
                                Positioned(
                                  left: playhead * timelineWidth - 1.5,
                                  top: 0,
                                  bottom: 0,
                                  child: IgnorePointer(
                                    child: Container(
                                      width: 3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // ── Unified gesture layer ──
                      // One GestureDetector covers the entire timeline strip.
                      // On drag start we measure pixel distance to each handle
                      // center and the playhead, then lock onto the closest
                      // target within _kGrabRadiusPx. This prevents the overlap
                      // bug entirely — no matter how close the handles get,
                      // the nearest one always wins.
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragStart: (details) {
                            _handleUnifiedDragStart(
                              details,
                              timelineWidth: timelineWidth,
                              displayedTrimStart: displayedTrimStart,
                              displayedTrimEnd: displayedTrimEnd,
                            );
                          },
                          onHorizontalDragUpdate: (d) {
                            _handleUnifiedDragUpdate(
                              d,
                              timelineWidth: timelineWidth,
                              displayedTrimStart: displayedTrimStart,
                              displayedTrimEnd: displayedTrimEnd,
                            );
                          },
                          onHorizontalDragEnd: (_) => _clearDragState(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ── Floating preview — only visible during handle drag ──
          if (_activeHandle != null &&
              _previewThumbnail != null &&
              _previewPosition != null)
            Positioned(
              left: (_previewPosition! * timelineWidth - 40).clamp(
                0.0,
                timelineWidth - 80,
              ),
              top: 0,
              child: Container(
                width: 80,
                height: 56,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.darkFill,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: colorScheme.primary, width: 2),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_previewThumbnail!, fit: BoxFit.cover),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        color: Colors.black54,
                        child: Text(
                          _formatTimeAtPosition(_previewPosition!),
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    if (isFineScrubbing)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Fine',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double get _displayedTrimStart {
    if (_activeHandle == 'start' && _dragValue != null) {
      return _dragValue!
          .clamp(0.0, widget.trimEnd - _minTrimGapNormalized)
          .toDouble();
    }
    return widget.trimStart;
  }

  double get _displayedTrimEnd {
    if (_activeHandle == 'end' && _dragValue != null) {
      return _dragValue!
          .clamp(widget.trimStart + _minTrimGapNormalized, 1.0)
          .toDouble();
    }
    return widget.trimEnd;
  }

  double get _minTrimGapNormalized {
    if (widget.videoDurationMs <= 0) return 0.02;
    return (250 / widget.videoDurationMs).clamp(0.01, 0.5).toDouble();
  }

  double get _effectivePlayheadPosition {
    if (_activeHandle != null) {
      return _playheadPosition.clamp(widget.trimStart, widget.trimEnd);
    }
    if (widget.isPlaying.value) {
      return widget.playbackPosition.value.clamp(
        widget.trimStart,
        widget.trimEnd,
      );
    }
    return _playheadPosition.clamp(widget.trimStart, widget.trimEnd);
  }

  String _formatTimeAtPosition(double normalizedPosition) {
    if (widget.videoDurationMs <= 0) return '--:--.--';
    final ms = (normalizedPosition * widget.videoDurationMs).round();
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$seconds.$millis';
  }
}

/// A trim handle that displays its keyframe thumbnail so the user can see
/// exactly which video frame the handle is positioned at. Falls back to the
/// accent color when no thumbnail is available.
class _HandleWithKeyframe extends StatelessWidget {
  const _HandleWithKeyframe({
    required this.thumbnail,
    required this.color,
    required this.borderRadius,
  });

  final Uint8List? thumbnail;
  final Color color;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Keyframe thumbnail background — slightly transparent so the
          // accent color tint shows through, keeping handles identifiable.
          if (thumbnail != null)
            Opacity(
              opacity: 0.65,
              child: Image.memory(thumbnail!, fit: BoxFit.cover),
            ),
          // Drag affordance icon
          const Center(
            child: Icon(Icons.drag_indicator, size: 12, color: Colors.white),
          ),
        ],
      ),
    );
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
    final primary = Theme.of(context).colorScheme.primary;
    final fill = active
        ? primary.withValues(alpha: 0.15)
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
            border: active ? Border.all(color: primary, width: 1.5) : null,
          ),
          child: Icon(
            icon,
            color: active ? primary : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
