import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../providers/battle_providers.dart';

class BattleIntro extends StatelessWidget {
  const BattleIntro({
    super.key,
    required this.selectedDifficulty,
    required this.onSelectDifficulty,
    required this.onStart,
  });

  final BattleDifficulty selectedDifficulty;
  final ValueChanged<BattleDifficulty> onSelectDifficulty;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.bolt_rounded, size: 64, color: AppColors.accent),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              'Battle Mode',
              style: AppTypography.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Rate moves as fast as you can.\nGOOD streaks multiply your score!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.secondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final diff in BattleDifficulty.values) ...[
            _DifficultyCard(
              difficulty: diff,
              isSelected: diff == selectedDifficulty,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelectDifficulty(diff);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const Spacer(),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onStart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start Battle',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  final BattleDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.accent : cs.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '${difficulty.duration} seconds',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.secondary,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.accent, size: 24),
          ],
        ),
      ),
    );
  }
}
