import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';

/// Compact card representing a single move inside the Set Builder sequencer.
///
/// Supports two interaction modes:
/// - **Tap**: navigates to the move's detail screen for full editing.
/// - **Long press**: activates LongPressDraggable for reorder (handled by
///   the parent SetBuilder) and reveals a delete (X) button in the top-right
///   corner so the user can remove the move from the set.
///
/// The card shows the move name and a colored placeholder for the video
/// thumbnail (actual thumbnail integration arrives with the Aura system).
class SetMoveCard extends StatefulWidget {
  const SetMoveCard({
    super.key,
    required this.move,
    required this.index,
    required this.onRemove,
  });

  final Move move;
  final int index;
  final VoidCallback onRemove;

  @override
  State<SetMoveCard> createState() => _SetMoveCardState();
}

class _SetMoveCardState extends State<SetMoveCard> {
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
      child: SizedBox(
        width: 100,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 100,
              height: 120,
              decoration: AppSurfaces.panel(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Video thumbnail placeholder — colored circle with move
                  // initial. Will be replaced with actual thumbnail once the
                  // video thumbnail cache is wired through.
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.move.name.isNotEmpty
                            ? widget.move.name[0].toUpperCase()
                            : '?',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Move name — truncated to 2 lines
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text(
                      widget.move.name,
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Delete button — appears on long press
            if (_showDelete)
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onRemove();
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.actionAgain,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
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
