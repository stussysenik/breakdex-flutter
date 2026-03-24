import 'package:flutter/material.dart';

import '../../../core/database/database.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';

/// Reusable lab card widget used in both list and board views.
///
/// Displays a lab's name, status pill, optional progress indicator, and
/// time metadata. The [compact] flag produces a smaller card for the
/// kanban board columns where horizontal space is limited.
class LabCard extends StatelessWidget {
  const LabCard({
    super.key,
    required this.lab,
    this.compact = false,
    this.onTap,
  });

  final Lab lab;

  /// When true, renders a narrower card for board columns (name + status only).
  final bool compact;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (compact) {
      return _buildCompactCard(context, colorScheme);
    }
    return _buildFullCard(context, colorScheme);
  }

  /// Full card for list view — name, status pill, progress bar, metadata.
  Widget _buildFullCard(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppSurfaces.panel(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: name + status pill
            Row(
              children: [
                Expanded(
                  child: Text(
                    lab.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusPill(status: lab.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Progress bar — visual representation of lab status
            _LabProgressBar(status: lab.status),
            const SizedBox(height: AppSpacing.sm),

            // Metadata row: type + time
            Row(
              children: [
                Icon(
                  lab.labType == 'set'
                      ? Icons.playlist_play_rounded
                      : Icons.science_outlined,
                  size: 14,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  lab.labType == 'set' ? 'Set' : 'Project',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(lab.updatedAt),
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Compact card for board columns — name + status only.
  Widget _buildCompactCard(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 4,
          vertical: AppSpacing.sm,
        ),
        decoration: AppSurfaces.panel(context, radius: AppRadius.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lab.name,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              lab.labType == 'set' ? 'Set' : 'Project',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Human-readable relative time string for card metadata.
  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

// -- Status Pill --------------------------------------------------------------

/// Color-coded pill showing a lab's current status (idea, attempting, landed,
/// clean). Mirrors the [StatePill] pattern used for FSRS learning states.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusMeta(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  static (String, Color) _statusMeta(String status) => switch (status) {
        'idea' => ('Idea', const Color(0xFFA7B1C2)),
        'attempting' => ('Attempting', AppColors.stateLearning),
        'landed' => ('Landed', AppColors.stateMastery),
        'clean' => ('Clean', const Color(0xFF0D9F9A)),
        _ => ('Idea', const Color(0xFFA7B1C2)),
      };
}

// -- Progress Bar -------------------------------------------------------------

/// Linear progress indicator derived from the lab status.
///
/// Maps the 4-stage status to a 0.0–1.0 progress value:
/// idea=0.1, attempting=0.4, landed=0.75, clean=1.0.
class _LabProgressBar extends StatelessWidget {
  const _LabProgressBar({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (_, color) = _StatusPill._statusMeta(status);
    final progress = _progressForStatus(status);

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }

  static double _progressForStatus(String status) => switch (status) {
        'idea' => 0.1,
        'attempting' => 0.4,
        'landed' => 0.75,
        'clean' => 1.0,
        _ => 0.1,
      };
}
