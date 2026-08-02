// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

part of '../move_list_screen.dart';

class _MoveGridCell extends ConsumerWidget {
  const _MoveGridCell({required this.move, required this.date});

  final Move move;

  /// The move's effective date under the active sort, resolved by the sliver.
  final DateTime date;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final learningState = LearningState.fromString(move.learningState);
    final colorScheme = Theme.of(context).colorScheme;

    // Whether this move's bytes can actually be pulled back down (task 5.3).
    // The tile used to ask `contentHash != null`, which only says the asset is
    // tracked — a move that never finished uploading would still offer a
    // download. Unresolved reads as not-restorable: a momentary honest "gone"
    // beats a promise the app cannot keep.
    final hash = move.contentHash;
    final restorable =
        hash != null &&
        (ref.watch(restorableAssetHashesProvider).valueOrNull ?? const {})
            .contains(hash);

    return _GridCardShell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/moves/move/${move.id}');
      },
      heroTag: 'move-thumb-${move.id}',
      background: move.videoPath != null
          ? VideoThumbnailImage(videoPath: move.resolvedVideoPath!)
          : Container(
              color: colorScheme.surfaceContainerHighest,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIconView(
                    restorable ? AppIcon.download : AppIcon.videoOff,
                    size: 40,
                    color: restorable
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                        : colorScheme.secondary,
                  ),
                  if (!restorable) ...[
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
      // The tile sits on a video thumbnail, so both lines take the light
      // treatment the shell's imagery demands rather than the theme's.
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (move.category != 'default') ...[
            _CategoryLabel(
              category: move.category,
              overrideTextColor: Colors.white70,
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],
          LibraryDateLabel(date: date, color: Colors.white70),
        ],
      ),
      topRightWidget: StatePill(state: learningState),
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
        decoration: AppSurfaces.panel(context, radius: AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            background,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
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
                      const SizedBox(height: 4),
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
      // Morph, not a raw Hero: the cell and the detail screen are one card
      // changing size, so the flight is timed by AppMotion.morph.
      card = AppMorph(identifier: heroTag!, child: card);
    }

    return Pressable(onTap: onTap, scaleEnd: 0.96, child: card);
  }
}
