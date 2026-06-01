part of '../move_list_screen.dart';

class _MoveGridCell extends ConsumerWidget {
  const _MoveGridCell({required this.move});

  final Move move;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final learningState = LearningState.fromString(move.learningState);
    final colorScheme = Theme.of(context).colorScheme;

    return _GridCardShell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/moves/move/${move.id}');
      },
      heroTag: 'move-thumb-${move.id}',
      background: move.videoPath != null
          ? _GridThumbnail(videoPath: move.resolvedVideoPath!)
          : Container(
              color: colorScheme.surfaceContainerHighest,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    move.contentHash != null
                        ? Icons.cloud_download_outlined
                        : Icons.videocam_off,
                    size: 40,
                    color: move.contentHash != null
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : colorScheme.secondary,
                  ),
                  if (move.contentHash == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Missing',
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.secondary.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
      name: move.name,
      subtitle: move.category != 'default'
          ? _CategoryLabel(
              category: move.category,
              overrideTextColor: Colors.white70,
            )
          : null,
      topRightWidget: StatePill(state: learningState),
    );
  }
}

class _GridThumbnail extends StatefulWidget {
  const _GridThumbnail({required this.videoPath});
  final String videoPath;

  @override
  State<_GridThumbnail> createState() => _GridThumbnailState();
}

class _GridThumbnailState extends State<_GridThumbnail> {
  final _videoService = VideoService();
  String? _thumbPath;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant final _GridThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      // Cancel previous pending load if coordinator is available
      ThumbnailCoordinatorScope.of(context)?.cancel(oldWidget.videoPath);
      _thumbPath = null;
      _loaded = false;
      _load();
    }
  }

  @override
  void dispose() {
    ThumbnailCoordinatorScope.of(context)?.cancel(widget.videoPath);
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
    final coordinator = ThumbnailCoordinatorScope.of(context);
    final String? path;
    if (coordinator != null) {
      path = await coordinator.enqueue(
        videoPath,
        maxWidth: VideoService.thumbnailWidthGrid,
      );
    } else {
      path = await _videoService.generateThumbnail(
        videoPath,
        maxWidth: VideoService.thumbnailWidthGrid,
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
      return Image.file(
        File(_thumbPath!),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.videocam_off,
            size: 40,
            color: colorScheme.secondary,
          ),
        ),
      );
    }
    if (_loaded) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.videocam_off, size: 40, color: colorScheme.secondary),
      );
    }
    // Shimmer placeholder while thumbnail loads — smoother than a spinner
    // and consistent with the RobustVideoPlayer loading state.
    return Container(
      color: colorScheme.surfaceContainerHighest,
    ).animate(onPlay: (final c) => c.repeat()).shimmer(
      duration: 1200.ms,
      color: Colors.white12,
    );
  }
}

class _GridCardShell extends StatelessWidget {
  const _GridCardShell({
    required this.onTap,
    required this.background,
    required this.name,
    required this.topRightWidget,
    this.subtitle,
    this.heroTag,
  });

  final VoidCallback onTap;
  final Widget background;
  final String name;
  final Widget topRightWidget;
  final Widget? subtitle;

  /// Optional Hero tag for shared-element transitions (grid → detail).
  final String? heroTag;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticTheme = AppSemanticTheme.of(context);

    Widget card = RepaintBoundary(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: AppSurfaces.panel(
          context,
          radius: AppRadius.md,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            background,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                decoration: BoxDecoration(
                  color:
                      (semanticTheme.isMonoOutline
                              ? colorScheme.onSurface
                              : Colors.black)
                          .withValues(alpha: 0.74),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      subtitle!,
                    ],
                  ],
                ),
              ),
            ),
            Positioned(top: 8, right: 8, child: topRightWidget),
          ],
        ),
      ),
    );

    if (heroTag != null) {
      card = Hero(tag: heroTag!, child: card);
    }

    return Pressable(
      onTap: onTap,
      scaleEnd: 0.96,
      child: card,
    );
  }
}
