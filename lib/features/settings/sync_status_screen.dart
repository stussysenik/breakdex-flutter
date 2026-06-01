import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/sync/asset_sync_engine.dart';

/// Sync status dashboard showing overall progress, active transfers,
/// and monthly data usage.
class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final syncProgress = ref.watch(assetSyncProgressProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final networkPolicy = ref.watch(networkPolicyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sync Status',
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        children: [
          // Overall status card
          _StatusCard(
            syncProgress: syncProgress.valueOrNull ?? SyncProgress.idle,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Network settings
          _SectionHeader(title: 'Network', colorScheme: colorScheme),
          const SizedBox(height: AppSpacing.sm),
          _SettingsTile(
            title: 'Sync on Mobile Data',
            subtitle: networkPolicy.syncOnMobileData
                ? 'Enabled (${networkPolicy.mobileDataCapMb} MB cap)'
                : 'WiFi only',
            trailing: Switch.adaptive(
              value: networkPolicy.syncOnMobileData,
              activeColor: AppColors.accent,
              onChanged: (final value) async {
                await networkPolicy.setSyncOnMobileData(enabled: value);
              },
            ),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Data usage
          _DataUsageCard(
            usedBytes: networkPolicy.mobileUsedBytesThisMonth(),
            capBytes: networkPolicy.mobileDataCapMb * 1024 * 1024,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick actions
          _SectionHeader(title: 'Actions', colorScheme: colorScheme),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.sync,
            title: 'Sync Now',
            subtitle: 'Upload pending videos to cloud',
            onTap: () {
              // Trigger immediate sync
              ref.read(backgroundSyncManagerProvider).triggerImmediate(
                    syncCallback: () => ref
                        .read(assetSyncEngineProvider)
                        .runSyncCycle(
                          ref
                              .read(connectivityServiceProvider)
                              .currentType,
                        ),
                  );
            },
            colorScheme: colorScheme,
          ),
          _ActionTile(
            icon: Icons.verified_outlined,
            title: 'Verify Integrity',
            subtitle: 'Re-hash local files to detect corruption',
            onTap: () async {
              final report =
                  await ref.read(integrityVerifierProvider).verify();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      report.allGood
                          ? 'All ${report.filesChecked} files verified OK'
                          : '${report.filesMismatched} mismatches, '
                              '${report.filesMissing} missing',
                    ),
                  ),
                );
              }
            },
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SyncProgress syncProgress;
  final ColorScheme colorScheme;

  const _StatusCard({
    required this.syncProgress,
    required this.colorScheme,
  });

  @override
  Widget build(final BuildContext context) {
    final isIdle = syncProgress.state == SyncEngineState.idle;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isIdle
              ? AppColors.stateMastery.withValues(alpha: 0.3)
              : AppColors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIdle ? Icons.cloud_done_outlined : Icons.sync,
                color: isIdle ? AppColors.stateMastery : AppColors.accent,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                syncProgress.statusLabel,
                style: AppTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (!isIdle) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: syncProgress.fraction,
                backgroundColor:
                    colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${syncProgress.syncedAssets}/${syncProgress.totalAssets} synced',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;

  const _SectionHeader({required this.title, required this.colorScheme});

  @override
  Widget build(final BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.caption.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.5),
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final ColorScheme colorScheme;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.colorScheme,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.merge(const TextStyle(fontWeight: FontWeight.w600)).copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _DataUsageCard extends StatelessWidget {
  final int usedBytes;
  final int capBytes;
  final ColorScheme colorScheme;

  const _DataUsageCard({
    required this.usedBytes,
    required this.capBytes,
    required this.colorScheme,
  });

  @override
  Widget build(final BuildContext context) {
    final usedMb = usedBytes / (1024 * 1024);
    final capMb = capBytes / (1024 * 1024);
    final fraction = capBytes > 0 ? (usedBytes / capBytes).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mobile Data This Month',
            style: AppTypography.bodySmall.merge(const TextStyle(fontWeight: FontWeight.w600)).copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor:
                  colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                fraction > 0.9 ? AppColors.actionAgain : AppColors.accent,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${usedMb.toStringAsFixed(1)} MB / ${capMb.toStringAsFixed(0)} MB',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.merge(const TextStyle(fontWeight: FontWeight.w600)).copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
