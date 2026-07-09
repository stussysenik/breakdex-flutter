import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/app_loader.dart';
import '../providers/achievement_providers.dart';
import 'achievement_tile.dart';

/// A data-dense grid showing every move's achievement tier.
///
/// Designed as a standalone widget that can be dropped into any screen
/// (Lab tab, Stats tab, profile). Follows Tufte's principle of maximizing
/// the data-ink ratio — no decorative chrome, just the garden.
///
/// Layout: 4-column grid, sorted mastered-first. A summary header shows
/// tier counts at a glance: "4 Mastered · 8 Growing · 12 Sprouting · 6 Seed".
class AchievementGarden extends ConsumerWidget {
  const AchievementGarden({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final gardenAsync = ref.watch(achievementGardenProvider);

    return gardenAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (final e, _) => Center(
        child: Text('Error loading garden: $e',
            style: AppTypography.bodySmall),
      ),
      data: (final garden) {
        if (garden.entries.isEmpty) {
          return _buildEmpty(context);
        }
        return _buildGarden(context, garden);
      },
    );
  }

  Widget _buildEmpty(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.park_outlined,
            size: 64,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your garden is empty',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add moves to start growing',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarden(final BuildContext context, final GardenSummary garden) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary header — compact tier counts
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          child: _SummaryHeader(garden: garden),
        ),
        const SizedBox(height: AppSpacing.md),

        // Grid of achievement tiles
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.8,
            ),
            itemCount: garden.entries.length,
            itemBuilder: (final context, final index) {
              final entry = garden.entries[index];
              return AchievementTile(
                moveId: entry.moveId,
                moveName: entry.moveName,
                tier: entry.tier,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact summary: "4 Mastered · 8 Growing · 12 Sprouting · 6 Seed"
///
/// Uses the tier's semantic color at reduced opacity for each count label.
/// Interpunct (·) separators keep it scannable without visual noise.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.garden});

  final GardenSummary garden;

  @override
  Widget build(final BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        if (garden.mastered > 0)
          _TierChip(
            count: garden.mastered,
            label: 'Mastered',
            color: AchievementTile.tierColor('mastered'),
          ),
        if (garden.growing > 0)
          _TierChip(
            count: garden.growing,
            label: 'Growing',
            color: AchievementTile.tierColor('growing'),
          ),
        if (garden.sprouting > 0)
          _TierChip(
            count: garden.sprouting,
            label: 'Sprouting',
            color: AchievementTile.tierColor('sprouting'),
          ),
        if (garden.seed > 0)
          _TierChip(
            count: garden.seed,
            label: 'Seed',
            color: AchievementTile.tierColor('seed'),
          ),
      ],
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '$count $label',
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
