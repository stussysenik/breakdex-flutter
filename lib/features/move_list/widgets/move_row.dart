part of '../move_list_screen.dart';

class _MoveRow extends ConsumerWidget {
  const _MoveRow({required this.move});

  final Move move;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = LearningState.fromString(move.learningState);
    final stateLabels = ref.watch(learningStateLabelsProvider);
    final stateLabel = resolveLearningStateLabel(stateLabels, state);
    final stateColor = AppSemanticTheme.of(context).colorForState(state);
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey(move.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.screenEdge),
          color: AppColors.actionAgain,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) {
          unawaited(HapticFeedback.heavyImpact());
          unawaited(_deleteMove(ref));
        },
        confirmDismiss: (_) async => true,
        child: Semantics(
          identifier: 'move-row-${move.id}',
          label: '${move.name}, $stateLabel',
          button: true,
          child: InkWell(
            onTap: () => context.go('/moves/move/${move.id}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: stateColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.sm),
                          bottomLeft: Radius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    move.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (move.videoPath == null &&
                                    move.contentHash == null) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.videocam_off,
                                    size: 14,
                                    color: colorScheme.secondary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ] else if (move.videoPath == null &&
                                    move.contentHash != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.cloud_download_outlined,
                                    size: 14,
                                    color: AppColors.accent.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (move.category != 'default')
                                  _CategoryLabel(category: move.category),
                                StatePill(state: state),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMove(WidgetRef ref) async {
    final orchestrator = ref.read(storageOrchestratorProvider);
    await orchestrator.deleteMove(
      move,
      cleanupMedia: (m) => ref.read(mediaCleanupServiceProvider).cleanupMoveMedia(m),
    );
  }
}

/// Small color dot + category name shown inline on each move row/grid cell.
/// Replaces the old filter-chip approach — category is always visible without
/// needing to toggle a filter.
class _CategoryLabel extends ConsumerWidget {
  const _CategoryLabel({required this.category, this.overrideTextColor});

  final String category;
  final Color? overrideTextColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final match = categories.where((c) => c.name == category).firstOrNull;
    final dotColor = match?.color ?? Theme.of(context).colorScheme.secondary;
    final textColor =
        overrideTextColor ?? Theme.of(context).colorScheme.secondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(color: textColor, fontSize: 10),
        ),
      ],
    );
  }
}

/// Renders small dots representing the number of moves in a combo.
/// Caps at [_ComboRow._maxDots] and shows a "+N" overflow label.
class _MoveCountDots extends StatelessWidget {
  const _MoveCountDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dotsToShow = count.clamp(0, _ComboRow._maxDots);
    final overflow = count - dotsToShow;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < dotsToShow; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ).animate().scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: AppMotion.fast02,
            delay: Duration(milliseconds: i * 20),
            curve: AppMotion.expressive,
          ),
        ],
        if (overflow > 0) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '+$overflow',
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}
