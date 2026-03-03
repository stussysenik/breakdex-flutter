import 'package:flutter/material.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';

/// The AGAIN / HARD / GOOD rating buttons + skip.
class RatingButtonRow extends StatelessWidget {
  const RatingButtonRow({
    super.key,
    required this.onRate,
    required this.onSkip,
  });

  final void Function(ReviewRating rating) onRate;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final rating in ReviewRating.values) ...[
              if (rating != ReviewRating.values.first)
                const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => onRate(rating),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rating.color,
                      foregroundColor: rating != ReviewRating.again
                          ? Colors.black
                          : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      textStyle: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(rating.displayText),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: onSkip,
          child: Text(
            'Skip →',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
