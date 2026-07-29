part of '../move_list_screen.dart';

// -- Combos Content ----------------------------------------------------------

class _CombosContentSliver extends StatelessWidget {
  const _CombosContentSliver({required this.combos});

  final List<(Combo, int, DateTime)> combos;

  @override
  Widget build(final BuildContext context) {
    return _sliverStaggeredList(
      itemCount: combos.length,
      builder: (final index) {
        final (combo, moveCount, date) = combos[index];
        return _ComboRow(
          combo: combo,
          moveCount: moveCount,
          date: date,
          index: index,
        );
      },
    );
  }
}

/// A combo list row with swipe-to-delete, move-count dots, and a colored
/// leading bar. Mirrors the `_MoveRow` pattern for consistent UX.
class _ComboRow extends ConsumerWidget {
  const _ComboRow({
    required this.combo,
    required this.moveCount,
    required this.date,
    this.index = 0,
  });

  final Combo combo;
  final int moveCount;

  /// The combo's effective date under the active sort, resolved by the sliver.
  final DateTime date;

  final int index;

  /// Max dots rendered before showing a "+N" overflow indicator.
  static const _maxDots = 8;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
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
        child: const AppIconView(AppIcon.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        DiagnosticsLog.info(
          'ComboRow',
          'Swipe-dismiss combo id=${combo.id} name="${combo.name}"',
        );
        unawaited(HapticFeedback.heavyImpact());
        unawaited(_deleteCombo(ref));
      },
      confirmDismiss: (final direction) async {
        DiagnosticsLog.trace(
          'ComboRow',
          'confirmDismiss direction=$direction id=${combo.id}',
        );
        return true;
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
            child:
                IntrinsicHeight(
                      child: Row(
                        children: [
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
                          AppIconView(
                            AppIcon.combo,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  const SizedBox(height: AppSpacing.xs),
                                  // Same metadata Wrap as `_MoveRow`, so the two row
                                  // types read as one library rather than two.
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.xs,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (moveCount > 0)
                                        _MoveCountDots(count: moveCount),
                                      LibraryDateLabel(date: date),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AppIconView(
                            AppIcon.forward,
                            color: colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(
                      duration: AppMotion.moderate01,
                      delay: Duration(milliseconds: index.clamp(0, 15) * 40),
                    )
                    .slideY(
                      begin: 0.03,
                      duration: AppMotion.moderate02,
                      delay: Duration(milliseconds: index.clamp(0, 15) * 40),
                    ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCombo(final WidgetRef ref) async {
    final log = StageLogger.begin(
      '_deleteCombo',
      subsystem: 'ComboRow',
      context: {'comboId': combo.id, 'name': combo.name},
    );
    try {
      await ref.read(blackboxServiceProvider).log(
        'delete_combo',
        'combo',
        combo.id,
        {'name': combo.name},
      );
      log.stage('blackboxLogged');
      await ref.read(mediaCleanupServiceProvider).cleanupComboMedia(combo);
      log.stage('cleanupComboMedia');
      await ref.read(comboRepositoryProvider).delete(combo.id);
      log.stage('dbDeleted');
      log.complete();
    } catch (e, stack) {
      log.fail(e, stack);
      rethrow;
    }
  }
}
