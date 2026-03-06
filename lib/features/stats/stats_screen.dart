import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/services/stats_export_service.dart';
import 'providers/stats_providers.dart';
import 'widgets/heat_map_grid.dart';
import 'widgets/stat_card.dart';
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
              // 1. Title + share button
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

              // 2. Stat cards row — Retention / Reviews / Moves
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge, vertical: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Retention',
                          value: '${(stats.overallRetention * 100).round()}%',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                          label: 'Reviews',
                          value: '${stats.ratingDistribution.values.fold(0, (a, b) => a + b)}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                          label: 'Moves',
                          value: '${stats.allMoves.length}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Activity heatmap
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge, AppSpacing.md, AppSpacing.screenEdge, 0),
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

              // 4. Most Practiced — hidden when empty
              SliverToBoxAdapter(
                child: _ConditionalSection(
                  visible: stats.topMoves.isNotEmpty,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenEdge, AppSpacing.lg, AppSpacing.screenEdge, 0),
                        child: Semantics(
                          header: true,
                          child: Text('Most Practiced',
                              style: AppTypography.titleMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenEdge, AppSpacing.md, AppSpacing.screenEdge, 0),
                        child: TopMovesList(topMoves: stats.topMoves),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }
}


/// Wraps a section in [AnimatedSize] + [AnimatedOpacity] so it smoothly
/// collapses/appears when [visible] toggles. Prevents empty sections from
/// occupying screen space and adding visual noise.
class _ConditionalSection extends StatelessWidget {
  const _ConditionalSection({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.moderate02,
      curve: AppMotion.productive,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: AppMotion.moderate01,
        child: visible ? child : const SizedBox.shrink(),
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
