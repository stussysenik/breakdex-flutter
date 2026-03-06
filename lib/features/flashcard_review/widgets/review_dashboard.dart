import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';

/// Minimal in-session dashboard — progress bar + counter only.
///
/// All filter/session-size controls live on the [MasteryPrescreen] now,
/// keeping the review flow distraction-free.
class ReviewDashboard extends ConsumerWidget {
  const ReviewDashboard({
    super.key,
    required this.currentIndex,
    required this.totalInSession,
  });

  final int currentIndex;
  final int totalInSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (totalInSession <= 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenEdge,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
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
                    color: AppColors.accent,
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
