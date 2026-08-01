// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/features/battle/providers/battle_providers.dart';
import 'package:breakdex/features/battle/widgets/battle_intro.dart';
import 'package:breakdex/features/battle/widgets/timer_ring.dart';
import 'package:breakdex/features/battle/widgets/battle_results_view.dart';
import 'package:breakdex/shared/widgets/app_dialog.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';

class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final state = ref.watch(battleProvider);

    // Joined the frame 2026-08-01 (§4.4 batch 2). `fill`, because a battle is
    // one screenful with a timer at the top and the rating row pinned at the
    // bottom — never a scroll. The close control it used to carry was really
    // two facts: a way back (the frame's, now) and a refusal to leave a battle
    // in progress (the screen's, declared once for the chevron and the system
    // back alike).
    return PopGuard(
      blocked: state.phase == BattlePhase.active,
      confirm: (final context) => _confirmForfeit(context, ref),
      child: AppScreen.fill(
        title: switch (state.phase) {
          BattlePhase.intro => 'Battle',
          BattlePhase.active => 'Score: ${state.score}',
          BattlePhase.results => 'Results',
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: AppScreen.bottomInsetOf(context)),
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
      ),
    );
  }
}

/// The price of leaving mid-battle, asked once and answered for every way out.
Future<bool> _confirmForfeit(
  final BuildContext context,
  final WidgetRef ref,
) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (final ctx) => AlertDialog(
      title: const Text('Forfeit battle?'),
      content: const Text('Your current score will be lost.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Continue'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Forfeit',
            style: TextStyle(color: AppSemanticTheme.of(context).actionAgain),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  ref.read(battleProvider.notifier).reset();
  return true;
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
                  color: AppSemanticTheme.of(context).actionGood,
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
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: cs.secondary),
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: cs.secondary),
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
                  color: AppSemanticTheme.of(context).actionAgain,
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
                  color: AppSemanticTheme.of(context).actionHard,
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
                  color: AppSemanticTheme.of(context).actionGood,
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
