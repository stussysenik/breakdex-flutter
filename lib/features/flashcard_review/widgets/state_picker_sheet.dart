import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';

/// Bottom sheet for manually overriding a move's learning state.
class StatePickerSheet extends ConsumerWidget {
  const StatePickerSheet({
    super.key,
    required this.currentState,
    required this.moveName,
  });

  final LearningState currentState;
  final String moveName;

  static Future<LearningState?> show(
    BuildContext context, {
    required LearningState currentState,
    required String moveName,
  }) {
    return showModalBottomSheet<LearningState>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) =>
          StatePickerSheet(currentState: currentState, moveName: moveName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final labels = ref.watch(learningStateLabelsProvider);

    const descriptions = {
      LearningState.newState: 'Start fresh — reset progress',
      LearningState.learning: 'In progress — needs practice',
      LearningState.mastery: 'Nailed it — fully learned',
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.lg,
          AppSpacing.screenEdge,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set State',
              style: AppTypography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              moveName,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final state in LearningState.values) ...[
              _StateOption(
                label: resolveLearningStateLabel(labels, state),
                state: state,
                description: descriptions[state] ?? '',
                isCurrent: state == currentState,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, state);
                },
              ),
              if (state != LearningState.values.last)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _StateOption extends StatelessWidget {
  const _StateOption({
    required this.state,
    required this.label,
    required this.description,
    required this.isCurrent,
    required this.onTap,
  });

  final LearningState state;
  final String label;
  final String description;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stateColor = AppSemanticTheme.of(context).colorForState(state);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isCurrent
              ? stateColor.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isCurrent
              ? Border.all(color: stateColor.withValues(alpha: 0.4), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: stateColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Icon(Icons.check_circle, color: stateColor, size: 20),
          ],
        ),
      ),
    );
  }
}
