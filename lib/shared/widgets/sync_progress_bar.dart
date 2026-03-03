import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/colors.dart';
import '../../core/design/typography.dart';
import '../../core/models/sync_progress.dart';
import '../../core/providers.dart';

class SyncProgressBar extends ConsumerWidget {
  const SyncProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(syncProgressProvider);

    return progressAsync.when(
      data: (progress) {
        if (progress.phase == SyncPhase.complete ||
            progress.phase == SyncPhase.error) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppColors.accent.withValues(alpha: 0.1),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      progress.label,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress.bytesProgress ?? progress.fraction,
                        minHeight: 3,
                        backgroundColor:
                            AppColors.accent.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
