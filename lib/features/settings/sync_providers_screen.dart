import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/sync/cloud_provider.dart';
import '../../core/sync/gdrive_setup_service.dart';
import '../../core/sync/icloud_setup_service.dart';

/// Feature flag: Google Drive requires OAuth client ID setup (GoogleService-
/// Info.plist). Flip to `true` once the Google Cloud project is provisioned.
const kGDriveEnabled = true;

/// Configuration screen for cloud storage providers.
///
/// Shows a list of configured providers with their status (connected, syncing,
/// error) and storage quota. Users can add new providers, toggle them on/off,
/// and test connections.
class SyncProvidersScreen extends ConsumerWidget {
  const SyncProvidersScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final providersAsync = ref.watch(cloudProvidersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cloud Providers',
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: providersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final e, _) => Center(child: Text('Error: $e')),
        data: (final providers) => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          children: [
            // Header
            Text(
              'Configure cloud storage to keep your training videos backed up. '
              'Each video needs at least 2 copies (local + cloud) before the '
              'local file can be safely removed.',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Configured providers
            if (providers.isEmpty)
              _EmptyProviderState(colorScheme: colorScheme)
            else
              ...providers.map(
                (final p) => _ProviderCard(provider: p, colorScheme: colorScheme),
              ),

            const SizedBox(height: AppSpacing.lg),

            // Add provider button
            _AddProviderButton(colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }
}

class _EmptyProviderState extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyProviderState({required this.colorScheme});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Cloud Providers',
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add a cloud provider to automatically back up your training videos.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  final CloudProvider provider;
  final ColorScheme colorScheme;

  const _ProviderCard({
    required this.provider,
    required this.colorScheme,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Watch sync operations to show error count for this provider
    final opsDao = ref.watch(syncOperationsDaoProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _iconForProvider(provider.providerType),
            color: AppColors.accent,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.displayName,
                  style: AppTypography.bodySmall.merge(const TextStyle(fontWeight: FontWeight.w600)).copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<bool>(
                  future: provider.isAuthenticated,
                  builder: (final context, final snap) {
                    final connected = snap.data ?? false;
                    return Text(
                      connected ? 'Connected' : 'Not connected',
                      style: AppTypography.bodySmall.copyWith(
                        color: connected
                            ? AppColors.stateMastery
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                // Show failed operation count for this provider
                FutureBuilder<List<SyncOperation>>(
                  future: opsDao.getRetryable(),
                  builder: (final context, final snap) {
                    final failed = (snap.data ?? [])
                        .where((final op) => op.providerId == provider.providerType)
                        .length;
                    if (failed == 0) return const SizedBox.shrink();
                    return Text(
                      '$failed failed operation${failed == 1 ? '' : 's'}',
                      style: AppTypography.caption.copyWith(
                        color: Colors.red.withValues(alpha: 0.8),
                      ),
                    );
                  },
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
    );
  }

  IconData _iconForProvider(final String type) => switch (type) {
        'icloud' => Icons.cloud_outlined,
        'gdrive' => Icons.add_to_drive_outlined,
        's3' => Icons.storage_outlined,
        _ => Icons.cloud_outlined,
      };
}

class _AddProviderButton extends ConsumerWidget {
  final ColorScheme colorScheme;
  const _AddProviderButton({required this.colorScheme});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showAddProviderSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.accent, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Add Cloud Provider',
              style: AppTypography.bodySmall.merge(const TextStyle(fontWeight: FontWeight.w600)).copyWith(
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProviderSheet(final BuildContext context, final WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (final ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Provider',
              style: AppTypography.titleSmall.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ProviderOption(
              icon: Icons.cloud_outlined,
              title: 'iCloud Drive',
              subtitle: 'Uses your Apple iCloud storage',
              onTap: () async {
                Navigator.pop(ctx);
                unawaited(HapticFeedback.mediumImpact());
                final result = await ref.read(iCloudSetupProvider).enable();
                if (!context.mounted) return;
                switch (result) {
                  case ICloudSetupResult.enabled:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('iCloud Drive enabled')),
                    );
                  case ICloudSetupResult.alreadyEnabled:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('iCloud Drive is already enabled'),
                      ),
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
              },
            ),
            if (kGDriveEnabled)
              _ProviderOption(
                icon: Icons.add_to_drive_outlined,
                title: 'Google Drive',
                subtitle: 'Requires Google account sign-in',
                onTap: () async {
                  Navigator.pop(ctx);
                  await HapticFeedback.mediumImpact();
                  final result =
                      await ref.read(gDriveSetupProvider).enable();
                  if (!context.mounted) return;
                  switch (result) {
                    case GDriveSetupResult.enabled:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Google Drive connected'),
                        ),
                      );
                    case GDriveSetupResult.alreadyEnabled:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Google Drive is already connected'),
                        ),
                      );
                    case GDriveSetupResult.cancelled:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Google sign-in was cancelled'),
                        ),
                      );
                  }
                },
              ),
            _ProviderOption(
              icon: Icons.storage_outlined,
              title: 'S3 Compatible',
              subtitle: 'AWS S3, Cloudflare R2, Backblaze B2, MinIO',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('S3 support coming soon')),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _ProviderOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProviderOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(
        title,
        style: AppTypography.bodySmall.merge(const TextStyle(fontWeight: FontWeight.w600)).copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
