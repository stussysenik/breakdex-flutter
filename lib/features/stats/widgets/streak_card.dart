import 'package:flutter/material.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.actionGood.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: AppColors.actionGood, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak day${streak == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  streak > 0 ? 'Current streak' : 'Start practicing!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.secondary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
