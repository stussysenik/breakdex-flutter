// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

part of '../move_list_screen.dart';

/// Grid layout for combos — mirrors `_MoveGrid` but uses a styled placeholder
/// instead of a video thumbnail (combos don't have their own video).
class _ComboGridSliver extends StatelessWidget {
  const _ComboGridSliver({required this.combos});

  final List<(Combo, int)> combos;

  @override
  Widget build(final BuildContext context) {
    return _sliverArsenalGrid(
      itemCount: combos.length,
      builder: (final index) {
        final (combo, moveCount) = combos[index];
        return _ComboGridCell(
          key: ValueKey('combo-cell-${combo.id}'),
          combo: combo,
          moveCount: moveCount,
        );
      },
    );
  }
}

/// A single combo card in grid view. Subscribes to [watchComboMoves] once per
/// cell to derive both the preview background and move-name subtitle — halving
/// subscriptions vs the previous dual-widget approach.
class _ComboGridCell extends ConsumerWidget {
  const _ComboGridCell({
    super.key,
    required this.combo,
    required this.moveCount,
  });

  final Combo combo;
  final int moveCount;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final stream = ref.watch(comboRepositoryProvider).watchComboMoves(combo.id);

    return StreamBuilder<List<ComboMoveWithDetail>>(
      stream: stream,
      builder: (final context, final snapshot) {
        final moves = snapshot.data ?? const <ComboMoveWithDetail>[];

        final previewPath = moves
                .map((final item) => item.move.resolvedVideoPath)
                .whereType<String>()
                .firstOrNull ??
            combo.resolvedActiveVideoPath;

        final background = previewPath != null && previewPath.isNotEmpty
            ? _GridThumbnail(videoPath: previewPath)
            : _ComboPreviewFallback(
                stepCount: moves.length,
                stepNames: moves.map((final item) => item.move.name).take(3).toList(),
              );

        final names = moves.map((final item) => item.move.name).take(3).toList();
        final overflow = moves.length - names.length;
        final sequenceLabel = names.isEmpty
            ? '$moveCount move${moveCount == 1 ? '' : 's'}'
            : [names.join(' \u2022 '), if (overflow > 0) '+$overflow'].join(' ');

        final subtitle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sequenceLabel,
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int index = 0; index < moveCount.clamp(0, 4); index++) ...[
                  if (index > 0)
                    Container(
                      width: 12,
                      height: 1.5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.96 - (index * 0.14),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );

        return _GridCardShell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/moves/combo/${combo.id}');
          },
          background: background,
          name: combo.name,
          subtitle: subtitle,
          topRightWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.linear_scale_rounded,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '$moveCount',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ComboPreviewFallback extends StatelessWidget {
  const _ComboPreviewFallback({
    required this.stepCount,
    required this.stepNames,
  });

  final int stepCount;
  final List<String> stepNames;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Row(
              children: [
                for (int index = 0; index < stepCount.clamp(0, 4); index++) ...[
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 1.5,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: colorScheme.primary.withValues(alpha: 0.22),
                      ),
                    )
                  else
                    const SizedBox(width: 0),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: 0.94 - (index * 0.18),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final name in stepNames.take(2)) ...[
              Text(
                name,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
