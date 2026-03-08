import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/database.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/services/deck_service.dart';

/// A compact card representing a saved deck in the horizontal scroll list.
///
/// Shows the deck name, type icon (smart/manual), and session size.
/// Tapping starts a review session with this deck's criteria.
class DeckCard extends StatelessWidget {
  const DeckCard({
    super.key,
    required this.deck,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final Deck deck;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmart = deck.deckType == 'smart';
    final iconData = isSmart ? Icons.tune_rounded : Icons.layers_outlined;

    String? semanticLabel;
    if (isSmart && deck.filterCriteria != null) {
      try {
        final filter = DeckFilter.fromJson(deck.filterCriteria!);
        if (filter.categories.isNotEmpty) {
          semanticLabel = filter.categories.join(', ');
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        onLongPress();
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppSurfaces.panel(
          context,
          tone: isSelected ? AppSurfaceTone.emphasis : AppSurfaceTone.base,
          raised: isSelected,
          radius: AppRadius.md,
          borderColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.24),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      iconData,
                      size: 14,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    if (deck.sessionSize != null)
                      Text(
                        '${deck.sessionSize}',
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  deck.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (semanticLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    semanticLabel,
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  onLongPress();
                },
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
