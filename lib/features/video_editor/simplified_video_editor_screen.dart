// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.  discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: avoid_slow_async_io, discarded_futures

import 'dart:async';
import 'package:breakdex/core/platform/io.dart';
import 'package:breakdex/core/platform/native_media.dart';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/navigation/app_route_observer.dart'
    show appRouteObserver;
import 'package:breakdex/core/services/media_playback_coordinator.dart';
import 'package:breakdex/core/services/native_video_export.dart';
import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/core/utils/loading_state_machine.dart';
import 'package:breakdex/core/utils/pid_controller.dart';
import 'package:breakdex/core/utils/diagnostics.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/features/video_editor/video_edit_geometry.dart';
import 'package:breakdex/core/design/icons.dart';

class SimplifiedVideoEditorView extends ConsumerStatefulWidget {
  const SimplifiedVideoEditorView({super.key, required this.videoPath});

  final String videoPath;

  @override
  ConsumerState<SimplifiedVideoEditorView> createState() =>
      _SimplifiedVideoEditorViewState();
}

class _SimplifiedVideoEditorViewState
    extends ConsumerState<SimplifiedVideoEditorView>
    with RouteAware, WidgetsBindingObserver {
  double _trimStart = 0.0;
  double _trimEnd = 1.0;

  final ValueNotifier<double> _playbackPosition = ValueNotifier(0.0);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);

  int _rotation = 0;
  int _selectedAspectIndex = 0;
  int _selectedSpeedIndex = 2;
  double? _customAspectRatio;
  static const int _customAspectIndex = 6;

  bool _matrixInitialized = false;
  Size? _previewViewportSize;
  VideoEditViewport? _previewViewport;

  final VideoService _videoService = VideoService();
  final _loadingController = LoadingStateController<void>();
  LoadingStateMachine<void> _loadState = const Idle();
  StreamSubscription<LoadingStateMachine<void>>? _loadSub;
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
    'Custom...',
  ];
  static const _aspectRatios = <double?>[
    null,
    null,
    9 / 16,
    16 / 9,
    1.0,
    4 / 5,
    null,
  ];

  double? get _effectiveTargetAspect {
    if (_selectedAspectIndex == _customAspectIndex) return _customAspectRatio;
    return _aspectRatios[_selectedAspectIndex];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MediaPlaybackCoordinator.shared.attach(
      playbackId: _playbackId,
      onPause: _pausePlayback,
    );
    _scaleStopwatch.start();
    _loadSub = _loadingController.stream.listen((final state) {
      if (mounted) setState(() => _loadState = state);
    });
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
  void didUpdateWidget(covariant final SimplifiedVideoEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _trimStart = 0.0;
      _trimEnd = 1.0;
      _playbackPosition.value = 0.0;
      _isPlaying.value = false;
      _matrixInitialized = false;
      _previewViewportSize = null;
      _previewViewport = null;
      unawaited(_loadVideo());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    MediaPlaybackCoordinator.shared.detach(_playbackId);
    _loadSub?.cancel();
    _loadingController.dispose();
    unawaited(_disposeController());
    _progressSub?.cancel();
    _exportHangTimer?.cancel();
    _playbackPosition.dispose();
    _isPlaying.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausePlayback();
    }
  }

  bool get _isEditorReady =>
      _loadState is Ready &&
      _controller != null &&
      _controller!.value.isInitialized;

  bool get _hasEdits =>
      _trimStart != 0.0 ||
      _trimEnd != 1.0 ||
      _rotation != 0 ||
      _selectedAspectIndex != 0;

  Future<void> _loadVideo({final bool isRetry = false}) async {
    final loadToken = ++_loadToken;
    await _disposeController();
    if (!mounted || loadToken != _loadToken) return;

    _playbackPosition.value = _trimStart.clamp(0.0, 1.0);
    _isPlaying.value = false;
    setState(() {
      _videoDuration = Duration.zero;
      _thumbnails = [];
      _matrixInitialized = false;
      _previewViewportSize = null;
      _previewViewport = null;
    });

    _loadingController.send(isRetry ? LoadingEvent.retry : LoadingEvent.start);

    final status = await _videoService.checkVideoFileWithRetry(
      widget.videoPath,
      maxRetries: 1,
    );
    if (!mounted || loadToken != _loadToken) return;

    if (status != VideoFileStatus.ready) {
      final error = switch (status) {
        VideoFileStatus.missing =>
          'The video is missing or still being downloaded.',
        VideoFileStatus.error => 'The video file could not be accessed safely.',
        VideoFileStatus.ready => null,
      };
      _loadingController.send(
        LoadingEvent.fail(
          error ?? 'Access failed',
          retryable: status == VideoFileStatus.error,
        ),
      );
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
      });
      _loadingController.send(LoadingEvent.complete(null));
      unawaited(_generateThumbnails());
    } on Object catch (error) {
      if (!mounted || loadToken != _loadToken) return;
      _loadingController.send(
        LoadingEvent.fail(
          error is TimeoutException
              ? 'The video took too long to initialize.'
              : 'Could not load the selected video.',
          retryable: true,
        ),
      );
    }
  }

  Future<VideoPlayerController> _initializeControllerWithRetry(
    final String path,
  ) async {
    final controller = fileVideoController(path);

    try {
      await controller.initialize().timeout(_kVideoInitTimeout);
      return controller;
    } on Object catch (_) {
      await controller.dispose();
      await Future<void>.delayed(_kVideoInitRetryDelay);
      final c2 = fileVideoController(path);
      await c2.initialize().timeout(_kVideoInitTimeout);
      return c2;
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_onVideoTick);
      await controller.dispose();
      if (mounted) setState(() => _controller = null);
    }
  }

  void _onVideoTick() {
    if (_controller == null || _isInternallySeeking || !mounted) return;

    final pos = _controller!.value.position;
    final duration = _controller!.value.duration;
    if (duration.inMilliseconds == 0) return;

    final normalized = pos.inMilliseconds / duration.inMilliseconds;
    _playbackPosition.value = normalized.clamp(0.0, 1.0);

    // End of trim range reached
    if (normalized >= _trimEnd - _kPlaybackTolerance) {
      _pausePlayback();
      unawaited(_controller!.seekTo(_normalizedPositionToDuration(_trimStart)));
    }
  }

  void _togglePlayPause() {
    if (!_isEditorReady) return;
    if (_isPlaying.value) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (!_isEditorReady || _isPlaying.value) return;
    MediaPlaybackCoordinator.shared.claimPrimary(_playbackId);

    if (_playbackPosition.value >= _trimEnd - _kPlaybackTolerance) {
      unawaited(
        _controller!
            .seekTo(_normalizedPositionToDuration(_trimStart))
            .then((_) => _controller!.play()),
      );
    } else {
      unawaited(_controller!.play());
    }
    _isPlaying.value = true;
  }

  void _pausePlayback() {
    if (!_isEditorReady || !_isPlaying.value) return;
    unawaited(_controller!.pause());
    _isPlaying.value = false;
  }

  Duration _normalizedPositionToDuration(
    final double normalized, {
    final Duration? duration,
  }) {
    final d = duration ?? _videoDuration;
    return Duration(milliseconds: (normalized * d.inMilliseconds).round());
  }

  Future<void> _generateThumbnails() async {
    if (_thumbnails.isNotEmpty) return;
    final results = await _videoService.loadTimelineThumbnails(
      videoPath: widget.videoPath,
      durationMs: _videoDuration.inMilliseconds,
      count: 8,
    );
    if (mounted) setState(() => _thumbnails = results);
  }

  void _onTrimChanged(final double start, final double end) {
    setState(() {
      _trimStart = start;
      _trimEnd = end;
    });
  }

  void _rotate() {
    setState(() {
      _rotation = (_rotation + 90) % 360;
      DiagnosticsLog.info(
        'VideoEditor',
        '[Simplified] Rotating to $_rotation°',
      );
      _matrixInitialized = false;
      _previewViewportSize = null;
    });
    unawaited(HapticFeedback.selectionClick());
  }

  void _setAspect(final int index) {
    if (index == _selectedAspectIndex && index != _customAspectIndex) return;
    DiagnosticsLog.info(
      'VideoEditor',
      '[Simplified] Setting aspect index $index',
    );
    if (index == _customAspectIndex) {
      _showCustomAspectDialog();
    } else {
      setState(() {
        _selectedAspectIndex = index;
        _matrixInitialized = false;
        _previewViewportSize = null;
      });
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _setSpeed(final int index) {
    if (index == _selectedSpeedIndex) return;
    final speed = _speeds[index];
    DiagnosticsLog.info(
      'VideoEditor',
      '[Simplified] Setting speed to ${speed}x',
    );
    setState(() => _selectedSpeedIndex = index);
    unawaited(_controller?.setPlaybackSpeed(speed));
    unawaited(HapticFeedback.selectionClick());
  }

  void _applyClampedPreviewTransform(final VideoEditViewport viewport) {
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();

    // Clamp scale
    final clampedScale = scale.clamp(viewport.minScale, viewport.maxScale);

    // Clamp translation to keep video bounds filled
    final translation = matrix.getTranslation();
    final clampedTx = translation.x.clamp(
      viewport.size.width - (viewport.orientedVideoSize.width * clampedScale),
      0.0,
    );
    final clampedTy = translation.y.clamp(
      viewport.size.height - (viewport.orientedVideoSize.height * clampedScale),
      0.0,
    );

    _transformController.value = Matrix4.diagonal3Values(
      clampedScale,
      clampedScale,
      1.0,
    )..setTranslationRaw(clampedTx, clampedTy, 0.0);
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppIconView(AppIcon.close, color: colorScheme.onSurface),
          onPressed: () => _handleDiscard(context),
        ),
        title: Text(
          'EDIT VIDEO',
          style: AppTypography.labelLarge.copyWith(
            color: colorScheme.onSurface,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (_isEditorReady && !_exporting)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _export,
                child: Text(
                  'SAVE',
                  style: AppTypography.labelLarge.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenEdge,
                    ),
                    child: _buildVideoPreview(colorScheme),
                  ),
                ),
              ),
              _buildBottomControls(colorScheme),
            ],
          ),
          if (_exporting) _buildExportOverlay(colorScheme),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(final ColorScheme colorScheme) {
    return _loadState.map(
      idle: (_) => const SizedBox.shrink(),
      loading: (_) => _buildPreviewStatusCard(
        colorScheme,
        icon: null,
        title: 'Loading video...',
        subtitle: 'Preparing the editor and syncing the first frame.',
        showSpinner: true,
      ),
      retrying: (final s) => _buildPreviewStatusCard(
        colorScheme,
        icon: null,
        title: 'Retrying video load...',
        subtitle: 'Attempt ${s.attempt} of ${s.maxAttempts}',
        showSpinner: true,
      ),
      downloading: (final s) => _buildPreviewStatusCard(
        colorScheme,
        icon: null,
        title: 'Downloading video...',
        subtitle: '${(s.progress * 100).toInt()}% complete',
        showSpinner: true,
      ),
      timeout: (_) => _buildPreviewStatusCard(
        colorScheme,
        icon: AppIcon.timer.resolve(context),
        title: 'Video load timed out',
        subtitle: 'Check your connection or try again.',
        actionLabel: 'Retry',
        onAction: () => unawaited(_loadVideo(isRetry: true)),
      ),
      error: (final s) => _buildPreviewStatusCard(
        colorScheme,
        icon: AppIcon.error.resolve(context),
        title: 'Video failed to load',
        subtitle: s.message,
        actionLabel: s.retryable ? 'Retry' : null,
        onAction: s.retryable
            ? () => unawaited(_loadVideo(isRetry: true))
            : null,
      ),
      ready: (_) {
        if (!_isEditorReady) {
          return _buildPreviewStatusCard(
            colorScheme,
            icon: AppIcon.schedule.resolve(context),
            title: 'Preparing editor...',
            subtitle: 'One more moment while the preview becomes available.',
          );
        }

        const playOverlay = Center(
          child: AppIconView(AppIcon.play, color: Colors.white70, size: 64),
        );

        final targetAspect = _effectiveTargetAspect;
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
          rawVideo = RotatedBox(quarterTurns: _rotation ~/ 90, child: rawVideo);
        }

        if (isCropMode) {
          return LayoutBuilder(
            builder: (final context, final constraints) {
              final viewport = computeVideoEditViewport(
                videoSize: videoSize,
                rotation: _rotation,
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
                targetAspect: targetAspect,
              );

              if (!_matrixInitialized ||
                  _previewViewportSize != constraints.biggest) {
                _previewViewport = viewport;
                _previewViewportSize = constraints.biggest;
                _transformController.value = viewport.initialTransform();
                _matrixInitialized = true;
                _gestureBaseScale = viewport.minScale;
              }

              final videoContent = SizedBox(
                width: viewport.orientedVideoSize.width,
                height: viewport.orientedVideoSize.height,
                child: rawVideo,
              );

              final viewportSize = viewport.size;

              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRect(
                      child: SizedBox(
                        width: viewportSize.width,
                        height: viewportSize.height,
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: viewport.minScale,
                          maxScale: viewport.maxScale,
                          constrained: false,
                          onInteractionStart: (_) {
                            _pausePlayback();
                            _gestureBaseScale = _transformController.value
                                .getMaxScaleOnAxis();
                            _pidController.reset();
                          },
                          onInteractionUpdate: (final details) {
                            final dt =
                                _scaleStopwatch.elapsedMilliseconds / 1000.0;
                            _scaleStopwatch.reset();
                            final currentScale = _transformController.value
                                .getMaxScaleOnAxis();

                            final rawTarget =
                                (_gestureBaseScale * details.scale).clamp(
                                  viewport.minScale,
                                  viewport.maxScale,
                                );

                            final target = rawTarget.clamp(
                              currentScale,
                              viewport.maxScale,
                            );
                            if ((target - currentScale).abs() < 0.008) return;

                            final delta = _pidController.update(
                              target,
                              currentScale,
                              dt > 0 ? dt : 0.016,
                            );

                            final clampedDelta = delta.clamp(-0.004, 0.06);
                            final newScale = (currentScale + clampedDelta)
                                .clamp(viewport.minScale, viewport.maxScale);

                            _transformController.value =
                                Matrix4.diagonal3Values(
                                  newScale,
                                  newScale,
                                  1.0,
                                );
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
                    if (!_isPlaying.value) playOverlay,
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildPreviewStatusCard(
    final ColorScheme colorScheme, {
    required final IconData? icon,
    required final String title,
    final String? subtitle,
    final String? actionLabel,
    final VoidCallback? onAction,
    final bool showSpinner = false,
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
              AppLoader(color: Theme.of(context).colorScheme.primary)
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

  Widget _buildBottomControls(final ColorScheme colorScheme) {
    return Container(
      color: AppColors.darkBg,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.md,
        AppSpacing.screenEdge,
        AppSpacing.xl + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TrimTimeline(
            trimStart: _trimStart,
            trimEnd: _trimEnd,
            thumbnails: _thumbnails,
            onChanged: _onTrimChanged,
            videoPath: widget.videoPath,
            videoDurationMs: _videoDuration.inMilliseconds,
            playbackPosition: _playbackPosition,
            isPlaying: _isPlaying,
            onPlayheadChanged: (final pos) {
              _isInternallySeeking = true;
              unawaited(
                _controller!
                    .seekTo(_normalizedPositionToDuration(pos))
                    .then((_) => _isInternallySeeking = false),
              );
            },
            onDragStart: _pausePlayback,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _TransformButton(
                icon: AppIcon.replay.resolve(context),
                onTap: _rotate,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PillSelector(
                  label: 'ASPECT',
                  items: _aspectLabels,
                  selectedIndex: _selectedAspectIndex,
                  onSelected: _setAspect,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PillSelector(
                  label: 'SPEED',
                  items: _speedLabels,
                  selectedIndex: _selectedSpeedIndex,
                  onSelected: _setSpeed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportOverlay(final ColorScheme colorScheme) {
    final progress = _exportProgress?.progress ?? 0.0;
    final phase = _exportProgress?.phase ?? 'Exporting...';
    final elapsed = _exportStartedAt != null
        ? DateTime.now().difference(_exportStartedAt!)
        : Duration.zero;

    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress : null,
                    strokeWidth: 6,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  phase.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTypography.titleLarge.copyWith(color: Colors.white),
                ),
                if (elapsed.inSeconds > 6) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Taking longer than usual. Pre-encoding high-resolution video can be slow.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDiscard(final BuildContext context) async {
    if (_hasEdits) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (final ctx) => AlertDialog(
          title: const Text('Discard edits?'),
          content: const Text('You have unsaved changes to this video.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Discard',
                style: TextStyle(color: AppColors.actionAgain),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    if (mounted) this.context.pop();
  }

  void _showCustomAspectDialog() {
    final wController = TextEditingController();
    final hController = TextEditingController();
    if (_customAspectRatio != null) {
      wController.text = '16';
      hController.text = (16.0 / _customAspectRatio!).round().toString();
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (final ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenEdge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Custom Aspect Ratio',
                  style: AppTypography.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter width and height to set a custom crop ratio.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: wController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Width',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        ':',
                        style: AppTypography.titleMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: hController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final w = double.tryParse(wController.text);
                      final h = double.tryParse(hController.text);
                      if (w != null && h != null && w > 0 && h > 0) {
                        Navigator.pop(ctx);
                        setState(() {
                          _customAspectRatio = w / h;
                          _selectedAspectIndex = _customAspectIndex;
                          _matrixInitialized = false;
                          _previewViewportSize = null;
                        });
                      }
                    },
                    child: const Text('Apply'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _export() async {
    if (!_isEditorReady) return;

    setState(() {
      _exporting = true;
      _exportProgress = null;
      _exportStartedAt = DateTime.now();
    });

    _pausePlayback();

    _progressSub = NativeVideoExport.progressStream.listen((final progress) {
      if (mounted) setState(() => _exportProgress = progress);
    });

    _exportHangTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _exporting) setState(() {});
    });

    String? tempPath;
    try {
      final tempDir = await getTemporaryDirectory();
      tempPath = p.join(tempDir.path, 'export_${const Uuid().v4()}.mp4');

      final trimStartMs = (_trimStart * _videoDuration.inMilliseconds).round();
      final trimEndMs = (_trimEnd * _videoDuration.inMilliseconds).round();
      final speed = _speeds[_selectedSpeedIndex];
      final normalizedRotation = ((_rotation % 360) + 360) % 360;
      final isCropMode =
          _effectiveTargetAspect != null ||
          _aspectLabels[_selectedAspectIndex] == 'Free Form';

      Rect? finalCrop;
      if (isCropMode) {
        final viewport = _previewViewport;
        if (viewport != null) {
          finalCrop = viewport.normalizedCropRect(_transformController.value);
        }
      }

      final resultPath = await NativeVideoExport.export(
        inputPath: widget.videoPath,
        outputPath: tempPath,
        trimStartMs: trimStartMs,
        trimEndMs: trimEndMs,
        speed: speed,
        rotation: normalizedRotation,
        aspectRatio: null,
        cropRect: finalCrop,
      ).timeout(const Duration(seconds: 120));

      unawaited(_progressSub?.cancel());
      _progressSub = null;

      unawaited(HapticFeedback.heavyImpact());
      if (mounted) context.pop(resultPath);
    } on Object catch (e) {
      if (tempPath != null) {
        final f = File(tempPath);
        if (await f.exists()) await f.delete();
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

class _PillSelector extends StatelessWidget {
  const _PillSelector({
    required this.label,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String label;
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: colorScheme.secondary,
            fontSize: 9,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 4),
            itemBuilder: (final ctx, final i) {
              final active = i == selectedIndex;
              return Center(
                child: GestureDetector(
                  onTap: () => onSelected(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: active ? colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      items[i],
                      style: AppTypography.caption.copyWith(
                        color: active
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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
  });

  final double trimStart;
  final double trimEnd;
  final List<Uint8List?> thumbnails;
  final void Function(double start, double end) onChanged;
  final String videoPath;
  final int videoDurationMs;
  final ValueListenable<double> playbackPosition;
  final ValueListenable<bool> isPlaying;
  final ValueChanged<double>? onPlayheadChanged;
  final VoidCallback? onDragStart;

  @override
  State<_TrimTimeline> createState() => _TrimTimelineState();
}

class _TrimTimelineState extends State<_TrimTimeline> {
  static const _kGrabRadiusPx = 30.0;
  static const _kSeekThrottleMs = 80;

  String? _activeHandle;
  double _playheadPosition = 0.0;
  double? _dragRawValue;
  int _lastSeekMs = 0;

  @override
  void initState() {
    super.initState();
    _playheadPosition = widget.playbackPosition.value;
  }

  void _handleDragStart(final DragStartDetails details) {
    final box = context.findRenderObject()! as RenderBox;
    final localX = box.globalToLocal(details.globalPosition).dx;
    final width = box.size.width;

    final startPx = widget.trimStart * width;
    final endPx = widget.trimEnd * width;
    final playheadPx = _playheadPosition * width;

    final dStart = (localX - startPx).abs();
    final dEnd = (localX - endPx).abs();
    final dPlayhead = (localX - playheadPx).abs();

    String? target;
    if (dStart < _kGrabRadiusPx && dStart <= dEnd && dStart <= dPlayhead) {
      target = 'start';
    } else if (dEnd < _kGrabRadiusPx && dEnd <= dStart && dEnd <= dPlayhead) {
      target = 'end';
    } else if (dPlayhead < _kGrabRadiusPx) {
      target = 'playhead';
    }

    if (target != null) {
      widget.onDragStart?.call();
      setState(() {
        _activeHandle = target;
        final dragVal = target == 'start'
            ? widget.trimStart
            : (target == 'end' ? widget.trimEnd : _playheadPosition);
        _dragRawValue = dragVal;
      });
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _handleDragUpdate(final DragUpdateDetails details) {
    if (_activeHandle == null) return;
    final box = context.findRenderObject()! as RenderBox;
    final width = box.size.width;
    final delta = details.delta.dx / width;

    final newVal = (_dragRawValue! + delta).clamp(0.0, 1.0);
    _dragRawValue = newVal;

    double actualVal = newVal;
    if (_activeHandle == 'start') {
      final clamped = newVal.clamp(0.0, widget.trimEnd - 0.05);
      actualVal = clamped;
      widget.onChanged(clamped, widget.trimEnd);
      setState(() => _playheadPosition = clamped);
    } else if (_activeHandle == 'end') {
      final clamped = newVal.clamp(widget.trimStart + 0.05, 1.0);
      actualVal = clamped;
      widget.onChanged(widget.trimStart, clamped);
      setState(() => _playheadPosition = clamped);
    } else {
      setState(() => _playheadPosition = newVal);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSeekMs > _kSeekThrottleMs) {
      _lastSeekMs = now;
      widget.onPlayheadChanged?.call(actualVal);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: (_) {
        setState(() => _activeHandle = null);
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Stack(
          children: [
            Row(
              children: List.generate(8, (final i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.darkFill,
                      borderRadius: BorderRadius.circular(AppRadius.xxs),
                    ),
                    child:
                        (i < widget.thumbnails.length &&
                            widget.thumbnails[i] != null)
                        ? Opacity(
                            opacity: 0.6,
                            child: Image.memory(
                              widget.thumbnails[i]!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
            Positioned(
              left: widget.trimStart * MediaQuery.of(context).size.width,
              top: 0,
              bottom: 0,
              width:
                  (widget.trimEnd - widget.trimStart) *
                  MediaQuery.of(context).size.width,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: widget.playbackPosition,
              builder: (final ctx, final pos, _) {
                return Positioned(
                  left:
                      pos *
                      (MediaQuery.of(context).size.width -
                          AppSpacing.screenEdge * 2),
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: Colors.white),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TransformButton extends StatelessWidget {
  const _TransformButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
