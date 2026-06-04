import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';

/// Bottom sheet for manually overriding a move's learning state.
///
/// In default mode, shows the 3 built-in states (renamable).
/// In custom mode, shows built-in + user-defined custom states.
class StatePickerSheet extends ConsumerWidget {
  const StatePickerSheet({
    super.key,
    required this.currentState,
    required this.moveName,
    this.onSelected,
  });

  final LearningState currentState;
  final String moveName;
  final ValueChanged<LearningState>? onSelected;

  static Future<LearningState?> show(
    final BuildContext context, {
    required final LearningState currentState,
    required final String moveName,
  }) {
    return showModalBottomSheet<LearningState>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Sharp corners for brutalist feel
      ),
      builder: (_) =>
          StatePickerSheet(currentState: currentState, moveName: moveName),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final labels = ref.watch(learningStateLabelsProvider);
    final mode = ref.watch(learningModeProvider);
    final customStates = ref.watch(customLearningStatesProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MOVE STATE'.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontFamily: 'Menlo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  moveName.toUpperCase(),
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Menlo',
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          for (final state in LearningState.values)
            _StateOption(
              label: resolveLearningStateLabel(labels, state).toUpperCase(),
              state: state,
              isCurrent: state == currentState,
              onTap: () {
                HapticFeedback.mediumImpact();
                if (onSelected != null) {
                  onSelected!(state);
                } else {
                  Navigator.pop(context, state);
                }
              },
            ),

          if (mode == LearningMode.custom) ...[
            for (final custom in customStates)
              _StateOption(
                label: custom.label.toUpperCase(),
                state: LearningState.mastery,
                customColor: custom.color,
                isCurrent: false,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (onSelected != null) {
                    onSelected!(LearningState.mastery);
                  } else {
                    Navigator.pop(context, LearningState.mastery);
                  }
                },
              ),
          ],
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _StateOption extends StatelessWidget {
  const _StateOption({
    required this.state,
    required this.label,
    required this.isCurrent,
    required this.onTap,
    this.customColor,
  });

  final LearningState state;
  final String label;
  final bool isCurrent;
  final VoidCallback onTap;
  final Color? customColor;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stateColor = customColor ?? context.stateColor(state);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              color: stateColor,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: 1.0,
                  fontFamily: 'Menlo',
                  color: isCurrent ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: stateColor),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  'CURRENT',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Menlo',
                    fontSize: 10,
                    color: stateColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

