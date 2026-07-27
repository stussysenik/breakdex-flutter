import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/settings_list_group.dart';

class ReviewCardDisplaySection extends ConsumerWidget {
  const ReviewCardDisplaySection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settings = ref.watch(reviewCardDisplaySettingsProvider);
    final notifier = ref.read(reviewCardDisplaySettingsProvider.notifier);
    final silentPractice = ref.watch(silentPracticePlaybackProvider);
    final silentPracticeNotifier = ref.read(
      silentPracticePlaybackProvider.notifier,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final entries = [
      _ReviewCardToggle(
        title: l10n.setViewKeepMusicTitle,
        subtitle: l10n.setViewKeepMusicSubtitle,
        value: silentPractice,
        onChanged: ({required final value}) => silentPracticeNotifier.setEnabled(value: value),
      ),
      _ReviewCardToggle(
        title: l10n.setViewTitleTitle,
        subtitle: l10n.setViewTitleSubtitle,
        value: settings.showTitle,
        onChanged: ({required final value}) => notifier.setShowTitle(value: value),
      ),
      _ReviewCardToggle(
        title: l10n.setViewStatePillTitle,
        subtitle: l10n.setViewStatePillSubtitle,
        value: settings.showState,
        onChanged: ({required final value}) => notifier.setShowState(value: value),
      ),
      _ReviewCardToggle(
        title: l10n.setViewCategoryTitle,
        subtitle: l10n.setViewCategorySubtitle,
        value: settings.showCategory,
        onChanged: ({required final value}) => notifier.setShowCategory(value: value),
      ),
      _ReviewCardToggle(
        title: l10n.setViewComboTimelineTitle,
        subtitle: l10n.setViewComboTimelineSubtitle,
        value: settings.showComboTimeline,
        onChanged: ({required final value}) => notifier.setShowComboTimeline(value: value),
      ),
      _ReviewCardToggle(
        title: l10n.setViewStepLabelTitle,
        subtitle: l10n.setViewStepLabelSubtitle,
        value: settings.showComboStepName,
        onChanged: ({required final value}) => notifier.setShowComboStepName(value: value),
      ),
      _ReviewCardToggle(
        title: l10n.setViewPlaybackControlsTitle,
        subtitle: l10n.setViewPlaybackControlsSubtitle,
        value: settings.showPlaybackControls,
        onChanged: ({required final value}) =>
            notifier.setShowPlaybackControls(value: value),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.setViewComposerTitle,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.setViewComposerSubtitle,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
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
  final Future<void> Function({required bool value}) onChanged;
}

class _ReviewCardToggleTile extends StatelessWidget {
  const _ReviewCardToggleTile({required this.entry});

  final _ReviewCardToggle entry;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => unawaited(entry.onChanged(value: !entry.value)),
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
                onChanged: (final value) => unawaited(entry.onChanged(value: value)),
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
