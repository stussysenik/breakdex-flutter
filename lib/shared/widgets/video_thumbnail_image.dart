// H.8 lint triage — discarded_futures: intentional fire-and-forget (the load
// is a UI side effect); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/platform/native_media.dart';
import 'package:breakdex/core/services/thumbnail_load_coordinator.dart';
import 'package:breakdex/core/services/video_service.dart';

/// One video's first frame, decoded through the shared
/// [ThumbnailLoadCoordinator] so a screenful of these does not stampede the
/// codec.
///
/// Promoted out of the move grid's private `_GridThumbnail` when the preview
/// strip needed the same loader: the coordinator hand-off, the file-status
/// retry, and the missing/loading states are one behaviour, and a second copy
/// of them would drift from this one on the first fix.
///
/// [maxWidth] is the decode width, not the layout width — a 28pt strip thumb
/// asks for [VideoService.thumbnailWidthGrid] only if the caller says so.
class VideoThumbnailImage extends StatefulWidget {
  const VideoThumbnailImage({
    super.key,
    required this.videoPath,
    this.maxWidth = VideoService.thumbnailWidthGrid,
    this.missingIconSize = 40,
  });

  final String videoPath;
  final int maxWidth;
  final double missingIconSize;

  @override
  State<VideoThumbnailImage> createState() => _VideoThumbnailImageState();
}

class _VideoThumbnailImageState extends State<VideoThumbnailImage> {
  final _videoService = VideoService();
  String? _thumbPath;
  bool _loaded = false;

  /// Held rather than looked up on demand: `dispose()` must cancel a pending
  /// decode, and an inherited-widget lookup there is illegal — the element is
  /// already deactivated. The private grid loader this was promoted from had
  /// the same bug; it only ever went unnoticed because nothing tore a
  /// thumbnail down under a test's watch.
  ThumbnailLoadCoordinator? _coordinator;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coordinator = ThumbnailCoordinatorScope.of(context);
  }

  @override
  void didUpdateWidget(covariant final VideoThumbnailImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      // Cancel previous pending load if coordinator is available
      _coordinator?.cancel(oldWidget.videoPath);
      _thumbPath = null;
      _loaded = false;
      _load();
    }
  }

  @override
  void dispose() {
    _coordinator?.cancel(widget.videoPath);
    super.dispose();
  }

  Future<void> _load() async {
    final videoPath = widget.videoPath;
    if (videoPath.isEmpty) {
      if (mounted) {
        setState(() {
          _thumbPath = null;
          _loaded = true;
        });
      }
      return;
    }

    final status = await _videoService.checkVideoFileWithRetry(videoPath);
    if (!mounted || widget.videoPath != videoPath) return;
    if (status != VideoFileStatus.ready) {
      setState(() {
        _thumbPath = null;
        _loaded = true;
      });
      return;
    }

    // Use coordinator for bounded concurrency if available, else direct
    final coordinator = _coordinator;
    final String? path;
    if (coordinator != null) {
      path = await coordinator.enqueue(videoPath, maxWidth: widget.maxWidth);
    } else {
      path = await _videoService.generateThumbnail(
        videoPath,
        maxWidth: widget.maxWidth,
      );
    }
    if (!mounted || widget.videoPath != videoPath) return;
    setState(() {
      _thumbPath = path;
      _loaded = true;
    });
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_loaded && _thumbPath != null) {
      return fileImage(
        _thumbPath!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _missing(colorScheme),
      );
    }
    if (_loaded) {
      return _missing(colorScheme);
    }
    // Shimmer placeholder while thumbnail loads — smoother than a spinner
    // and consistent with the RobustVideoPlayer loading state.
    return Container(color: colorScheme.surfaceContainerHighest)
        .animate(onPlay: (final c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white12);
  }

  Widget _missing(final ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceContainerHighest,
    child: AppIconView(
      AppIcon.videoOff,
      size: widget.missingIconSize,
      color: colorScheme.secondary,
    ),
  );
}
