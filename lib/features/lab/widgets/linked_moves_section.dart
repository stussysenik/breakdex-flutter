import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../providers/lab_providers.dart';

/// Horizontal scroll of move cards linked to a lab.
///
/// Each card shows the move name with a category pill and a thumbnail
/// placeholder. Features:
/// - Tap a card to navigate to the move detail screen
/// - "+" card at the end to add a move via a search/picker bottom sheet
/// - [DragTarget] that accepts move IDs dragged from the Arsenal tab
///
/// This section is used for 'project'-type labs to link reference moves
/// without the strict ordering of the Set Builder.
class LinkedMovesSection extends ConsumerWidget {
  const LinkedMovesSection({
    super.key,
    required this.labId,
    required this.onAddMove,
  });

  final String labId;
  final VoidCallback onAddMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labMovesAsync = ref.watch(labMovesProvider(labId));
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
          child: Text(
            'LINKED MOVES',
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // DragTarget wrapper — accepts move IDs dragged from Arsenal
        DragTarget<String>(
          onAcceptWithDetails: (details) {
            _linkMove(ref, details.data);
          },
          builder: (context, candidates, rejects) {
            final isHighlighted = candidates.isNotEmpty;

            return AnimatedContainer(
              duration: AppMotion.fast02,
              decoration: isHighlighted
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.accent, width: 2),
                    )
                  : const BoxDecoration(),
              child: labMovesAsync.when(
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge,
                  ),
                  child: Text(
                    'Error: $e',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.actionAgain,
                    ),
                  ),
                ),
                data: (labMoves) {
                  if (labMoves.isEmpty) {
                    return _EmptyLinkedMoves(onAddMove: onAddMove);
                  }

                  return SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenEdge,
                      ),
                      itemCount: labMoves.length + 1,
                      itemBuilder: (context, index) {
                        if (index == labMoves.length) {
                          return _AddLinkedMoveCard(onTap: onAddMove);
                        }
                        final item = labMoves[index];
                        return _LinkedMoveCard(
                          move: item.move,
                          onRemove: () {
                            ref
                                .read(labsDaoProvider)
                                .removeMoveFromLab(labId, item.move.id);
                            HapticFeedback.lightImpact();
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _linkMove(WidgetRef ref, String moveId) {
    // Get current count so we can append at the end
    final labMoves = ref.read(labMovesProvider(labId)).valueOrNull ?? [];
    ref
        .read(labsDaoProvider)
        .addMoveToLab(labId, moveId, labMoves.length);
    HapticFeedback.mediumImpact();
  }
}

// -- Linked Move Card ---------------------------------------------------------

class _LinkedMoveCard extends StatefulWidget {
  const _LinkedMoveCard({
    required this.move,
    required this.onRemove,
  });

  final Move move;
  final VoidCallback onRemove;

  @override
  State<_LinkedMoveCard> createState() => _LinkedMoveCardState();
}

class _LinkedMoveCardState extends State<_LinkedMoveCard> {
  bool _showDelete = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push('/moves/move/${widget.move.id}'),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        setState(() => _showDelete = !_showDelete);
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: AppSurfaces.panel(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thumbnail placeholder
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            widget.move.name.isNotEmpty
                                ? widget.move.name[0].toUpperCase()
                                : '?',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Category pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.move.category,
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.secondary,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Move name
                  Text(
                    widget.move.name,
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (_showDelete)
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.actionAgain,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -- Empty State --------------------------------------------------------------

class _EmptyLinkedMoves extends StatelessWidget {
  const _EmptyLinkedMoves({required this.onAddMove});

  final VoidCallback onAddMove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onAddMove,
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link_rounded,
                size: 18,
                color: colorScheme.secondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Link moves to this lab',
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

// -- Add Card -----------------------------------------------------------------

class _AddLinkedMoveCard extends StatelessWidget {
  const _AddLinkedMoveCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 60,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
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
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              'Add',
              style: AppTypography.caption.copyWith(
                color: AppColors.accent.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
