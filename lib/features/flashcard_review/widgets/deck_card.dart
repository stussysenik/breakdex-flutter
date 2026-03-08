import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/database.dart';
import '../../../core/design/spacing.dart';
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

    // Parse filter criteria for display
    String subtitle = isSmart ? 'Smart' : 'Manual';
    if (isSmart && deck.filterCriteria != null) {
      try {
        final filter = DeckFilter.fromJson(deck.filterCriteria!);
        final parts = <String>[];
        if (filter.categories.isNotEmpty) {
          parts.add(filter.categories.join(', '));
        }
        if (filter.dueOnly) parts.add('Due only');
        if (parts.isNotEmpty) subtitle = parts.join(' · ');
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
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
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
                      isSmart ? Icons.auto_awesome : Icons.playlist_add_check,
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
                const SizedBox(height: 6),
                Text(
                  deck.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isSelected ? 'Ready to review' : subtitle,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : colorScheme.secondary,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
