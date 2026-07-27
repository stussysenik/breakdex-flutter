// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/features/battle/providers/battle_providers.dart';
import 'package:breakdex/features/battle/widgets/battle_intro.dart';
import 'package:breakdex/features/battle/widgets/timer_ring.dart';
import 'package:breakdex/features/battle/widgets/battle_results_view.dart';

class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final state = ref.watch(battleProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context, ref, state),
        ),
        title: state.phase == BattlePhase.active
            ? Text('Score: ${state.score}')
            : null,
      ),
      body: SafeArea(
        child: switch (state.phase) {
          BattlePhase.intro => BattleIntro(
              selectedDifficulty: state.difficulty,
              onSelectDifficulty: (final d) =>
                  ref.read(battleProvider.notifier).selectDifficulty(d),
              onStart: () => ref.read(battleProvider.notifier).start(),
            ),
          BattlePhase.active => _ActiveBattle(state: state),
          BattlePhase.results => BattleResultsView(
              state: state,
              onPlayAgain: () {
                ref.read(battleProvider.notifier).reset();
              },
              onDone: () {
                ref.read(battleProvider.notifier).reset();
                Navigator.of(context).pop();
              },
            ),
        },
      ),
    );
  }
}

Future<void> _handleClose(final BuildContext context, final WidgetRef ref, final BattleState state) async {
  if (state.phase == BattlePhase.active) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: const Text('Forfeit battle?'),
        content: const Text(
          'Your current score will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Forfeit',
              style: TextStyle(color: AppColors.actionAgain),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }
  if (context.mounted) {
    ref.read(battleProvider.notifier).reset();
    Navigator.of(context).pop();
  }
}

class _ActiveBattle extends ConsumerWidget {
  const _ActiveBattle({required this.state});

  final BattleState state;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final move = state.currentMove;
    if (move == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          // Timer ring
          TimerRing(
            timeRemaining: state.timeRemaining,
            totalTime: state.difficulty.duration.toDouble(),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Streak indicator
          if (state.streak >= 2)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                '${state.streak}x Streak!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.actionGood,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          // Move card
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      move.category,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.secondary,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      move.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '#${state.currentIndex + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.secondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Rating buttons
          Row(
            children: [
              Expanded(
                child: _RatingButton(
                  label: 'Again',
                  color: AppColors.actionAgain,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(battleProvider.notifier).rate('AGAIN');
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RatingButton(
                  label: 'Hard',
                  color: AppColors.actionHard,
                  foregroundColor: Colors.black,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(battleProvider.notifier).rate('HARD');
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RatingButton(
                  label: 'Good',
                  color: AppColors.actionGood,
                  foregroundColor: Colors.black,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(battleProvider.notifier).rate('GOOD');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.foregroundColor = Colors.white,
  });

  final String label;
  final Color color;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
