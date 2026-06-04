import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';
import '../../../core/services/fsrs_service.dart';

/// Anki-style 3-column total card breakdown: New / Learning / Mastery.
///
/// Uses [TotalStateCounts] to show the **total** number of cards in each
/// FSRS state, not just due ones. LEARN combines learning + relearning
/// since both represent cards the user is actively working on.
class DueCardsSummary extends ConsumerWidget {
  const DueCardsSummary({super.key, required this.totalStateCounts});

  final TotalStateCounts totalStateCounts;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final labels = ref.watch(learningStateLabelsProvider);

    return Row(
      children: [
        _DueColumn(
          label: resolveLearningStateLabel(labels, LearningState.newState),
          count: totalStateCounts.newCount,
          color: context.stateColor(LearningState.newState),
        ),
        const SizedBox(width: AppSpacing.sm),
        _DueColumn(
          label: resolveLearningStateLabel(labels, LearningState.learning),
          count: totalStateCounts.learningCount,
          color: context.stateColor(LearningState.learning),
        ),
        const SizedBox(width: AppSpacing.sm),
        _DueColumn(
          label: resolveLearningStateLabel(labels, LearningState.mastery),
          count: totalStateCounts.reviewCount,
          color: context.stateColor(LearningState.mastery),
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
  Widget build(final BuildContext context) {
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
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
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
