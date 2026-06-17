import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';
import '../../../core/sync/gdrive_setup_service.dart';
import '../../../core/sync/icloud_setup_service.dart';
import '../../../shared/widgets/action_tile.dart';

class CloudSyncSection extends ConsumerWidget {
  const CloudSyncSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final iCloudAvailable = ref.watch(iCloudAvailableProvider);
    final configuredProviders = ref.watch(cloudProvidersProvider);

    // Check if iCloud is already configured & enabled in the DB
    final iCloudConnected = configuredProviders.whenOrNull(
          data: (final providers) =>
              providers.any((final p) => p.providerType == 'icloud'),
        ) ??
        false;

    // Check if Google Drive is configured & enabled
    final gDriveConnected = configuredProviders.whenOrNull(
          data: (final providers) =>
              providers.any((final p) => p.providerType == 'gdrive'),
        ) ??
        false;

    final syncHealth = ref.watch(syncHealthProvider);
    final syncProgress = ref.watch(assetSyncProgressProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'VIDEO BACKUP',
              style: AppTypography.sectionHeader.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SyncHealthDot(health: syncHealth),
          ],
        ),
        if (syncProgress != null && syncHealth != SyncHealth.noProviders) ...[
          const SizedBox(height: 4),
          Text(
            syncProgress.statusLabel,
            style: AppTypography.caption.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        // iCloud row
        SyncProviderRow(
          icon: Icons.cloud_outlined,
          title: 'iCloud Drive',
          status: iCloudConnected
              ? ProviderStatus.connected
              : iCloudAvailable.when(
                  data: (final available) => available
                      ? ProviderStatus.available
                      : ProviderStatus.unavailable,
                  loading: () => ProviderStatus.loading,
                  error: (_, _) => ProviderStatus.unavailable,
                ),
          onTap: iCloudConnected
              ? null
              : () => _enableICloud(context, ref),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Google Drive
        SyncProviderRow(
          icon: Icons.add_to_drive_outlined,
          title: 'Google Drive',
          status: gDriveConnected
              ? ProviderStatus.connected
              : ProviderStatus.available,
          onTap: gDriveConnected
              ? () => _disconnectGDrive(context, ref)
              : () => _enableGDrive(context, ref),
        ),
        const SizedBox(height: AppSpacing.sm),

        // S3 — coming soon
        const SyncProviderRow(
          icon: Icons.storage_outlined,
          title: 'S3 Compatible',
          status: ProviderStatus.comingSoon,
          onTap: null,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Links to sync screens
        ActionTile(
          icon: Icons.sync,
          label: 'Sync Status',
          onTap: () => context.push('/settings-panel/sync-status'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ActionTile(
          icon: Icons.cleaning_services_outlined,
          label: 'Free Up Space',
          onTap: () => context.push('/settings-panel/free-space'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ActionTile(
          icon: Icons.help_outline,
          label: 'How Backup Works',
          onTap: () => context.push('/settings-panel/sync-help'),
        ),
      ],
    );
  }

  Future<void> _enableGDrive(final BuildContext context, final WidgetRef ref) async {
    await HapticFeedback.mediumImpact();
    final result = await ref.read(gDriveSetupProvider).enable();
    if (!context.mounted) return;

    switch (result) {
      case GDriveSetupResult.enabled:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Drive connected')),
        );
      case GDriveSetupResult.alreadyEnabled:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Drive is already connected'),
          ),
        );
      case GDriveSetupResult.cancelled:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in was cancelled')),
        );
    }
  }

  Future<void> _disconnectGDrive(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: const Text('Disconnect Google Drive?'),
        content: const Text(
          'Videos already backed up to Drive stay there. New videos won’t '
          'back up until you reconnect and sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await HapticFeedback.mediumImpact();
    await ref.read(gDriveSetupProvider).disconnect();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Drive disconnected')),
    );
  }

  Future<void> _enableICloud(final BuildContext context, final WidgetRef ref) async {
    await HapticFeedback.mediumImpact();
    final result = await ref.read(iCloudSetupProvider).enable();
    if (!context.mounted) return;

    switch (result) {
      case ICloudSetupResult.enabled:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('iCloud Drive enabled')),
        );
      case ICloudSetupResult.alreadyEnabled:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('iCloud Drive is already enabled')),
        );
      case ICloudSetupResult.notAvailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enable iCloud Drive in iOS Settings > [your name] > iCloud',
            ),
            duration: Duration(seconds: 4),
          ),
        );
    }
  }
}

enum ProviderStatus { connected, available, unavailable, comingSoon, loading }

class SyncProviderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final ProviderStatus status;
  final VoidCallback? onTap;

  const SyncProviderRow({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled =
        status == ProviderStatus.comingSoon ||
        status == ProviderStatus.unavailable;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: status == ProviderStatus.connected
                ? AppColors.stateMastery.withValues(alpha: 0.4)
                : colorScheme.outline.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDisabled
                  ? colorScheme.onSurface.withValues(alpha: 0.3)
                  : colorScheme.onSurface,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDisabled
                      ? colorScheme.onSurface.withValues(alpha: 0.3)
                      : colorScheme.onSurface,
                ),
              ),
            ),
            _statusLabel(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _statusLabel(final ColorScheme colorScheme) {
    switch (status) {
      case ProviderStatus.connected:
        return Text(
          'Connected',
          style: AppTypography.caption.copyWith(
            color: AppColors.stateMastery,
            fontWeight: FontWeight.w600,
          ),
        );
      case ProviderStatus.available:
        return Text(
          'Tap to enable',
          style: AppTypography.caption.copyWith(
            color: AppColors.accent,
          ),
        );
      case ProviderStatus.unavailable:
        return Text(
          'Not available',
          style: AppTypography.caption.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        );
      case ProviderStatus.comingSoon:
        return Text(
          'Coming soon',
          style: AppTypography.caption.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        );
      case ProviderStatus.loading:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
    }
  }
}

/// Colored dot indicator for overall sync health.
///
/// green = all synced, blue = syncing, amber = pending,
/// red = error, gray = no providers configured.
class SyncHealthDot extends StatelessWidget {
  final SyncHealth health;
  const SyncHealthDot({super.key, required this.health});

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (health) {
          SyncHealth.allSynced => AppColors.stateMastery,
          SyncHealth.syncing => Colors.blue,
          SyncHealth.pendingUpload => Colors.amber,
          SyncHealth.error => Colors.red,
          SyncHealth.noProviders =>
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        },
      ),
    );
  }
}
