import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/services/categories_service.dart';
import '../providers/review_providers.dart';

/// Top dashboard showing state filter chips, category filter chips,
/// and a session summary line. Supports auto-collapse.
class ReviewDashboard extends ConsumerWidget {
  const ReviewDashboard({
    super.key,
    required this.currentIndex,
    required this.totalInSession,
  });

  final int currentIndex;
  final int totalInSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(dashboardExpandedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: _ExpandedContent(
            currentIndex: currentIndex,
            totalInSession: totalInSession,
          ),
          secondChild: const _CollapsedBar(),
          crossFadeState:
              expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
        ),
        // Progress is always visible
        _ProgressSection(
          currentIndex: currentIndex,
          totalInSession: totalInSession,
        ),
      ],
    );
  }
}

class _CollapsedBar extends ConsumerWidget {
  const _CollapsedBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedState = ref.watch(reviewStateFilterProvider);
    final selectedCategory = ref.watch(reviewCategoryFilterProvider);
    final sessionSize = ref.watch(reviewSessionSizeProvider);

    final parts = <String>[];
    if (selectedState != null) {
      parts.add(selectedState.displayText);
    }
    if (selectedCategory != null) {
      parts.add(selectedCategory);
    }
    if (sessionSize != null) {
      parts.add('$sessionSize cards');
    }

    final summary =
        parts.isEmpty ? 'All moves' : parts.join(' \u2022 ');

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(dashboardExpandedProvider.notifier).state = true;
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
        child: Row(
          children: [
            Icon(Icons.filter_list, size: 16, color: colorScheme.secondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                summary,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more, size: 18, color: colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}

class _ExpandedContent extends ConsumerWidget {
  const _ExpandedContent({
    required this.currentIndex,
    required this.totalInSession,
  });

  final int currentIndex;
  final int totalInSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final stateCounts = ref.watch(moveStateCountsProvider);
    final selectedState = ref.watch(reviewStateFilterProvider);
    final selectedCategory = ref.watch(reviewCategoryFilterProvider);
    final categories = ref.watch(categoriesProvider);
    final categoryCounts = ref.watch(moveCategoryCountsProvider);
    final stateTemporalCounts = ref.watch(reviewStateTemporalCountsProvider);
    final categoryTemporalCounts =
        ref.watch(reviewCategoryTemporalCountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State filter chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
            ),
            children: [
              _StateChip(
                label: 'All',
                color: AppColors.accent,
                count: stateCounts.whenOrNull(
                  data: (c) => c.values.fold<int>(0, (a, b) => a + b),
                ),
                temporalCounts: null,
                selected: selectedState == null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(reviewStateFilterProvider.notifier).state = null;
                },
              ),
              for (final state in LearningState.values) ...[
                const SizedBox(width: AppSpacing.sm),
                _StateChip(
                  label: state.displayText,
                  color: state.color,
                  count: stateCounts.whenOrNull(data: (c) => c[state] ?? 0),
                  temporalCounts: stateTemporalCounts.whenOrNull(
                    data: (c) => c[state],
                  ),
                  selected: selectedState == state,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(reviewStateFilterProvider.notifier).state =
                        selectedState == state ? null : state;
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Category filter chips
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
            ),
            children: [
              _CategoryChip(
                label: 'All',
                color: colorScheme.secondary,
                count: null,
                temporalCounts: null,
                selected: selectedCategory == null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(reviewCategoryFilterProvider.notifier).state = null;
                },
              ),
              for (final cat in categories) ...[
                const SizedBox(width: AppSpacing.sm),
                _CategoryChip(
                  label: cat.name,
                  color: cat.color,
                  count: categoryCounts.whenOrNull(
                    data: (c) => c[cat.name] ?? 0,
                  ),
                  temporalCounts: categoryTemporalCounts.whenOrNull(
                    data: (c) => c[cat.name],
                  ),
                  selected: selectedCategory == cat.name,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(reviewCategoryFilterProvider.notifier).state =
                        selectedCategory == cat.name ? null : cat.name;
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Session size selector
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          child: _SessionSizeRow(),
        ),
      ],
    );
  }
}

class _ProgressSection extends ConsumerWidget {
  const _ProgressSection({
    required this.currentIndex,
    required this.totalInSession,
  });

  final int currentIndex;
  final int totalInSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (totalInSession <= 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenEdge,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalInSession > 0
                        ? (currentIndex + 1) / totalInSession
                        : 0,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: AppColors.accent,
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${currentIndex + 1}/$totalInSession',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.color,
    required this.count,
    required this.temporalCounts,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final int? count;
  final TemporalCounts? temporalCounts;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: selected
              ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: selected ? color : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (temporalCounts != null) ...[
              const SizedBox(width: 5),
              _TemporalBadge(
                counts: temporalCounts!,
                color: selected ? color : colorScheme.secondary,
              ),
            ] else if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppTypography.caption.copyWith(
                  color: (selected ? color : colorScheme.secondary)
                      .withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionSizeRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = ref.watch(reviewSessionSizeProvider);

    return Row(
      children: [
        Text(
          'SESSION',
          style: AppTypography.caption.copyWith(
            color: colorScheme.secondary,
            letterSpacing: 1.5,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        for (final size in reviewSessionSizeOptions) ...[
          if (size != reviewSessionSizeOptions.first)
            const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(reviewSessionSizeProvider.notifier).state = size;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected == size
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: selected == size
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : colorScheme.surfaceContainerHighest,
                  width: 1,
                ),
              ),
              child: Text(
                size?.toString() ?? 'All',
                style: AppTypography.caption.copyWith(
                  color: selected == size
                      ? AppColors.accent
                      : colorScheme.secondary,
                  fontWeight:
                      selected == size ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.count,
    required this.temporalCounts,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final int? count;
  final TemporalCounts? temporalCounts;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : colorScheme.surfaceContainerHighest,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: selected ? color : colorScheme.secondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
            if (temporalCounts != null) ...[
              const SizedBox(width: 4),
              _TemporalBadge(
                counts: temporalCounts!,
                color: selected ? color : colorScheme.secondary,
                compact: true,
              ),
            ] else if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppTypography.caption.copyWith(
                  color: (selected ? color : colorScheme.secondary)
                      .withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact temporal badge: today|week|total with decreasing opacity.
class _TemporalBadge extends StatelessWidget {
  const _TemporalBadge({
    required this.counts,
    required this.color,
    this.compact = false,
  });

  final TemporalCounts counts;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 8.0 : 9.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${counts.today}',
          style: AppTypography.caption.copyWith(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '|',
          style: AppTypography.caption.copyWith(
            color: color.withValues(alpha: 0.4),
            fontSize: fontSize,
          ),
        ),
        Text(
          '${counts.thisWeek}',
          style: AppTypography.caption.copyWith(
            color: color.withValues(alpha: 0.7),
            fontSize: fontSize,
          ),
        ),
        Text(
          '|',
          style: AppTypography.caption.copyWith(
            color: color.withValues(alpha: 0.3),
            fontSize: fontSize,
          ),
        ),
        Text(
          '${counts.total}',
          style: AppTypography.caption.copyWith(
            color: color.withValues(alpha: 0.5),
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
