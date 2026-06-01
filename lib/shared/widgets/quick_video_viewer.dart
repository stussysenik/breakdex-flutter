import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/navigation/app_route_observer.dart';
import '../../core/services/media_playback_coordinator.dart';
import '../../core/utils/diagnostics.dart';

class QuickVideoViewer extends ConsumerStatefulWidget {
  const QuickVideoViewer({super.key, required this.videoPath, this.title});

  final String videoPath;
  final String? title;

  @override
  ConsumerState<QuickVideoViewer> createState() => _QuickVideoViewerState();
}

class _QuickVideoViewerState extends ConsumerState<QuickVideoViewer>
    with RouteAware, WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _showControls = true;
  String? _errorMessage;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    DiagnosticsLog.info('QuickVideoViewer', '_init videoPath=${widget.videoPath}');
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..setLooping(true)
      ..initialize()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Video init timed out'),
          )
          .then((_) {
            if (mounted) {
              setState(() => _initialized = true);
              MediaPlaybackCoordinator.shared.claimPrimary('qv_${widget.videoPath}');
              _controller.play();
            }
          })
          .catchError((final e, final stack) {
            DiagnosticsLog.error('QuickVideoViewer', '_init failed: $e');
            if (mounted) {
              setState(() {
              _hasError = true;
              _errorMessage = '$e';
            });
            }
          });
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

  @override
  void dispose() {
    DiagnosticsLog.info('QuickVideoViewer', '_dispose');
    WidgetsBinding.instance.removeObserver(this);
    if (_route is ModalRoute<dynamic>) appRouteObserver.unsubscribe(this);
    MediaPlaybackCoordinator.shared.release('qv_${widget.videoPath}');
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    _controller.pause();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _controller.pause();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      setState(() => _showControls = true);
    } else {
      MediaPlaybackCoordinator.shared.claimPrimary('qv_${widget.videoPath}');
      _controller.play();
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasError)
            _buildError()
          else if (!_initialized)
            const Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
            )
          else
            GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: () => context.pop(),
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
          if (widget.title != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  widget.title!,
                  style: AppTypography.titleSmall.copyWith(color: Colors.white70),
                ),
              ),
            ),
          if (_initialized && !_hasError && _showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                    stops: [0.3, 1.0],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CtrlBtn(Icons.replay_5_rounded, () {
                      final pos = _controller.value.position;
                      _controller.seekTo(pos - const Duration(seconds: 5));
                    }),
                    _CtrlBtn(
                      _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      _togglePlay,
                      size: 48,
                    ),
                    _CtrlBtn(Icons.forward_5_rounded, () {
                      final pos = _controller.value.position;
                      final dur = _controller.value.duration;
                      var next = pos + const Duration(seconds: 5);
                      if (next > dur) next = dur;
                      _controller.seekTo(next);
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white38, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(_errorMessage ?? 'Failed to load video',
              style: AppTypography.bodySmall.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _CtrlBtn(this.icon, this.onTap, {this.size = 32});

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
