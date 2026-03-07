import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';

/// The AGAIN / HARD / GOOD / EASY rating buttons styled as subtle tinted pills.
///
/// Each button uses both color AND a distinct icon shape for accessibility:
/// red is commonly confused with green (deuteranopia), so shape
/// differentiators ensure ratings are distinguishable without color.
///
/// Colors are read from [ratingColorsProvider] so they respect user
/// customization from Settings.
class RatingButtonRow extends ConsumerWidget {
  const RatingButtonRow({
    super.key,
    required this.onRate,
    this.intervalPreviews,
  });

  final void Function(ReviewRating rating) onRate;

  /// Optional interval preview per rating — when provided, shows the
  /// scheduled interval below each button so the learner sees the
  /// consequence of each rating before tapping.
  final Map<ReviewRating, Duration>? intervalPreviews;

  /// Distinct icon per rating for color-blind accessibility.
  /// Shape + color = double encoding (WCAG 1.4.1 Use of Color).
  static IconData _iconForRating(ReviewRating rating) => switch (rating) {
        ReviewRating.again => Icons.close_rounded,    // X shape — "wrong"
        ReviewRating.hard  => Icons.remove_rounded,   // Minus — "struggle"
        ReviewRating.good  => Icons.check_rounded,    // Checkmark — "got it"
        ReviewRating.easy  => Icons.star_rounded,     // Star — "effortless"
      };

  /// Map from ReviewRating to the matching configurable color.
  static Color _colorForRating(ReviewRating rating, RatingColors rc) =>
      switch (rating) {
        ReviewRating.again => rc.again,
        ReviewRating.hard  => rc.hard,
        ReviewRating.good  => rc.good,
        ReviewRating.easy  => rc.easy,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final rc = ref.watch(ratingColorsProvider);

    return Row(
      children: [
        for (final rating in ReviewRating.values) ...[
          if (rating != ReviewRating.values.first)
            const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TintedPillButton(
                  rating: rating,
                  icon: _iconForRating(rating),
                  color: _colorForRating(rating, rc),
                  onRate: onRate,
                ),
                if (intervalPreviews != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatInterval(intervalPreviews![rating]),
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Format a Duration into a compact human-readable interval.
  ///
  /// Matches Anki's convention:
  /// - < 1 hour → "Xm" (minutes)
  /// - < 24 hours → "Xh" (hours)
  /// - < 30 days → "Xd" (days)
  /// - >= 30 days → "Xmo" (months)
  static String _formatInterval(Duration? duration) {
    if (duration == null) return '';
    final minutes = duration.inMinutes;
    if (minutes < 60) return '${minutes}m';
    final hours = duration.inHours;
    if (hours < 24) return '${hours}h';
    final days = duration.inDays;
    if (days < 30) return '${days}d';
    return '${(days / 30).round()}mo';
  }
}

/// Tinted pill rating button — subtle translucent background with colored text.
///
/// 44dp height meets Apple HIG minimum touch target. Full pill shape with
/// `AppRadius.xl` (30). Background uses 10% opacity tint of the rating color.
class _TintedPillButton extends StatelessWidget {
  const _TintedPillButton({
    required this.rating,
    required this.icon,
    required this.color,
    required this.onRate,
  });

  final ReviewRating rating;
  final IconData icon;
  final Color color;
  final void Function(ReviewRating rating) onRate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rate ${rating.displayText}',
      button: true,
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onRate(rating);
          },
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
                Text(
                  rating.displayText,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
