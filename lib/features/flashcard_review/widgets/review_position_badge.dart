import 'package:flutter/material.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';

/// Compact textual counter for the immersive review overlay.
///
/// Dot progress looked decorative and read as artifact against video. A
/// readable textual badge communicates the same information with less noise.
class ReviewPositionBadge extends StatelessWidget {
  const ReviewPositionBadge({
    super.key,
    required this.currentIndex,
    required this.total,
  });

  final int currentIndex;
  final int total;

  @override
  Widget build(final BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        '${currentIndex + 1} of $total',
        style: AppTypography.bodySmall.copyWith(
          color: Colors.white.withValues(alpha: 0.94),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
