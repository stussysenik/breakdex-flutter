import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';
import '../../../core/services/categories_service.dart';
import '../providers/stats_providers.dart';

/// Top practiced moves list with enriched subtitle: category + FSRS state + last reviewed.
class TopMovesList extends ConsumerWidget {
  const TopMovesList({super.key, required this.topMoves});

  final List<TopMoveInfo> topMoves;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesProvider);
    final stateLabels = ref.watch(learningStateLabelsProvider);

    if (topMoves.isEmpty) {
      return Text(
        'No reviews yet',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: cs.secondary),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          for (int i = 0; i < topMoves.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
            _MoveRow(
              rank: i + 1,
              info: topMoves[i],
              categories: categories,
              stateLabels: stateLabels,
            ),
          ],
        ],
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({
    required this.rank,
    required this.info,
    required this.categories,
    required this.stateLabels,
  });

  final int rank;
  final TopMoveInfo info;
  final List<Category> categories;
  final Map<LearningState, String> stateLabels;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Resolve category color
    final catMatch = categories
        .where((c) => c.name == info.category)
        .firstOrNull;
    final catColor = catMatch?.color ?? cs.secondary;

    final visibleState = _visibleState(info.fsrsStateLabel);
    final stateColor = context.stateColor(visibleState);
    final stateLabel = resolveLearningStateLabel(stateLabels, visibleState);

    // Last reviewed date
    final lastReviewedText = info.lastReviewed != null
        ? DateFormat('MMM d').format(info.lastReviewed!)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: stateColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.moveName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (info.category != 'default') ...[
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: catColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        info.category,
                        style: AppTypography.caption.copyWith(
                          color: cs.secondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    Text(
                      stateLabel,
                      style: AppTypography.caption.copyWith(
                        color: stateColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (lastReviewedText.isNotEmpty) ...[
                      Text(
                        lastReviewedText,
                        style: AppTypography.caption.copyWith(
                          color: cs.secondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${info.reviewCount}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.secondary),
          ),
        ],
      ),
    );
  }

  LearningState _visibleState(String rawLabel) {
    final normalized = rawLabel.trim().toLowerCase();
    return switch (normalized) {
      'mastered' || 'review' || 'mastery' => LearningState.mastery,
      'learning' || 'learn' || 'relearning' => LearningState.learning,
      _ => LearningState.newState,
    };
  }
}
