import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/services/video_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    this.height = 300,
    this.borderRadius,
    this.overlay,
  });

  final String videoPath;
  final double height;
  final BorderRadius? borderRadius;
  final Widget? overlay;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _controller.dispose();
      _initPlayer();
    }
  }

  void _initPlayer() {
    _initialized = false;
    _hasError = false;
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ??
        BorderRadius.circular(AppRadius.lg);

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
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : GestureDetector(
                    onTap: _togglePlay,
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
                        if (!_controller.value.isPlaying)
                          const Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              color: Colors.white70,
                              size: 64,
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
class RobustVideoPlayer extends StatefulWidget {
  const RobustVideoPlayer({
    super.key,
    required this.videoPath,
    this.height = 300,
    this.onRepick,
    this.onEdit,
    this.overlay,
  });

  final String videoPath;
  final double height;
  final VoidCallback? onRepick;
  final VoidCallback? onEdit;
  final Widget? overlay;

  @override
  State<RobustVideoPlayer> createState() => _RobustVideoPlayerState();
}

enum _PlayerState { checking, ready, missing, error }

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

  Future<void> _checkFile() async {
    setState(() => _state = _PlayerState.checking);
    final status = await _videoService.checkVideoFile(widget.videoPath);
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
      _PlayerState.ready => VideoPlayerWidget(
          videoPath: widget.videoPath,
          height: widget.height,
          overlay: widget.overlay,
        ).animate().fadeIn(duration: 300.ms),
      _PlayerState.missing => _buildStatusCard(
          icon: Icons.cloud_off,
          message: 'Video not found',
          actionLabel: widget.onRepick != null ? 'Re-pick Video' : null,
          onAction: widget.onRepick,
          colorScheme: colorScheme,
        ),
      _PlayerState.error => _buildStatusCard(
          icon: Icons.error_outline,
          message: 'Playback error',
          actionLabel: 'Retry',
          onAction: _checkFile,
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
  }) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colorScheme.secondary, size: 48),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
