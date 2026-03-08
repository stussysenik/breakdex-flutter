import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/services/stats_export_service.dart';
import '../../shared/widgets/app_segmented_control.dart';
import 'providers/stats_providers.dart';
import 'widgets/heat_map_grid.dart';
import 'widgets/stat_card.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

enum _StatsMode { card, time }

class _StatsScreenState extends ConsumerState<StatsScreen> {
  _StatsMode _mode = _StatsMode.card;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statsBundleProvider);

    return Scaffold(
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (stats) {
            final moveCards = stats.cardStats
                .where((item) => item.entityType == 'move')
                .length;
            final comboCards = stats.cardStats
                .where((item) => item.entityType == 'combo')
                .length;

            return CustomScrollView(
              slivers: [
                // 1. Title + share button
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge,
                    AppSpacing.lg,
                    AppSpacing.screenEdge,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                'Stats',
                                style: AppTypography.titleLarge.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _mode == _StatsMode.card
                                  ? 'Cards, outcomes, and retention.'
                                  : 'Timeline, days, and exact reactions.',
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        _ShareButton(stats: stats),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge,
                    AppSpacing.md,
                    AppSpacing.screenEdge,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _StatsHeroCard(mode: _mode, stats: stats),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge,
                    AppSpacing.md,
                    AppSpacing.screenEdge,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: AppSegmentedControl<_StatsMode>(
                      items: const [
                        AppSegmentedControlItem(
                          value: _StatsMode.card,
                          icon: Icons.view_agenda_rounded,
                          label: 'Card',
                        ),
                        AppSegmentedControlItem(
                          value: _StatsMode.time,
                          icon: Icons.schedule_rounded,
                          label: 'Time',
                        ),
                      ],
                      selectedValue: _mode,
                      onChanged: (selection) {
                        HapticFeedback.selectionClick();
                        setState(() => _mode = selection);
                      },
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge,
                    vertical: AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: _mode == _StatsMode.card
                                ? 'Retention'
                                : 'Streak',
                            value: _mode == _StatsMode.card
                                ? '${(stats.overallRetention * 100).round()}%'
                                : '${stats.currentStreak}',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatCard(
                            label: _mode == _StatsMode.card
                                ? 'Events'
                                : '30d Active',
                            value: _mode == _StatsMode.card
                                ? '${stats.reviewTimeline.length}'
                                : '${stats.dailyBreakdown.where((day) => day.reviewCount > 0).length}',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatCard(
                            label: _mode == _StatsMode.card
                                ? 'Moves / Combos'
                                : 'Timeline',
                            value: _mode == _StatsMode.card
                                ? '$moveCards / $comboCards'
                                : '${stats.reviewTimeline.length}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_mode == _StatsMode.card) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenEdge,
                      AppSpacing.md,
                      AppSpacing.screenEdge,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Per Card',
                          style: AppTypography.titleMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = stats.cardStats[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenEdge,
                          AppSpacing.md,
                          AppSpacing.screenEdge,
                          0,
                        ),
                        child: _CardStatTile(item: item),
                      ).animate().fadeIn(
                        duration: AppMotion.moderate01,
                        delay: Duration(milliseconds: index.clamp(0, 12) * 35),
                      );
                    }, childCount: stats.cardStats.length),
                  ),
                ] else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenEdge,
                      AppSpacing.md,
                      AppSpacing.screenEdge,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Activity',
                          style: AppTypography.titleMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenEdge,
                      vertical: AppSpacing.md,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: HeatMapGrid(dailyCounts: stats.dailyCounts),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenEdge,
                      0,
                      AppSpacing.screenEdge,
                      0,
                    ),
                    sliver: const SliverToBoxAdapter(
                      child: _SelectedDayDetailCard(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenEdge,
                      AppSpacing.md,
                      AppSpacing.screenEdge,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Last 7 Days',
                          style: AppTypography.titleMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final day = stats.dailyBreakdown[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenEdge,
                          AppSpacing.md,
                          AppSpacing.screenEdge,
                          0,
                        ),
                        child: _DayTimelineCard(day: day),
                      );
                    }, childCount: stats.dailyBreakdown.take(7).length),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenEdge,
                      AppSpacing.lg,
                      AppSpacing.screenEdge,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Recent Reactions',
                          style: AppTypography.titleMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = stats.reviewTimeline[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenEdge,
                          AppSpacing.md,
                          AppSpacing.screenEdge,
                          0,
                        ),
                        child: _TimelineEntryTile(entry: entry),
                      );
                    }, childCount: stats.reviewTimeline.take(24).length),
                  ),
                ],

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatsHeroCard extends StatelessWidget {
  const _StatsHeroCard({required this.mode, required this.stats});

  final _StatsMode mode;
  final StatsBundle stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final headline = mode == _StatsMode.card
        ? '${stats.cardStats.length}'
        : '${stats.currentStreak}';
    final title = mode == _StatsMode.card ? 'Tracked Cards' : 'Day Streak';
    final subtitle = mode == _StatsMode.card
        ? '${(stats.overallRetention * 100).round()}% retention across your review history'
        : '${stats.dailyBreakdown.where((day) => day.reviewCount > 0).length} active days in the last 30';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.panel(
        context,
        raised: true,
        focused: true,
        radius: AppRadius.lg,
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            headline,
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CardStatTile extends StatelessWidget {
  const _CardStatTile({required this.item});

  final CardReviewStats item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.panel(
        context,
        radius: AppRadius.md,
        raised: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.isDeleted) ...[
                      const SizedBox(height: 6),
                      _DeletedBadge(label: 'Deleted'),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      '${item.entityType == 'combo' ? 'Combo' : 'Move'} · ${item.category}',
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.shownCount} shown',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(item.successRatio * 100).round()}%',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              if (item.firstReviewedAt != null)
                Text(
                  'First seen ${DateFormat('MMM d, HH:mm').format(item.firstReviewedAt!.toLocal())}',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              if (item.lastReviewedAt != null)
                Text(
                  'Last seen ${DateFormat('MMM d, HH:mm').format(item.lastReviewedAt!.toLocal())}',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: Row(
              children: [
                _RatioBar(color: AppColors.actionAgain, flex: item.againCount),
                _RatioBar(color: AppColors.actionHard, flex: item.hardCount),
                _RatioBar(color: AppColors.actionGood, flex: item.goodCount),
                _RatioBar(color: AppColors.actionEasy, flex: item.easyCount),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Again ${item.againCount} · Hard ${item.hardCount} · Good ${item.goodCount} · Easy ${item.easyCount}',
            style: AppTypography.caption.copyWith(color: colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}

class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.color, required this.flex});

  final Color color;
  final int flex;

  @override
  Widget build(BuildContext context) {
    if (flex <= 0) {
      return const SizedBox.shrink();
    }

    return Expanded(
      flex: flex,
      child: Container(height: 8, color: color),
    );
  }
}

class _DayTimelineCard extends StatelessWidget {
  const _DayTimelineCard({required this.day});

  final DayStats day;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.panel(context, radius: AppRadius.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, MMM d').format(day.date),
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.reviewCount} reviews · ${(day.accuracy * 100).round()}% solid recalls',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${day.goodCount + day.easyCount}/${day.reviewCount}',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntryTile extends StatelessWidget {
  const _TimelineEntryTile({required this.entry});

  final ReviewTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratingColor = switch (entry.rating) {
      'AGAIN' => AppColors.actionAgain,
      'HARD' => AppColors.actionHard,
      'GOOD' => AppColors.actionGood,
      'EASY' => AppColors.actionEasy,
      _ => colorScheme.secondary,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.panel(context, radius: AppRadius.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: ratingColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (entry.isDeleted) ...[
                  const SizedBox(height: 6),
                  _DeletedBadge(label: 'Deleted'),
                ],
                const SizedBox(height: 2),
                Text(
                  entry.graduated
                      ? '${entry.rating} · graduated into review'
                      : '${entry.rating} · ${entry.isDeleted
                            ? 'deleted ${entry.entityType}'
                            : entry.entityType == 'combo'
                            ? 'combo'
                            : entry.category}',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM d, HH:mm').format(entry.reviewedAt.toLocal()),
            style: AppTypography.caption.copyWith(color: colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}

class _SelectedDayDetailCard extends ConsumerWidget {
  const _SelectedDayDetailCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDate = ref.watch(selectedDateProvider);
    final detailAsync = ref.watch(dayDetailProvider(selectedDate));

    return detailAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppSurfaces.panel(context, radius: AppRadius.md),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppSurfaces.panel(context, radius: AppRadius.md),
        child: Text(
          'Could not load ${DateFormat('MMM d').format(selectedDate)}: $error',
          style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary),
        ),
      ),
      data: (items) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppSurfaces.panel(context, radius: AppRadius.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(selectedDate),
                style: AppTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                items.isEmpty
                    ? 'No reviews captured on this date.'
                    : '${items.length} timestamped review event${items.length == 1 ? '' : 's'}',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                for (final item in items.take(8)) ...[
                  _SelectedDayEntry(item: item),
                  if (item != items.take(8).last)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SelectedDayEntry extends StatelessWidget {
  const _SelectedDayEntry({required this.item});

  final DayMoveReview item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratingColor = switch (item.rating) {
      'AGAIN' => AppColors.actionAgain,
      'HARD' => AppColors.actionHard,
      'GOOD' => AppColors.actionGood,
      'EASY' => AppColors.actionEasy,
      _ => colorScheme.secondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: AppSurfaces.panel(context, radius: AppRadius.sm),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: ratingColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.moveName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.isDeleted) ...[
                  const SizedBox(height: 6),
                  _DeletedBadge(label: 'Deleted ${item.entityType}'),
                ],
                const SizedBox(height: 2),
                Text(
                  '${item.rating} · ${item.category}',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(item.reviewedAt.toLocal()),
            style: AppTypography.caption.copyWith(color: colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}

class _DeletedBadge extends StatelessWidget {
  const _DeletedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppSurfaces.panel(context, radius: AppRadius.xs),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: colorScheme.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ShareButton extends StatefulWidget {
  const _ShareButton({required this.stats});

  final StatsBundle stats;

  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<_ShareButton> {
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final summary = StatsExportService.generateTextSummary(widget.stats);
      await Share.share(summary);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _sharing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share, size: 22),
      tooltip: 'Share Stats',
      onPressed: _sharing ? null : _share,
    );
  }
}
