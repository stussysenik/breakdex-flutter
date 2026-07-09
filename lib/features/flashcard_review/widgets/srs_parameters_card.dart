// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/fsrs_settings.dart';
import '../../../core/providers.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Editable FSRS scheduling controls.
///
/// Lets the learner tune the global scheduler — retention, maximum interval,
/// fuzzing, and learning/relearning steps — directly from the schedule surface.
/// Every edit flows through [fsrsSettingsProvider] (clamped, persisted to
/// SharedPreferences) and the card reflects the live persisted values.
///
/// State note: the retention slider keeps a local *draft* while the user is
/// dragging so the thumb tracks the finger smoothly; it commits to the notifier
/// on release. Everything else reflects the persisted config directly, so the
/// UI is never showing a value the scheduler isn't actually using.
class SrsParametersCard extends ConsumerStatefulWidget {
  const SrsParametersCard({super.key});

  @override
  ConsumerState<SrsParametersCard> createState() => _SrsParametersCardState();
}

class _SrsParametersCardState extends ConsumerState<SrsParametersCard> {
  /// Non-null only while the retention slider is being dragged.
  double? _retentionDraft;

  static const _maxIntervalPresets = <String, int>{
    '1y': 365,
    '5y': 1825,
    '100y': 36500,
  };

  static const _stepPresets = <String, List<Duration>>{
    'None': [],
    '10m': [Duration(minutes: 10)],
    '1m · 10m': [Duration(minutes: 1), Duration(minutes: 10)],
    '10m · 1d': [Duration(minutes: 10), Duration(days: 1)],
  };

  @override
  Widget build(final BuildContext context) {
    final config = ref.watch(fsrsConfigProvider);
    final notifier = ref.read(fsrsSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final retention = _retentionDraft ?? config.desiredRetention;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + reset
          Row(
            children: [
              Icon(Icons.tune, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                l10n.revFsrsParameters,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() => _retentionDraft = null);
                  notifier.resetToDefaults();
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.revReset,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Retention — the highest-leverage knob.
          _ControlLabel(
            icon: Icons.psychology,
            label: l10n.revRetention,
            value: '${(retention * 100).round()}%',
          ),
          Slider(
            value: retention.clamp(
              FsrsSettings.minRetention,
              FsrsSettings.maxRetention,
            ),
            min: FsrsSettings.minRetention,
            max: FsrsSettings.maxRetention,
            divisions:
                ((FsrsSettings.maxRetention - FsrsSettings.minRetention) * 100)
                    .round(),
            label: '${(retention * 100).round()}%',
            onChanged: (final v) => setState(() => _retentionDraft = v),
            onChangeEnd: (final v) {
              setState(() => _retentionDraft = null);
              notifier.setDesiredRetention(v);
            },
          ),
          Text(
            l10n.revRetentionHint,
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Maximum interval presets.
          _ControlLabel(
            icon: Icons.calendar_month,
            label: l10n.revMaxInterval,
            value: _formatMaxInterval(config.maximumInterval),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.xs,
            children: _maxIntervalPresets.entries.map((final e) {
              return ChoiceChip(
                label: Text(e.key),
                selected: config.maximumInterval == e.value,
                onSelected: (_) => notifier.setMaximumInterval(e.value),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Fuzzing.
          Row(
            children: [
              Icon(Icons.shuffle, size: 14, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.revFuzzing,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ),
              Switch(
                value: config.enableFuzzing,
                onChanged: (final v) => notifier.setFuzzing(enabled: v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Learning / relearning step presets.
          _StepPresetRow(
            icon: Icons.school,
            label: l10n.revLearning,
            presets: _stepPresets,
            current: config.learningSteps,
            onSelected: notifier.setLearningSteps,
          ),
          const SizedBox(height: AppSpacing.xs),
          _StepPresetRow(
            icon: Icons.replay,
            label: l10n.revRelearning,
            presets: _stepPresets,
            current: config.relearningSteps,
            onSelected: notifier.setRelearningSteps,
          ),

          const SizedBox(height: AppSpacing.sm),
          Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.sm),

          // Forgetting curve formula (unchanged — explanatory).
          Text(
            l10n.revForgettingCurve,
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              'R(t) = (1 + t / (9 · S))⁻¹',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.revForgettingCurveLegend,
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _formatMaxInterval(final int days) {
    if (days % 365 == 0) return '${days ~/ 365}y';
    return '${days}d';
  }
}

/// A label row: icon + name on the left, current value on the right.
class _ControlLabel extends StatelessWidget {
  const _ControlLabel({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: colorScheme.secondary),
          ),
        ),
        Text(
          value,
          style: AppTypography.caption.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Label + a wrap of step-list presets; the one matching [current] is selected.
class _StepPresetRow extends StatelessWidget {
  const _StepPresetRow({
    required this.icon,
    required this.label,
    required this.presets,
    required this.current,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final Map<String, List<Duration>> presets;
  final List<Duration> current;
  final ValueChanged<List<Duration>> onSelected;

  bool _matches(final List<Duration> a, final List<Duration> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: colorScheme.secondary),
            const SizedBox(width: 8),
            Text(
              label,
              style:
                  AppTypography.caption.copyWith(color: colorScheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: AppSpacing.xs,
          children: presets.entries.map((final e) {
            return ChoiceChip(
              label: Text(e.key),
              selected: _matches(current, e.value),
              onSelected: (_) => onSelected(e.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
