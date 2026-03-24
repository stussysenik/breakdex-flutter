part of '../move_list_screen.dart';

// -- Combos Content ----------------------------------------------------------

class _CombosContentSliver extends StatelessWidget {
  const _CombosContentSliver({required this.combos});

  final List<(Combo, int)> combos;

  @override
  Widget build(BuildContext context) {
    return _sliverStaggeredList(
      itemCount: combos.length,
      builder: (index) {
        final (combo, moveCount) = combos[index];
        return _ComboRow(combo: combo, moveCount: moveCount);
      },
    );
  }
}

/// A combo list row with swipe-to-delete, move-count dots, and a colored
/// leading bar. Mirrors the `_MoveRow` pattern for consistent UX.
class _ComboRow extends ConsumerWidget {
  const _ComboRow({required this.combo, required this.moveCount});

  final Combo combo;
  final int moveCount;

  /// Max dots rendered before showing a "+N" overflow indicator.
  static const _maxDots = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(combo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.screenEdge),
        decoration: BoxDecoration(
          color: AppColors.actionAgain,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        ref.read(comboRepositoryProvider).delete(combo.id);
      },
      child: Semantics(
        identifier: 'combo-row-${combo.id}',
        label: '${combo.name}, $moveCount moves',
        button: true,
        child: InkWell(
          onTap: () => context.go('/moves/combo/${combo.id}'),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Leading accent bar
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.sm),
                        bottomLeft: Radius.circular(AppRadius.sm),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.linear_scale_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            combo.name,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (moveCount > 0) ...[
                            const SizedBox(height: AppSpacing.xs),
                            _MoveCountDots(count: moveCount),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
