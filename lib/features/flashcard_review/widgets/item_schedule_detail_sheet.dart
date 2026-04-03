import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/models/reviewable_item.dart';
import '../../../core/providers.dart';
import '../../../core/services/fsrs_service.dart';
import '../providers/deck_providers.dart';
import '../providers/review_providers.dart';

/// Bottom sheet showing the full FSRS math breakdown for a single item.
///
/// Displays:
/// - Stability bar (visual representation of memory duration)
/// - Difficulty bar (0–10 scale)
/// - Retrievability percentage
/// - Reps / lapses counts
/// - Rating previews ("If AGAIN → 1m, If GOOD → 4d") with concrete dates
/// - "Review Now" button to start a single-item session
class ItemScheduleDetailSheet extends ConsumerWidget {
  const ItemScheduleDetailSheet({super.key, required this.item});

  final ReviewableItemWithCard item;

  static Future<void> show(BuildContext context, ReviewableItemWithCard item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItemScheduleDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final canReviewNow = item.item is ReviewableMove;
    final coefficientsAsync = ref.watch(
      srsCoefficientsProvider((
        entityId: item.item.entityId,
        entityType: item.item.entityType,
      )),
    );
    final intervalsAsync = ref.watch(
      intervalPreviewProvider((
        entityId: item.item.entityId,
        entityType: item.item.entityType,
      )),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.screenEdge,
          right: AppSpacing.screenEdge,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewPadding.bottom + AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Item name + state badge
            Row(
              children: [
                Icon(
                  item.item is ReviewableCombo
                      ? Icons.linear_scale_rounded
                      : Icons.sports_martial_arts,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.item.displayName,
                    style: AppTypography.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                _StateBadge(fsrsState: item.card?.fsrsState ?? 0),
              ],
            ),
            if (item.item.category != null) ...[
              const SizedBox(height: 4),
              Text(
                item.item.category!,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // Rating previews (Practical dates)
            Text(
              'Upcoming Schedule',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            intervalsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (intervals) => _RatingPreviews(intervals: intervals),
            ),
            const SizedBox(height: AppSpacing.lg),

            // FSRS Math (Hidden under advanced)
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                title: Text(
                  'Advanced Algorithm Stats',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.lg,
                ),
                children: [
                  coefficientsAsync.when(
                    loading: () => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                    data: (coeff) => _CoefficientDisplay(coeff: coeff),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Review Now button
            if (canReviewNow)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    ref
                        .read(reviewModeProvider.notifier)
                        .set(ReviewMode.review);
                    ref
                        .read(reviewSessionSourceProvider.notifier)
                        .set(ReviewSessionSource.stateBased);
                    ref.read(selectedDeckProvider.notifier).state = null;
                    ref.read(reviewStateFilterProvider.notifier).state = null;
                    ref
                        .read(reviewSessionTargetMoveIdsProvider.notifier)
                        .state = {
                      item.item.entityId,
                    };
                    refreshReviewSession(ref);
                    ref.read(reviewSessionActiveProvider.notifier).state = true;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: const Text('Review Now'),
                ),
              ),
            if (!canReviewNow)
              Text(
                'Combo sessions still open in the schedule view only.',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StateBadge extends ConsumerWidget {
  const _StateBadge({required this.fsrsState});
  final int fsrsState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleState = learningStateFromFsrsState(fsrsState);
    final labels = ref.watch(learningStateLabelsProvider);
    final label = resolveLearningStateLabel(labels, visibleState);
    final color = context.stateColor(visibleState);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _CoefficientDisplay extends StatelessWidget {
  const _CoefficientDisplay({required this.coeff});
  final SrsCoefficients coeff;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final retPct = (coeff.retrievability * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stability bar
        _CoeffBar(
          label: 'Stability',
          value: coeff.stabilityFormatted,
          fraction: (coeff.stability / 365).clamp(0, 1),
          color: AppColors.stateMastery,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Difficulty bar
        _CoeffBar(
          label: 'Difficulty',
          value: coeff.difficulty.toStringAsFixed(1),
          fraction: coeff.difficulty / 10,
          color: AppColors.actionHard,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Retrievability bar
        _CoeffBar(
          label: 'Retrievability',
          value: '$retPct%',
          fraction: coeff.retrievability,
          color: coeff.retrievability > 0.85
              ? AppColors.actionGood
              : coeff.retrievability > 0.5
              ? AppColors.actionHard
              : AppColors.actionAgain,
        ),
        const SizedBox(height: AppSpacing.md),

        // Reps / Lapses row
        Row(
          children: [
            _StatChip(
              label: 'Reps',
              value: '${coeff.reps}',
              color: AppColors.actionGood,
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatChip(
              label: 'Lapses',
              value: '${coeff.lapses}',
              color: AppColors.actionAgain,
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatChip(
              label: 'Interval',
              value: _fmtDuration(coeff.interval),
              color: colorScheme.secondary,
            ),
          ],
        ),
      ],
    );
  }

  static String _fmtDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }
}

class _CoeffBar extends StatelessWidget {
  const _CoeffBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            Text(
              value,
              style: AppTypography.caption.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction.clamp(0, 1),
            backgroundColor: colorScheme.surfaceContainerHigh,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.bodySmall.copyWith(
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

class _RatingPreviews extends StatelessWidget {
  const _RatingPreviews({required this.intervals});
  final Map<ReviewRating, Duration> intervals;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Column(
      children: ReviewRating.values.map((rating) {
        final interval = intervals[rating] ?? Duration.zero;
        final nextDue = now.add(interval);
        final dateStr = _formatDate(nextDue);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: rating.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                child: Text(
                  rating.displayText,
                  style: AppTypography.caption.copyWith(
                    color: rating.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, size: 12, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                _formatInterval(interval),
                style: AppTypography.caption.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static String _formatInterval(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }

  static String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
