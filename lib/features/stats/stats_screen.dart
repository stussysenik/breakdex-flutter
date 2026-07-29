import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/features/stats/providers/stats_providers.dart';
import 'package:breakdex/features/stats/widgets/practice_calendar_view.dart';
import 'package:breakdex/core/utils/diagnostics.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    DiagnosticsLog.info('StatsScreen', 'Building StatsScreen');
    final statsAsync = ref.watch(statsBundleProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // The header band is the app's, not this screen's: the floating
    // `SliverAppBar` and its Menlo-w900 title override were why STATISTICS
    // scrolled away and sat at a different height than every other screen.
    // The brutalist voice stays where it belongs — inside the content band,
    // which is the band the constitution lets a screen own.
    return AppScreen.slivers(
      title: 'Statistics',
      slivers: statsAsync.when(
        loading: () => const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: AppLoader()),
          ),
        ],
        error: (final error, _) => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Error: $error')),
          ),
        ],
        data: (final stats) {
          final activeDays = stats.dailyBreakdown
              .where((final day) => day.reviewCount > 0)
              .length;

          return [
              SliverList(
                delegate: SliverChildListDelegate([
                    _StatRow(label: 'CURRENT STREAK', value: '${stats.currentStreak} DAYS'),
                    _StatRow(label: 'ACTIVE DAYS', value: '$activeDays TOTAL'),
                    _StatRow(label: 'TOTAL REVIEWS', value: '${stats.reviewTimeline.length} EVENTS'),
                    _StatRow(
                      label: 'RETENTION',
                      value: '${(stats.overallRetention * 100).toStringAsFixed(1)}%',
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    Text(
                      'PRACTICE CALENDAR'.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Menlo',
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const PracticeCalendarView(),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    Text(
                      'RECENT REACTION LOG'.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Menlo',
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                ]),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (final context, final index) {
                    final entry = stats.reviewTimeline[index];
                    return _BrutalistReactionTile(entry: entry);
                  },
                  childCount: stats.reviewTimeline.take(20).length,
                ),
              ),
          ];
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w700,
              fontFamily: 'Menlo',
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              fontFamily: 'Menlo',
            ),
          ),
        ],
      ),
    );
  }
}

class _BrutalistReactionTile extends StatelessWidget {
  const _BrutalistReactionTile({required this.entry});
  final ReviewTimelineEntry entry;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticTheme.of(context);
    final ratingColor = switch (entry.rating) {
      'AGAIN' => semantic.actionAgain,
      'HARD' => semantic.actionHard,
      'GOOD' => semantic.actionGood,
      'EASY' => semantic.actionEasy,
      _ => colorScheme.secondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 24, color: ratingColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName.toUpperCase(),
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Menlo',
                  ),
                ),
                Text(
                  '${entry.rating} · ${entry.category.toUpperCase()}',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontFamily: 'Menlo',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(entry.reviewedAt),
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontFamily: 'Menlo',
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(final DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'TODAY';
    }
    return '${dt.day}/${dt.month}';
  }
}
