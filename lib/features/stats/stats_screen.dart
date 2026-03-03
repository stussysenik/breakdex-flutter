import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/services/stats_export_service.dart';
import 'providers/stats_providers.dart';
import 'widgets/heat_map_grid.dart';
import 'widgets/stat_card.dart';
import 'widgets/streak_card.dart';
import 'widgets/rating_distribution_bar.dart';
import 'widgets/top_moves_list.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsBundleProvider);
    return Scaffold(
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (stats) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge, AppSpacing.lg, AppSpacing.screenEdge, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Stats',
                          style: AppTypography.titleLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      _ShareButton(stats: stats),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge, vertical: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: StreakCard(streak: stats.currentStreak),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                            label: 'Total', value: stats.totalReviews),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                            label: 'Week', value: stats.reviewsThisWeek),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                            label: 'Month', value: stats.reviewsThisMonth),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge, AppSpacing.lg, AppSpacing.screenEdge, 0),
                sliver: SliverToBoxAdapter(
                  child: Semantics(
                    header: true,
                    child: Text('Activity',
                        style: AppTypography.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge, vertical: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: HeatMapGrid(dailyCounts: stats.dailyCounts),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge, AppSpacing.sm, AppSpacing.screenEdge, 0),
                sliver: SliverToBoxAdapter(
                  child: Semantics(
                    header: true,
                    child: Text('Rating Distribution',
                        style: AppTypography.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge, vertical: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: RatingDistributionBar(
                      distribution: stats.ratingDistribution),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge, AppSpacing.sm, AppSpacing.screenEdge, 0),
                sliver: SliverToBoxAdapter(
                  child: Semantics(
                    header: true,
                    child: Text('Most Practiced',
                        style: AppTypography.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge, AppSpacing.md, AppSpacing.screenEdge, 0),
                sliver: SliverToBoxAdapter(
                  child: TopMovesList(
                    topMoveEntries: stats.topMoveEntries,
                    allMoves: stats.allMoves,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge, AppSpacing.lg, AppSpacing.screenEdge, AppSpacing.xl),
                sliver: SliverToBoxAdapter(
                  child: _BattleCard(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push('/battle');
                    },
                  ),
                ),
              ),
            ],
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
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

class _BattleCard extends StatelessWidget {
  const _BattleCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Battle Mode',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Timed speed-review challenge',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.secondary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.secondary),
          ],
        ),
      ),
    );
  }
}
