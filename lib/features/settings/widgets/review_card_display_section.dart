import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/settings_list_group.dart';

class ReviewCardDisplaySection extends ConsumerWidget {
  const ReviewCardDisplaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reviewCardDisplaySettingsProvider);
    final notifier = ref.read(reviewCardDisplaySettingsProvider.notifier);
    final silentPractice = ref.watch(silentPracticePlaybackProvider);
    final silentPracticeNotifier = ref.read(
      silentPracticePlaybackProvider.notifier,
    );

    final entries = [
      _ReviewCardToggle(
        title: 'Keep music playing',
        subtitle: 'Keep Breakdex clips muted so your music can keep playing.',
        value: silentPractice,
        onChanged: silentPracticeNotifier.setEnabled,
      ),
      _ReviewCardToggle(
        title: 'Title',
        subtitle: 'Show the move or combo name on the card.',
        value: settings.showTitle,
        onChanged: notifier.setShowTitle,
      ),
      _ReviewCardToggle(
        title: 'State pill',
        subtitle: 'Show the current NEW / LEARNING / MASTERY pill.',
        value: settings.showState,
        onChanged: notifier.setShowState,
      ),
      _ReviewCardToggle(
        title: 'Category',
        subtitle: 'Show move categories like TOPROCK or FOOTWORK.',
        value: settings.showCategory,
        onChanged: notifier.setShowCategory,
      ),
      _ReviewCardToggle(
        title: 'Combo timeline',
        subtitle: 'Show step navigation when reviewing combos.',
        value: settings.showComboTimeline,
        onChanged: notifier.setShowComboTimeline,
      ),
      _ReviewCardToggle(
        title: 'Step label',
        subtitle: 'Show the active combo step name under the timeline.',
        value: settings.showComboStepName,
        onChanged: notifier.setShowComboStepName,
      ),
      _ReviewCardToggle(
        title: 'Speed + loop controls',
        subtitle: 'Show loop and speed controls on the card.',
        value: settings.showPlaybackControls,
        onChanged: notifier.setShowPlaybackControls,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsListGroup(
          children: [
            for (final entry in entries) _ReviewCardToggleTile(entry: entry),
          ],
        ),
      ],
    );
  }
}

class _ReviewCardToggle {
  const _ReviewCardToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool value) onChanged;
}

class _ReviewCardToggleTile extends StatelessWidget {
  const _ReviewCardToggleTile({required this.entry});

  final _ReviewCardToggle entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => unawaited(entry.onChanged(!entry.value)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch.adaptive(
                value: entry.value,
                onChanged: (value) => unawaited(entry.onChanged(value)),
                activeThumbColor: colorScheme.primary,
                activeTrackColor: colorScheme.primary.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
