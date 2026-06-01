import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/navigation/app_route_observer.dart';
import '../../core/services/media_playback_coordinator.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/video_path_resolver.dart';
import '../../core/services/video_service.dart';
import '../../core/utils/loading_state_machine.dart';

/// Skip amount for forward/backward navigation.
/// 5 seconds suits short breakdancing clips (typically 5–30s).
const _kSkipSeconds = 5;

/// How long transport controls stay visible before auto-hiding during playback.
const _kControlsHideDelay = Duration(seconds: 3);

/// Shared transport-control logic for both inline and fullscreen video players.
/// Subclasses must provide [videoController] and call [cancelHideTimer] on dispose.
mixin _VideoTransportMixin<T extends StatefulWidget> on State<T> {
  VideoPlayerController get videoController;
  bool _showControls = true;
  Timer? _hideTimer;

  void togglePlay() {
    if (videoController.value.isPlaying) {
      videoController.pause();
      setState(() => _showControls = true);
      _hideTimer?.cancel();
    } else {
      unawaited(videoController.play());
      setState(() {}); // Rebuild to show pause icon immediately
      scheduleHide();
    }
  }

  /// Single tap toggles play/pause directly.
  void tapHandler() {
    togglePlay();
  }

  void scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_kControlsHideDelay, () {
      if (mounted && videoController.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void skip(final int seconds) {
    final pos = videoController.value.position;
    final dur = videoController.value.duration;
    var next = pos + Duration(seconds: seconds);
    if (next < Duration.zero) next = Duration.zero;
    if (next > dur) next = dur;
    unawaited(videoController.seekTo(next));
    if (videoController.value.isPlaying) scheduleHide();
  }

  void cancelHideTimer() => _hideTimer?.cancel();
}

class VideoPlayerWidget extends ConsumerStatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    this.height = 300,
    this.borderRadius,
    this.overlay,
    this.onEdit,
    this.autoPlay = false,
    this.minimal = false,
    this.looping = true,
    this.muted = false,
    this.playbackSpeed = 1.0,
    this.onPlayStateChanged,
  });

  final String videoPath;
  final double height;
  final BorderRadius? borderRadius;
  final Widget? overlay;
  final VoidCallback? onEdit;
  final bool autoPlay;
  final bool minimal;
  final bool looping;
  final bool muted;
  final double playbackSpeed;
  final ValueChanged<bool>? onPlayStateChanged;

  @override
  ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget>
    with _VideoTransportMixin, RouteAware, WidgetsBindingObserver {
  final _videoService = VideoService();
  final String _playbackId = UniqueKey().toString();
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _isMuted = false;
  String? _posterPath;
  ModalRoute<dynamic>? _route;
  bool _tickerModeEnabled = true;
  bool _suppressNextRoutePause = false;

  @override
  VideoPlayerController get videoController => _controller;

  @override
  void togglePlay() {
    if (_controller.value.isPlaying) {
      _pausePlayback();
      return;
    }
    MediaPlaybackCoordinator.shared.claimPrimary(_playbackId);
    super.togglePlay();
    widget.onPlayStateChanged?.call(true);
  }

  @override
  void initState() {
    super.initState();
    _isMuted = widget.muted || ref.read(quietModeEnabledProvider);
    WidgetsBinding.instance.addObserver(this);
    MediaPlaybackCoordinator.shared.attach(
      playbackId: _playbackId,
      onPause: _pausePlayback,
    );
    _initPlayer();
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

    final tickerModeEnabled = TickerMode.valuesOf(context).enabled;
    if (_tickerModeEnabled != tickerModeEnabled) {
      _tickerModeEnabled = tickerModeEnabled;
      if (!tickerModeEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _pausePlayback();
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant final VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      cancelHideTimer();
      MediaPlaybackCoordinator.shared.release(_playbackId);
      _controller.dispose();
      _isMuted = widget.muted || ref.read(quietModeEnabledProvider);
      _initPlayer();
      return;
    }

    if (_initialized) {
      if (oldWidget.looping != widget.looping) {
        unawaited(_controller.setLooping(widget.looping));
      }
      if (oldWidget.muted != widget.muted) {
        final effectiveMute = widget.muted || ref.read(quietModeEnabledProvider);
        unawaited(_controller.setVolume(effectiveMute ? 0.0 : 1.0));
        _isMuted = effectiveMute;
      }
      if (oldWidget.playbackSpeed != widget.playbackSpeed) {
        unawaited(_controller.setPlaybackSpeed(widget.playbackSpeed));
      }
    }
  }

  void _initPlayer({
    final Duration? resumePosition,
    final bool resumePlaying = false,
    final bool allowAutoPlay = true,
  }) {
    _initialized = false;
    _hasError = false;
    _posterPath = null;
    unawaited(_loadPoster());

    final quietMode = ref.read(quietModeEnabledProvider);

    _controller = VideoPlayerController.file(
      File(widget.videoPath),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: quietMode),
    )
      ..setLooping(widget.looping)
      ..initialize()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Video init timed out'),
          )
          .then((_) async {
            if (mounted) {
              final effectiveMute = widget.muted || quietMode;
              if (effectiveMute) await _controller.setVolume(0.0);
              if (widget.playbackSpeed != 1.0) {
                await _controller.setPlaybackSpeed(widget.playbackSpeed);
              }
              if (resumePosition != null) {
                final duration = _controller.value.duration;
                await _controller.seekTo(
                  resumePosition > duration ? duration : resumePosition,
                );
              }
              if ((resumePlaying || (allowAutoPlay && widget.autoPlay)) &&
                  _tickerModeEnabled) {
                MediaPlaybackCoordinator.shared.claimPrimary(_playbackId);
                await _controller.play();
                widget.onPlayStateChanged?.call(true);
                scheduleHide();
              }
              setState(() => _initialized = true);
            }
          })
          .catchError((_) {
            if (mounted) setState(() => _hasError = true);
          });
  }

  Future<void> _loadPoster() async {
    final poster = await _videoService.generateThumbnail(widget.videoPath);
    if (!mounted || poster == null) return;
    setState(() => _posterPath = poster);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      unawaited(_controller.setVolume(_isMuted ? 0 : 1));
    });
  }

  void _pausePlayback() {
    cancelHideTimer();
    MediaPlaybackCoordinator.shared.release(_playbackId);
    if (_controller.value.isPlaying) {
      unawaited(_controller.pause());
      widget.onPlayStateChanged?.call(false);
    }
    if (mounted) setState(() => _showControls = true);
  }

  @override
  void dispose() {
    cancelHideTimer();
    WidgetsBinding.instance.removeObserver(this);
    if (_route is ModalRoute<dynamic>) appRouteObserver.unsubscribe(this);
    MediaPlaybackCoordinator.shared.detach(_playbackId);
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    cancelHideTimer();
    _suppressNextRoutePause = true;
    MediaPlaybackCoordinator.shared.suppressNextNavigationPause();
    Navigator.of(context, rootNavigator: true)
        .push(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => _FullscreenVideoPlayer(
              controller: _controller,
              playbackId: _playbackId,
              onEdit: widget.onEdit,
            ),
            transitionsBuilder: (_, final anim, _, final child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: AppMotion.moderate01,
            reverseTransitionDuration: AppMotion.moderate01,
          ),
        )
        .whenComplete(() => _suppressNextRoutePause = false);
  }

  @override
  void didPushNext() {
    if (_suppressNextRoutePause) return;
    _pausePlayback();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _pausePlayback();
  }

  @override
  Widget build(final BuildContext context) {
    ref.listen(quietModeEnabledProvider, (final previous, final next) {
      if (previous != next && mounted) {
        final pos = _initialized ? _controller.value.position : null;
        final playing = _initialized && _controller.value.isPlaying;
        cancelHideTimer();
        MediaPlaybackCoordinator.shared.release(_playbackId);
        _controller.dispose();
        _isMuted = widget.muted || next;
        _initPlayer(
          resumePosition: pos,
          resumePlaying: playing,
          allowAutoPlay: false,
        );
      }
    });

    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: AppColors.darkBg,
        child: _hasError
            ? const Center(
                child: Icon(Icons.error_outline, color: Colors.white54, size: 48),
              )
            : !_initialized
            ? Stack(
                fit: StackFit.expand,
                children: [
                  if (_posterPath != null)
                    Image.file(File(_posterPath!), fit: BoxFit.cover),
                  Container(color: Colors.black26),
                  Center(
                    child: widget.minimal
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : CircularProgressIndicator(color: colorScheme.primary),
                  ),
                ],
              )
            : GestureDetector(
                onTap: tapHandler,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                    if (!widget.minimal) ...[
                      RepaintBoundary(
                        child: AnimatedOpacity(
                          opacity: _showControls ? 1.0 : 0.0,
                          duration: AppMotion.moderate01,
                          child: IgnorePointer(
                            ignoring: !_showControls,
                            child: _VideoControls(
                              controller: _controller,
                              onTogglePlay: togglePlay,
                              onSkipBack: () => skip(-_kSkipSeconds),
                              onSkipForward: () => skip(_kSkipSeconds),
                              onFullscreen: _openFullscreen,
                              onEdit: widget.onEdit,
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: _showControls ? 0.0 : 0.4,
                            duration: AppMotion.moderate01,
                            child: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              color: Colors.white,
                              size: 56,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Semantics(
                          label: _isMuted ? 'Unmute' : 'Mute',
                          button: true,
                          child: GestureDetector(
                            onTap: _toggleMute,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: AnimatedOpacity(
                                opacity: _showControls ? 0.9 : 0.5,
                                duration: AppMotion.moderate01,
                                child: Icon(
                                  _isMuted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (widget.minimal) ...[
                      IgnorePointer(
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: _controller.value.isPlaying ? 0.0 : 0.6,
                            duration: AppMotion.moderate01,
                            child: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              color: Colors.white,
                              size: 72,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (widget.overlay != null) widget.overlay!,
                  ],
                ),
              ),
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  const _VideoControls({
    required this.controller,
    required this.onTogglePlay,
    required this.onSkipBack,
    required this.onSkipForward,
    this.onFullscreen,
    this.onExitFullscreen,
    this.onEdit,
    this.isFullscreen = false,
  });

  final VideoPlayerController controller;
  final VoidCallback onTogglePlay;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;
  final VoidCallback? onFullscreen;
  final VoidCallback? onExitFullscreen;
  final VoidCallback? onEdit;
  final bool isFullscreen;

  @override
  Widget build(final BuildContext context) {
    final isPlaying = controller.value.isPlaying;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
          stops: [0.3, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TransportButton(
                icon: Icons.replay_5_rounded,
                onTap: onSkipBack,
                size: isFullscreen ? 40 : 32,
              ),
              const SizedBox(width: AppSpacing.lg),
              _TransportButton(
                icon: isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                onTap: onTogglePlay,
                size: isFullscreen ? 56 : 48,
              ),
              const SizedBox(width: AppSpacing.lg),
              _TransportButton(
                icon: Icons.forward_5_rounded,
                onTap: onSkipForward,
                size: isFullscreen ? 40 : 32,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _SeekBar(
            controller: controller,
            isFullscreen: isFullscreen,
            onFullscreen: onFullscreen,
            onExitFullscreen: onExitFullscreen,
            onEdit: onEdit,
          ),
          SizedBox(height: isFullscreen ? AppSpacing.lg : AppSpacing.sm),
        ],
      ),
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({
    required this.controller,
    required this.isFullscreen,
    this.onFullscreen,
    this.onExitFullscreen,
    this.onEdit,
  });

  final VideoPlayerController controller;
  final bool isFullscreen;
  final VoidCallback? onFullscreen;
  final VoidCallback? onExitFullscreen;
  final VoidCallback? onEdit;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  bool _dragging = false;
  double _dragValue = 0;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final actionButtons = [
      if (widget.onEdit != null) ...[
        const SizedBox(width: 4),
        _TransportButton(
          icon: Icons.tune_rounded,
          onTap: widget.onEdit!,
          size: 24,
        ),
      ],
      const SizedBox(width: 4),
      _TransportButton(
        icon: widget.isFullscreen
            ? Icons.fullscreen_exit_rounded
            : Icons.fullscreen_rounded,
        onTap: widget.isFullscreen
            ? (widget.onExitFullscreen ?? () {})
            : (widget.onFullscreen ?? () {}),
        size: 24,
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isFullscreen ? AppSpacing.md : AppSpacing.sm,
      ),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: widget.controller,
        builder: (final context, final value, _) {
          final duration = value.duration;
          final position = value.position;
          final progress = duration.inMilliseconds > 0
              ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
              : 0.0;
          final displayPosition = _dragging
              ? Duration(milliseconds: (_dragValue * duration.inMilliseconds).round())
              : position;

          return Row(
            children: [
              SizedBox(
                width: 38,
                child: Text(
                  _fmt(displayPosition),
                  style: AppTypography.caption.copyWith(color: Colors.white70, fontSize: 11),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: colorScheme.primary,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: colorScheme.primary,
                    overlayColor: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _dragging ? _dragValue : progress,
                    onChangeStart: (final v) => setState(() {
                      _dragging = true;
                      _dragValue = v;
                    }),
                    onChanged: (final v) => setState(() => _dragValue = v),
                    onChangeEnd: (final v) {
                      setState(() => _dragging = false);
                      unawaited(widget.controller.seekTo(
                        Duration(milliseconds: (v * duration.inMilliseconds).round()),
                      ));
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  _fmt(duration),
                  style: AppTypography.caption.copyWith(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.end,
                ),
              ),
              ...actionButtons,
            ],
          );
        },
      ),
    );
  }

  static String _fmt(final Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({required this.icon, required this.onTap, this.size = 32});
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

class _FullscreenVideoPlayer extends StatefulWidget {
  const _FullscreenVideoPlayer({
    required this.controller,
    required this.playbackId,
    this.onEdit,
  });
  final VideoPlayerController controller;
  final String playbackId;
  final VoidCallback? onEdit;

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer>
    with _VideoTransportMixin, RouteAware, WidgetsBindingObserver {
  ModalRoute<dynamic>? _route;

  @override
  VideoPlayerController get videoController => widget.controller;

  @override
  void togglePlay() {
    if (widget.controller.value.isPlaying) {
      _pauseFullscreenPlayback();
      return;
    }
    MediaPlaybackCoordinator.shared.claimPrimary(widget.playbackId);
    super.togglePlay();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));
    if (widget.controller.value.isPlaying) scheduleHide();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextRoute = ModalRoute.of(context);
    if (_route != nextRoute) {
      if (_route is ModalRoute<dynamic>) appRouteObserver.unsubscribe(this);
      _route = nextRoute;
      if (nextRoute is ModalRoute<dynamic>) appRouteObserver.subscribe(this, nextRoute);
    }
  }

  void _pauseFullscreenPlayback() {
    cancelHideTimer();
    MediaPlaybackCoordinator.shared.release(widget.playbackId);
    if (widget.controller.value.isPlaying) unawaited(widget.controller.pause());
    if (mounted) setState(() => _showControls = true);
  }

  @override
  void dispose() {
    cancelHideTimer();
    WidgetsBinding.instance.removeObserver(this);
    if (_route is ModalRoute<dynamic>) appRouteObserver.unsubscribe(this);
    if (!widget.controller.value.isPlaying) MediaPlaybackCoordinator.shared.release(widget.playbackId);
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]));
    super.dispose();
  }

  @override
  void didPushNext() => _pauseFullscreenPlayback();

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _pauseFullscreenPlayback();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: tapHandler,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: AppMotion.moderate01,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: _VideoControls(
                  controller: widget.controller,
                  onTogglePlay: togglePlay,
                  onSkipBack: () => skip(-_kSkipSeconds),
                  onSkipForward: () => skip(_kSkipSeconds),
                  isFullscreen: true,
                  onExitFullscreen: () => Navigator.of(context).pop(),
                  onEdit: widget.onEdit,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: SafeArea(
                top: false,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlaceholder extends StatelessWidget {
  const VideoPlaceholder({super.key, this.height = 300, this.icon = Icons.videocam_outlined});
  final double height;
  final IconData icon;

  @override
  Widget build(final BuildContext context) {
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 48),
    );
  }
}

class RobustVideoPlayer extends ConsumerStatefulWidget {
  const RobustVideoPlayer({
    super.key,
    required this.videoPath,
    this.height = 300,
    this.onRepick,
    this.onEdit,
    this.overlay,
    this.ghostThumbnailPath,
    this.originalVideoName,
    this.autoPlay = false,
    this.borderRadius,
    this.minimal = false,
    this.looping = true,
    this.muted = false,
    this.playbackSpeed = 1.0,
    this.onPlayStateChanged,
  });

  final String videoPath;
  final double height;
  final VoidCallback? onRepick;
  final VoidCallback? onEdit;
  final Widget? overlay;
  final String? ghostThumbnailPath;
  final String? originalVideoName;
  final bool autoPlay;
  final BorderRadius? borderRadius;
  final bool minimal;
  final bool looping;
  final bool muted;
  final double playbackSpeed;
  final ValueChanged<bool>? onPlayStateChanged;

  @override
  ConsumerState<RobustVideoPlayer> createState() => _RobustVideoPlayerState();
}

class _RobustVideoPlayerState extends ConsumerState<RobustVideoPlayer> {
  final _loadingController = LoadingStateController<void>();
  LoadingStateMachine<void> _loadingState = const Idle();
  StreamSubscription<LoadingStateMachine<void>>? _stateSub;
  final _videoService = VideoService();
  String? _resolvedPath;

  @override
  void initState() {
    super.initState();
    _stateSub = _loadingController.stream.listen((final state) {
      if (mounted) setState(() => _loadingState = state);
    });
    _checkFile();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(final RobustVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) _checkFile();
  }

  Future<void> _checkFile({final bool isRetry = false}) async {
    _loadingController.send(isRetry ? LoadingEvent.retry : LoadingEvent.start);
    _resolvedPath = null;
    final status = await _videoService.checkVideoFileWithRetry(widget.videoPath);
    if (!mounted) return;
    if (status == VideoFileStatus.missing) {
      final found = await VideoPathResolver.resolve(widget.videoPath);
      if (!mounted) return;
      if (found != null) {
        _resolvedPath = found;
        _loadingController.send(LoadingEvent.complete(null));
        return;
      }
    }
    switch (status) {
      case VideoFileStatus.ready:
        _loadingController.send(LoadingEvent.complete(null));
      case VideoFileStatus.missing:
        _loadingController.send(LoadingEvent.fail('Video not found', retryable: false));
      case VideoFileStatus.error:
        _loadingController.send(LoadingEvent.fail('Something went wrong', retryable: true));
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final quietMode = ref.watch(quietModeEnabledProvider);

    return _loadingState.map(
      idle: (_) => const SizedBox.shrink(),
      loading: (_) => _buildShimmer(),
      downloading: (_) => _buildShimmer(),
      ready: (_) => VideoPlayerWidget(
        videoPath: _resolvedPath ?? widget.videoPath,
        height: widget.height,
        borderRadius: widget.borderRadius,
        overlay: widget.overlay,
        onEdit: widget.onEdit,
        autoPlay: widget.autoPlay,
        minimal: widget.minimal,
        looping: widget.looping,
        muted: widget.muted || quietMode,
        playbackSpeed: widget.playbackSpeed,
        onPlayStateChanged: widget.onPlayStateChanged,
      ).animate().fadeIn(duration: 300.ms),
      timeout: (final t) => _buildStatusCard(
        icon: Icons.cloud_off,
        message: 'Connection timed out',
        actionLabel: 'Tap to retry',
        onAction: () => _checkFile(isRetry: true),
        colorScheme: colorScheme,
      ),
      error: (final e) => e.message == 'Video not found'
          ? _buildStatusCard(
              icon: Icons.cloud_off,
              message: 'Video not found',
              actionLabel: widget.onRepick != null ? 'Re-pick Video' : null,
              onAction: widget.onRepick,
              colorScheme: colorScheme,
              showGhost: true,
            )
          : _buildStatusCard(
              icon: Icons.error_outline,
              message: e.message,
              actionLabel: e.retryable ? 'Tap to retry' : null,
              onAction: e.retryable ? () => _checkFile(isRetry: true) : null,
              colorScheme: colorScheme,
            ),
      retrying: (_) => _buildStatusCard(
        icon: Icons.refresh,
        message: 'Retrying...',
        showSpinner: true,
        colorScheme: colorScheme,
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(AppRadius.lg),
          ),
        )
        .animate(onPlay: (final c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white12);
  }

  Widget _buildStatusCard({
    required final IconData icon,
    required final String message,
    final String? actionLabel,
    final VoidCallback? onAction,
    required final ColorScheme colorScheme,
    final bool showGhost = false,
    final bool showSpinner = false,
  }) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showGhost && widget.ghostThumbnailPath != null)
              Opacity(
                opacity: 0.15,
                child: Image.file(
                  File(widget.ghostThumbnailPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: showGhost && widget.ghostThumbnailPath != null
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.85)
                    : colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showSpinner)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  else
                    Icon(icon, color: colorScheme.secondary, size: 48),
                  const SizedBox(height: AppSpacing.sm),
                  Text(message, style: AppTypography.bodyMedium.copyWith(color: colorScheme.secondary)),
                  if (widget.originalVideoName != null && message == 'Video not found') ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text(
                        widget.originalVideoName!,
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.secondary.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextButton(onPressed: onAction, child: Text(actionLabel)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
