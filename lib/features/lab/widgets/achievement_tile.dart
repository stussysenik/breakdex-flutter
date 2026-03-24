import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';

/// A single tile in the Achievement Garden grid.
///
/// Shows the tier icon (emoji), move name, and a subtle background tint
/// derived from the tier color. Tap navigates to the move detail screen.
///
/// Icon mapping follows the botanical growth metaphor:
///   Seed       → stone (dormant potential)
///   Sprouting  → seedling (first sign of growth)
///   Growing    → herb (active development)
///   Mastered   → gem (polished mastery)
class AchievementTile extends StatelessWidget {
  const AchievementTile({
    super.key,
    required this.moveId,
    required this.moveName,
    required this.tier,
  });

  final String moveId;
  final String moveName;
  final String tier;

  /// Tier-to-emoji mapping. Each emoji signals progress at a glance.
  static String tierIcon(String tier) => switch (tier) {
        'mastered' => '\u{1F48E}', // 💎
        'growing' => '\u{1F33F}', // 🌿
        'sprouting' => '\u{1F331}', // 🌱
        _ => '\u{1FAA8}', // 🪨
      };

  /// Semantic color for each tier — used for tint and summary chips.
  ///
  /// Colors are drawn from the existing AppColors palette:
  ///   Mastered  → stateMastery (green, achievement)
  ///   Growing   → stateLearning (blue, active progress)
  ///   Sprouting → actionGood (green, positive signal)
  ///   Seed      → secondary grey (neutral, dormant)
  static Color tierColor(String tier) => switch (tier) {
        'mastered' => AppColors.stateMastery,
        'growing' => AppColors.stateLearning,
        'sprouting' => AppColors.actionGood,
        _ => const Color(0xFF8892A4), // Neutral grey for seed
      };

  @override
  Widget build(BuildContext context) {
    final color = tierColor(tier);
    final icon = tierIcon(tier);

    return GestureDetector(
      onTap: () => context.push('/arsenal/move/$moveId'),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tier icon — large enough to be scannable in a 4-column grid
            Text(
              icon,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Move name — truncated to 2 lines max
            Text(
              moveName,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
