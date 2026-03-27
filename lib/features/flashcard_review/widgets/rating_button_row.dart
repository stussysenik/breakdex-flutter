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
    this.compact = false,
  });

  final void Function(ReviewRating rating) onRate;

  /// Optional interval preview per rating — when provided, shows the
  /// scheduled interval below each button so the learner sees the
  /// consequence of each rating before tapping.
  final Map<ReviewRating, Duration>? intervalPreviews;

  /// Compact mode: icon + interval only, no text label, 44pt height.
  /// Designed for the immersive review layout's slim rating strip.
  final bool compact;

  /// Distinct icon per rating for color-blind accessibility.
  /// Shape + color = double encoding (WCAG 1.4.1 Use of Color).
  static IconData _iconForRating(ReviewRating rating) => switch (rating) {
        ReviewRating.again => Icons.close_rounded,    // X shape — "wrong"
        ReviewRating.hard  => Icons.trending_flat_rounded, // Wave — "struggled"
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
            const SizedBox(width: 12),
          Expanded(
            child: compact
                ? _CompactRatingButton(
                    rating: rating,
                    icon: _iconForRating(rating),
                    color: _colorForRating(rating, rc),
                    onRate: onRate,
                    intervalLabel: _formatInterval(intervalPreviews?[rating]),
                  )
                : Column(
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

/// Compact rating button — icon + label + interval, 60pt height.
///
/// Used in the immersive review layout's rating strip. Shows the rating
/// label (Again/Hard/Good/Easy) for expressiveness, with the scheduled
/// interval below it so the learner sees the consequence before tapping.
class _CompactRatingButton extends StatelessWidget {
  const _CompactRatingButton({
    required this.rating,
    required this.icon,
    required this.color,
    required this.onRate,
    required this.intervalLabel,
  });

  final ReviewRating rating;
  final IconData icon;
  final Color color;
  final void Function(ReviewRating rating) onRate;
  final String intervalLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rate ${rating.displayText}',
      button: true,
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: () {
            switch (rating) {
              case ReviewRating.again:
                HapticFeedback.heavyImpact();
              case ReviewRating.hard:
                HapticFeedback.mediumImpact();
              case ReviewRating.good:
                HapticFeedback.lightImpact();
              case ReviewRating.easy:
                HapticFeedback.selectionClick();
            }
            onRate(rating);
          },
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 2),
                Text(
                  rating.displayText,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (intervalLabel.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    intervalLabel,
                    style: AppTypography.caption.copyWith(
                      color: color.withValues(alpha: 0.5),
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tinted pill rating button — subtle translucent background with colored text.
///
/// 48dp height keeps the tap target generous while the sharper radius keeps
/// the action row looking more deliberate and less bubble-like.
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onRate(rating);
          },
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 48,
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
