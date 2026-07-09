// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/labs_dao.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/app_loader.dart';
import '../providers/lab_providers.dart';
import '../../flow/widgets/aura_transition_indicator.dart';
import 'set_move_card.dart';

/// Horizontal move sequencer for labs with type 'set'.
///
/// Displays linked moves as compact cards in a horizontally-scrollable row,
/// with small transition indicators (colored dots) between each card as
/// placeholders for the future Aura transition system. Supports:
///
/// - **LongPressDraggable + DragTarget** for reordering moves within the set
/// - **"+" button** at the end to open the move picker and add new moves
/// - **Empty state** with an instructional message and a dashed border
///
/// Watches [labMovesProvider] for reactive updates — any change to the
/// lab_moves junction table immediately reflects in the UI.
class SetBuilder extends ConsumerWidget {
  const SetBuilder({
    super.key,
    required this.labId,
    required this.onAddMove,
  });

  final String labId;
  final VoidCallback onAddMove;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final labMovesAsync = ref.watch(labMovesProvider(labId));
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
          child: Text(
            'SET SEQUENCE',
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Sequencer row
        labMovesAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: AppLoader()),
          ),
          error: (final e, _) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
            ),
            child: Text(
              'Error loading moves: $e',
              style: AppTypography.caption.copyWith(color: AppColors.actionAgain),
            ),
          ),
          data: (final labMoves) {
            if (labMoves.isEmpty) {
              return _EmptySetState(onAddMove: onAddMove);
            }

            return SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                itemCount: labMoves.length + 1, // +1 for add button
                itemBuilder: (final context, final index) {
                  // Add button at the end
                  if (index == labMoves.length) {
                    return _AddMoveButton(onTap: onAddMove);
                  }

                  final item = labMoves[index];
                  final card = SetMoveCard(
                    move: item.move,
                    index: index,
                    onRemove: () => _removeMoveFromLab(ref, item.move.id),
                  );

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag source + drop target for reordering
                      LongPressDraggable<int>(
                        data: index,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Opacity(
                            opacity: 0.8,
                            child: SizedBox(
                              width: 100,
                              height: 120,
                              child: card,
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: card,
                        ),
                        onDragStarted: () => HapticFeedback.mediumImpact(),
                        child: DragTarget<int>(
                          onAcceptWithDetails: (final details) {
                            _reorder(ref, labMoves, details.data, index);
                          },
                          builder: (final context, final candidates, final rejects) {
                            return AnimatedContainer(
                              duration: AppMotion.fast02,
                              padding: EdgeInsets.all(
                                candidates.isNotEmpty ? 4 : 0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: candidates.isNotEmpty
                                    ? Border.all(
                                        color: AppColors.accent,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: card,
                            );
                          },
                        ),
                      ),
                      // Aura transition indicator between cards —
                      // shows the rated affinity (green/amber/red/gray)
                      // between consecutive moves in the set sequence.
                      if (index < labMoves.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: AuraTransitionIndicator(
                            fromMoveId: labMoves[index].move.id,
                            toMoveId: labMoves[index + 1].move.id,
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// Reorder moves by swapping source and target indices, then persisting
  /// the new order via the DAO.
  void _reorder(
    final WidgetRef ref,
    final List<LabMoveWithDetail> current,
    final int fromIndex,
    final int toIndex,
  ) {
    if (fromIndex == toIndex) return;
    final moveIds = current.map((final e) => e.move.id).toList();
    final removed = moveIds.removeAt(fromIndex);
    moveIds.insert(toIndex, removed);
    ref.read(labsDaoProvider).reorderLabMoves(labId, moveIds);
    HapticFeedback.selectionClick();
  }

  void _removeMoveFromLab(final WidgetRef ref, final String moveId) {
    ref.read(labsDaoProvider).removeMoveFromLab(labId, moveId);
    HapticFeedback.lightImpact();
  }
}

// -- Empty state --------------------------------------------------------------

class _EmptySetState extends StatelessWidget {
  const _EmptySetState({required this.onAddMove});

  final VoidCallback onAddMove;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onAddMove,
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                color: colorScheme.secondary.withValues(alpha: 0.5),
                size: 28,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Drag moves here to build your set',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Add Move Button ----------------------------------------------------------

class _AddMoveButton extends StatelessWidget {
  const _AddMoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 60,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                color: AppColors.accent.withValues(alpha: 0.7),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                'Add',
                style: AppTypography.caption.copyWith(
                  color: AppColors.accent.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
