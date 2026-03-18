part of '../move_list_screen.dart';

/// Grid layout for combos — mirrors `_MoveGrid` but uses a styled placeholder
/// instead of a video thumbnail (combos don't have their own video).
class _ComboGridSliver extends StatelessWidget {
  const _ComboGridSliver({required this.combos});

  final List<(Combo, int)> combos;

  @override
  Widget build(BuildContext context) {
    return _sliverArsenalGrid(
      itemCount: combos.length,
      builder: (index) {
        final (combo, moveCount) = combos[index];
        return _ComboGridCell(combo: combo, moveCount: moveCount);
      },
    );
  }
}

/// A single combo card in grid view. Shows an accent-gradient placeholder
/// with a playlist icon, the combo name, move-count dots, and a count pill.
class _ComboGridCell extends ConsumerWidget {
  const _ComboGridCell({required this.combo, required this.moveCount});

  final Combo combo;
  final int moveCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GridCardShell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/arsenal/combo/${combo.id}');
      },
      background: _ComboPreviewBackground(combo: combo),
      name: combo.name,
      subtitle: _ComboGridMeta(combo: combo, moveCount: moveCount),
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
  }
}

class _ComboGridMeta extends ConsumerWidget {
  const _ComboGridMeta({required this.combo, required this.moveCount});

  final Combo combo;
  final int moveCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comboMovesStream = ref
        .watch(comboRepositoryProvider)
        .watchComboMoves(combo.id);

    return StreamBuilder<List<ComboMoveWithDetail>>(
      stream: comboMovesStream,
      builder: (context, snapshot) {
        final moves = snapshot.data ?? const <ComboMoveWithDetail>[];
        final names = moves.map((item) => item.move.name).take(3).toList();
        final overflow = moves.length - names.length;
        final sequenceLabel = names.isEmpty
            ? '$moveCount move${moveCount == 1 ? '' : 's'}'
            : [names.join(' • '), if (overflow > 0) '+$overflow'].join(' ');

        return Column(
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
            const SizedBox(height: 6),
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
      },
    );
  }
}

class _ComboPreviewBackground extends ConsumerWidget {
  const _ComboPreviewBackground({required this.combo});

  final Combo combo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comboMovesStream = ref
        .watch(comboRepositoryProvider)
        .watchComboMoves(combo.id);

    return StreamBuilder<List<ComboMoveWithDetail>>(
      stream: comboMovesStream,
      builder: (context, snapshot) {
        final comboMoves = snapshot.data ?? const <ComboMoveWithDetail>[];
        final previewPath =
            comboMoves
                .map((item) => item.move.videoPath)
                .whereType<String>()
                .firstOrNull ??
            combo.activeVideoPath;

        if (previewPath != null && previewPath.isNotEmpty) {
          return _GridThumbnail(videoPath: previewPath);
        }

        return _ComboPreviewFallback(
          stepCount: comboMoves.length,
          stepNames: comboMoves.map((item) => item.move.name).take(3).toList(),
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
  Widget build(BuildContext context) {
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
