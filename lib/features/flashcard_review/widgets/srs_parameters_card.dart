import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';

/// Displays the active FSRS algorithm configuration so learners can see
/// exactly how their reviews are being scheduled.
///
/// Shows: retention target, learning steps, relearning steps, max interval,
/// the forgetting curve formula, and fuzzing status. This transparency
/// builds trust — the learner knows *why* a review is scheduled when it is.
class SrsParametersCard extends ConsumerWidget {
  const SrsParametersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(fsrsConfigProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.tune, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'FSRS Parameters',
                style: AppTypography.caption.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Parameters grid
          _ParamRow(
            label: 'Retention',
            value: '${(config.desiredRetention * 100).round()}%',
            icon: Icons.psychology,
          ),
          _ParamRow(
            label: 'Learning',
            value: config.learningSteps
                .map((d) => _formatDuration(d))
                .join(' → '),
            icon: Icons.school,
          ),
          _ParamRow(
            label: 'Relearning',
            value: config.relearningSteps
                .map((d) => _formatDuration(d))
                .join(' → '),
            icon: Icons.replay,
          ),
          _ParamRow(
            label: 'Max interval',
            value: '${(config.maximumInterval / 365).round()} years',
            icon: Icons.calendar_month,
          ),
          _ParamRow(
            label: 'Fuzzing',
            value: config.enableFuzzing ? 'ON' : 'OFF',
            icon: Icons.shuffle,
          ),

          const SizedBox(height: AppSpacing.sm),
          Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.sm),

          // Forgetting curve formula
          Text(
            'Forgetting curve',
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
              'R(t) = (1 + t / (9 \u00b7 S))\u207b\u00b9',
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
            't = days elapsed, S = stability',
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

  static String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }
}

class _ParamRow extends StatelessWidget {
  const _ParamRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
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
      ),
    );
  }
}
