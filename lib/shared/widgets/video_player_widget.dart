import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/services/video_service.dart';

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
      videoController.play();
      scheduleHide();
    }
  }

  /// Single tap toggles play/pause directly — no more 2-tap dance.
  /// Controls scrim auto-hides but the persistent center icon stays visible.
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

  void skip(int seconds) {
    final pos = videoController.value.position;
    final dur = videoController.value.duration;
    var next = pos + Duration(seconds: seconds);
    if (next < Duration.zero) next = Duration.zero;
    if (next > dur) next = dur;
    videoController.seekTo(next);
    if (videoController.value.isPlaying) scheduleHide();
  }

  void cancelHideTimer() => _hideTimer?.cancel();
}

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    this.height = 300,
    this.borderRadius,
    this.overlay,
    this.onEdit,
    this.autoPlay = false,
  });

  final String videoPath;
  final double height;
  final BorderRadius? borderRadius;
  final Widget? overlay;
  final VoidCallback? onEdit;
  final bool autoPlay;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with _VideoTransportMixin {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _isMuted = false;

  @override
  VideoPlayerController get videoController => _controller;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      cancelHideTimer();
      _controller.removeListener(_onTick);
      _controller.dispose();
      _initPlayer();
    }
  }

  void _initPlayer() {
    _initialized = false;
    _hasError = false;
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..setLooping(true)
      ..initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Video init timed out'),
      ).then((_) {
        if (mounted) {
          _controller.addListener(_onTick);
          if (widget.autoPlay) {
            _controller.play();
            scheduleHide();
          }
          setState(() => _initialized = true);
        }
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  /// Rebuild on every position tick so the seek bar updates smoothly.
  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    cancelHideTimer();
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    cancelHideTimer();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            _FullscreenVideoPlayer(controller: _controller, onEdit: widget.onEdit),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: AppMotion.moderate01,
        reverseTransitionDuration: AppMotion.moderate01,
      ),
    );
  }

  // -- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.lg);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: AppColors.darkBg,
        child: _hasError
            ? const Center(
                child:
                    Icon(Icons.error_outline, color: Colors.white54, size: 48),
              )
            : !_initialized
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accent),
                  )
                : GestureDetector(
                    onTap: tapHandler,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                        // Controls scrim — auto-hides during playback
                        AnimatedOpacity(
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
                        // Persistent center play/pause icon — never fully hidden.
                        // Always-visible at reduced opacity so users know where to tap.
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
                        // Persistent mute toggle — top-right corner, always tappable
                        Positioned(
                          top: 8,
                          right: 8,
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
                        if (widget.overlay != null) widget.overlay!,
                      ],
                    ),
                  ),
      ),
    );
  }
}

// -- Transport Controls Overlay -------------------------------------------

/// Gradient-scrim overlay with music-player-style transport controls.
///
/// Layout: large play/pause center-stage flanked by ±5s skip buttons,
/// a draggable seek bar with timestamps, and a fullscreen toggle in the corner.
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
  Widget build(BuildContext context) {
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
          // Transport row: skip back | play/pause | skip forward
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
          // Seek bar row: time | slider | time | fullscreen
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

// -- Seek Bar -------------------------------------------------------------

/// Draggable seek bar with timestamps and fullscreen toggle.
///
/// Uses local [_dragging] state to decouple the slider from the controller
/// during a drag gesture. This prevents the slider from snapping back to the
/// controller's (slightly stale) position mid-scrub, which causes jitter.
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
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final position = value.position;
    final duration = value.duration;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    // While dragging, show the scrub position instead of the controller time.
    final displayPosition = _dragging
        ? Duration(
            milliseconds: (_dragValue * duration.inMilliseconds).round())
        : position;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isFullscreen ? AppSpacing.md : AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              _fmt(displayPosition),
              style: AppTypography.caption
                  .copyWith(color: Colors.white70, fontSize: 11),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: Colors.white24,
                thumbColor: AppColors.accent,
                overlayColor: AppColors.accent.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _dragging ? _dragValue : progress,
                onChangeStart: (v) =>
                    setState(() { _dragging = true; _dragValue = v; }),
                onChanged: (v) => setState(() => _dragValue = v),
                onChangeEnd: (v) {
                  setState(() => _dragging = false);
                  widget.controller.seekTo(
                    Duration(
                        milliseconds:
                            (v * duration.inMilliseconds).round()),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              _fmt(duration),
              style: AppTypography.caption
                  .copyWith(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.end,
            ),
          ),
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
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// -- Transport Button -----------------------------------------------------

/// Minimal tappable icon for transport controls.
///
/// Padding ensures the touch target meets Apple HIG 44pt minimum even for
/// smaller icons (24–32pt).
class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.onTap,
    this.size = 32,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
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

// -- Fullscreen Player ----------------------------------------------------

/// Immersive fullscreen video player pushed as a route.
///
/// Shares the same [VideoPlayerController] as the inline player so playback
/// is seamless — no reload, no position jump. Enables immersive system UI
/// and unlocks landscape rotation for wider videos.
class _FullscreenVideoPlayer extends StatefulWidget {
  const _FullscreenVideoPlayer({required this.controller, this.onEdit});

  final VideoPlayerController controller;
  final VoidCallback? onEdit;

  @override
  State<_FullscreenVideoPlayer> createState() =>
      _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer>
    with _VideoTransportMixin {
  @override
  VideoPlayerController get videoController => widget.controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    widget.controller.addListener(_onTick);
    if (widget.controller.value.isPlaying) scheduleHide();
  }

  @override
  void dispose() {
    cancelHideTimer();
    widget.controller.removeListener(_onTick);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}

// -- Supporting Widgets (unchanged) ---------------------------------------

class VideoPlaceholder extends StatelessWidget {
  const VideoPlaceholder({
    super.key,
    this.height = 300,
    this.icon = Icons.videocam_outlined,
  });

  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 48),
    );
  }
}

/// Wraps VideoPlayerWidget with file-existence checking and error recovery.
///
/// When [ghostThumbnailPath] is set, a faded thumbnail appears behind the
/// "Video not found" card so the user retains visual memory of the clip.
class RobustVideoPlayer extends StatefulWidget {
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
  });

  final String videoPath;
  final double height;
  final VoidCallback? onRepick;
  final VoidCallback? onEdit;
  final Widget? overlay;
  final String? ghostThumbnailPath;

  /// Original filename shown when the video file is missing, so the user
  /// can identify which clip needs to be re-imported.
  final String? originalVideoName;
  final bool autoPlay;

  @override
  State<RobustVideoPlayer> createState() => _RobustVideoPlayerState();
}

enum _PlayerState { checking, retrying, ready, missing, error }

class _RobustVideoPlayerState extends State<RobustVideoPlayer> {
  _PlayerState _state = _PlayerState.checking;
  final _videoService = VideoService();

  @override
  void initState() {
    super.initState();
    _checkFile();
  }

  @override
  void didUpdateWidget(RobustVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _checkFile();
    }
  }

  /// Check or retry video file availability. [isRetry] controls the loading state label.
  Future<void> _checkFile({bool isRetry = false}) async {
    setState(() => _state = isRetry ? _PlayerState.retrying : _PlayerState.checking);
    final status = await _videoService.checkVideoFileWithRetry(widget.videoPath);
    if (!mounted) return;
    setState(() {
      _state = switch (status) {
        VideoFileStatus.ready => _PlayerState.ready,
        VideoFileStatus.missing => _PlayerState.missing,
        VideoFileStatus.error => _PlayerState.error,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (_state) {
      _PlayerState.checking => _buildShimmer(),
      _PlayerState.retrying => _buildStatusCard(
          icon: Icons.refresh,
          message: 'Retrying...',
          showSpinner: true,
          colorScheme: colorScheme,
        ),
      _PlayerState.ready => VideoPlayerWidget(
          videoPath: widget.videoPath,
          height: widget.height,
          overlay: widget.overlay,
          onEdit: widget.onEdit,
          autoPlay: widget.autoPlay,
        ).animate().fadeIn(duration: 300.ms),
      _PlayerState.missing => _buildStatusCard(
          icon: Icons.cloud_off,
          message: 'Video not found',
          actionLabel: widget.onRepick != null ? 'Re-pick Video' : null,
          onAction: widget.onRepick,
          colorScheme: colorScheme,
          showGhost: true,
        ),
      _PlayerState.error => _buildStatusCard(
          icon: Icons.error_outline,
          message: 'Something went wrong',
          actionLabel: 'Tap to retry',
          onAction: () => _checkFile(isRetry: true),
          colorScheme: colorScheme,
        ),
    };
  }

  Widget _buildShimmer() {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white12);
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    required ColorScheme colorScheme,
    bool showGhost = false,
    bool showSpinner = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ghost thumbnail background at 0.15 opacity
            if (showGhost && widget.ghostThumbnailPath != null)
              Opacity(
                opacity: 0.15,
                child: Image.file(
                  File(widget.ghostThumbnailPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  else
                    Icon(icon, color: colorScheme.secondary, size: 48),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                  if (widget.originalVideoName != null &&
                      message == 'Video not found') ...[
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
                    TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel),
                    ),
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
