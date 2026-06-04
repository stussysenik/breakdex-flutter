import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/state_machines/sync/sync_bloc.dart';

class SyncProgressBar extends ConsumerWidget {
  const SyncProgressBar({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final stateAsync = ref.watch(syncStateProvider);

    return stateAsync.when(
      data: (final state) {
        return state.maybeWhen(
          idle: () => const SizedBox.shrink(),
          complete: () => const SizedBox.shrink(),
          error: (_) => const SizedBox.shrink(),
          authenticating: () => _buildBar(context, 'Authenticating...', null),
          pushingMetadata: (final current, final total, final desc) {
            final progress = total > 0 ? current / total : null;
            return _buildBar(context, 'Syncing metadata ($desc)', progress);
          },
          uploadingVideos: (final current, final total, final desc) {
            final progress = total > 0 ? current / total : null;
            return _buildBar(context, 'Uploading videos ($desc)', progress);
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBar(final BuildContext context, final String label, final double? progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
