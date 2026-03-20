import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';

/// Lightweight dot progress indicator for the immersive review overlay.
///
/// Shows a row of small dots (5px) — filled for completed, hollow for
/// remaining. When total > 12, collapses to first 5 dots + counter + last 5
/// to stay compact. Designed for overlay on dark video backgrounds.
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.currentIndex,
    required this.total,
  });

  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    if (total > 12) {
      final showCount = math.min(5, total);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < showCount; i++) _dot(i <= currentIndex),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${currentIndex + 1}/$total',
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
              ),
            ),
          ),
          for (int i = total - showCount; i < total; i++)
            _dot(i <= currentIndex),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < total; i++) _dot(i <= currentIndex),
      ],
    );
  }

  Widget _dot(bool filled) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.25),
      ),
    );
  }
}

/// Minimal in-session dashboard — progress bar + counter only.
///
/// All filter/session-size controls live on the [MasteryPrescreen] now,
/// keeping the review flow distraction-free.
class ReviewDashboard extends ConsumerWidget {
  const ReviewDashboard({
    super.key,
    required this.currentIndex,
    required this.totalInSession,
    this.sessionLabel,
  });

  final int currentIndex;
  final int totalInSession;
  final String? sessionLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (totalInSession <= 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          if (sessionLabel != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                sessionLabel!,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalInSession > 0
                        ? (currentIndex + 1) / totalInSession
                        : 0,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: Theme.of(context).colorScheme.primary,
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${currentIndex + 1}/$totalInSession',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
