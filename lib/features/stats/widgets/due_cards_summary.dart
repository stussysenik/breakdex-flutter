import 'package:flutter/material.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/services/fsrs_service.dart';

/// Anki-style 3-column total card breakdown: New / Learning / Mastery.
///
/// Uses [TotalStateCounts] to show the **total** number of cards in each
/// FSRS state, not just due ones. LEARN combines learning + relearning
/// since both represent cards the user is actively working on.
class DueCardsSummary extends StatelessWidget {
  const DueCardsSummary({
    super.key,
    required this.totalStateCounts,
  });

  final TotalStateCounts totalStateCounts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DueColumn(
          label: 'NEW',
          count: totalStateCounts.newCount,
          color: AppColors.stateNew,
        ),
        const SizedBox(width: AppSpacing.sm),
        _DueColumn(
          label: 'LEARN',
          count: totalStateCounts.learningCount +
              totalStateCounts.relearningCount,
          color: AppColors.stateLearning,
        ),
        const SizedBox(width: AppSpacing.sm),
        _DueColumn(
          label: 'MASTERY',
          count: totalStateCounts.reviewCount,
          color: AppColors.stateMastery,
        ),
      ],
    );
  }
}

class _DueColumn extends StatelessWidget {
  const _DueColumn({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: AppTypography.titleSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
