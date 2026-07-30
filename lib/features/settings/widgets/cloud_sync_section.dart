import 'package:flutter/material.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';
import 'package:breakdex/core/sync/gdrive_setup_service.dart';
import 'package:breakdex/core/sync/icloud_setup_service.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/action_tile.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/core/design/icons.dart';

class CloudSyncSection extends ConsumerWidget {
  const CloudSyncSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final iCloudAvailable = ref.watch(iCloudAvailableProvider);
    final configuredProviders = ref.watch(cloudProvidersProvider);

    // Check if iCloud is already configured & enabled in the DB
    final iCloudConnected =
        configuredProviders.whenOrNull(
          data: (final providers) =>
              providers.any((final p) => p.providerType == 'icloud'),
        ) ??
        false;

    // Check if Google Drive is configured & enabled
    final gDriveConnected =
        configuredProviders.whenOrNull(
          data: (final providers) =>
              providers.any((final p) => p.providerType == 'gdrive'),
        ) ??
        false;

    final syncHealth = ref.watch(syncHealthProvider);
    final syncProgress = ref.watch(assetSyncProgressProvider).valueOrNull;
    final pendingCount = ref.watch(underprotectedCountProvider).valueOrNull;

    // Honest subtitle (D1): live engine label only while transferring;
    // otherwise the persistent Drift count decides — "All synced" is a
    // measurement, never a default.
    final syncSubtitle = switch (syncHealth) {
      SyncHealth.noProviders => null,
      SyncHealth.syncing when syncProgress != null => syncProgress.statusLabel,
      _ when pendingCount == null => l10n.setSyncChecking,
      _ when pendingCount > 0 => l10n.setSyncPendingCount(pendingCount),
      _ => l10n.setSyncAllSynced,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.setSyncSectionHeader,
              style: AppTypography.sectionHeader.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SyncHealthDot(health: syncHealth),
          ],
        ),
        if (syncSubtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            syncSubtitle,
            style: AppTypography.caption.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        // Appwrite identity account (wave task 3.3). Optional: signing in unlocks
        // cross-device sync; local-only users can ignore it entirely.
        const _AccountRow(),
        const SizedBox(height: AppSpacing.sm),

        // iCloud row
        SyncProviderRow(
          icon: AppIcon.cloud.resolve(context),
          title: l10n.setSyncProviderIcloudTitle,
          status: iCloudConnected
              ? ProviderStatus.connected
              : iCloudAvailable.when(
                  data: (final available) => available
                      ? ProviderStatus.available
                      : ProviderStatus.unavailable,
                  loading: () => ProviderStatus.loading,
                  error: (_, _) => ProviderStatus.unavailable,
                ),
          onTap: iCloudConnected ? null : () => _enableICloud(context, ref),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Google Drive. On web the google_sign_in Drive setup is not wired —
        // render honestly unavailable instead of offering a tap that can only
        // fail (backup-account spec). When connected, name the account that
        // holds the videos so nobody searches the wrong Drive.
        if (ref.watch(isWebPlatformProvider))
          SyncProviderRow(
            icon: AppIcon.add.resolve(context),
            title: l10n.setSyncProviderGdriveTitle,
            subtitle: l10n.setSyncGdriveWebUnavailable,
            status: ProviderStatus.unavailable,
            onTap: null,
          )
        else
          SyncProviderRow(
            icon: AppIcon.add.resolve(context),
            title: l10n.setSyncProviderGdriveTitle,
            subtitle:
                gDriveConnected &&
                    ref.watch(gdriveAccountEmailProvider).valueOrNull != null
                ? l10n.setSyncGdriveConnectedAccount(
                    ref.watch(gdriveAccountEmailProvider).valueOrNull!,
                  )
                : null,
            status: gDriveConnected
                ? ProviderStatus.connected
                : ProviderStatus.available,
            onTap: gDriveConnected
                ? () => _disconnectGDrive(context, ref)
                : () => _enableGDrive(context, ref),
          ),
        const SizedBox(height: AppSpacing.sm),

        // S3 — coming soon
        SyncProviderRow(
          icon: AppIcon.storage.resolve(context),
          title: l10n.setSyncProviderS3Title,
          status: ProviderStatus.comingSoon,
          onTap: null,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Force a fresh manifest push so the web mirror reflects the current
        // library on demand — also the quickest way to confirm Drive writes.
        if (iCloudConnected || gDriveConnected) ...[
          ActionTile(
            icon: AppIcon.upload.resolve(context),
            label: l10n.setSyncReuploadTile,
            onTap: () => _reuploadManifest(context, ref),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Links to sync screens
        ActionTile(
          icon: AppIcon.sync.resolve(context),
          label: l10n.setSyncStatusTile,
          onTap: () => context.push('/settings-panel/sync-status'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ActionTile(
          icon: AppIcon.refresh.resolve(context),
          label: l10n.setSyncFreeSpaceTile,
          onTap: () => context.push('/settings-panel/free-space'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ActionTile(
          icon: AppIcon.help.resolve(context),
          label: l10n.setSyncHelpTile,
          onTap: () => context.push('/settings-panel/sync-help'),
        ),
      ],
    );
  }

  Future<void> _reuploadManifest(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await HapticFeedback.mediumImpact();
    messenger.showSnackBar(SnackBar(content: Text(l10n.setSyncReuploading)));
    try {
      final count = await ref.read(manifestSyncServiceProvider).syncNow();
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? l10n.setSyncReuploadSuccess
                : l10n.setSyncReuploadNoProvider,
          ),
        ),
      );
    } on Object catch (e) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.setSyncReuploadFailed(e.toString()))),
      );
    }
  }

  Future<void> _enableGDrive(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    await HapticFeedback.mediumImpact();
    final result = await ref.read(gDriveSetupProvider).enable();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);

    switch (result) {
      case GDriveSetupResult.enabled:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.setSyncGdriveConnected)));
      case GDriveSetupResult.alreadyEnabled:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.setSyncGdriveAlreadyConnected)),
        );
      case GDriveSetupResult.cancelled:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.setSyncGdriveCancelled)));
    }
  }

  Future<void> _disconnectGDrive(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: Text(l10n.setSyncDisconnectTitle),
        content: Text(l10n.setSyncDisconnectBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.setSyncDisconnectCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.setSyncDisconnectConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await HapticFeedback.mediumImpact();
    await ref.read(gDriveSetupProvider).disconnect();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.setSyncGdriveDisconnected)));
  }

  Future<void> _enableICloud(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    await HapticFeedback.mediumImpact();
    final result = await ref.read(iCloudSetupProvider).enable();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);

    switch (result) {
      case ICloudSetupResult.enabled:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.setSyncIcloudEnabled)));
      case ICloudSetupResult.alreadyEnabled:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.setSyncIcloudAlreadyEnabled)),
        );
      case ICloudSetupResult.notAvailable:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.setSyncIcloudNotAvailable),
            duration: const Duration(seconds: 4),
          ),
        );
    }
  }
}

/// The Appwrite identity account row (wave task 3.3).
///
/// Signed out → "Sign in with Google" → routes to [AppwriteLoginScreen] (`/auth`).
/// Signed in → shows the account email + a "Sign out" affordance. Reactive to
/// [currentAppwriteUserProvider], so it flips the moment a session lands or ends.
/// Copy is inline English, matching the login screen's own hardcoded strings.
class _AccountRow extends ConsumerWidget {
  const _AccountRow();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final user = ref.watch(currentAppwriteUserProvider).valueOrNull;
    if (user == null) {
      return SyncProviderRow(
        icon: AppIcon.settings.resolve(context),
        title: 'Sign in with Google',
        status: ProviderStatus.available,
        onTap: () => context.push('/auth'),
      );
    }
    return SyncProviderRow(
      icon: AppIcon.settings.resolve(context),
      title: user.email.isNotEmpty ? user.email : 'Signed in',
      status: ProviderStatus.connected,
      onTap: () => _signOut(context, ref),
    );
  }

  Future<void> _signOut(final BuildContext context, final WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your local library stays on this device. You can sign back in any '
          'time to resume syncing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await HapticFeedback.mediumImpact();
    try {
      await ref.read(appwriteAuthServiceProvider).signOut();
    } on AuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

enum ProviderStatus { connected, available, unavailable, comingSoon, loading }

class SyncProviderRow extends StatelessWidget {
  final IconData icon;
  final String title;

  /// Optional detail under the title — the connected account email, or the
  /// reason a provider is unavailable on this platform.
  final String? subtitle;
  final ProviderStatus status;
  final VoidCallback? onTap;

  const SyncProviderRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                ? AppSemanticTheme.of(context).stateMastery.withValues(alpha: 0.4)
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDisabled
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.onSurface.withValues(
                          alpha: isDisabled ? 0.3 : 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _statusLabel(l10n, colorScheme, AppSemanticTheme.of(context)),
          ],
        ),
      ),
    );
  }

  Widget _statusLabel(
    final AppLocalizations l10n,
    final ColorScheme colorScheme,
    final AppSemanticTheme semantic,
  ) {
    switch (status) {
      case ProviderStatus.connected:
        return Text(
          l10n.setSyncStatusConnected,
          style: AppTypography.caption.copyWith(
            color: semantic.stateMastery,
            fontWeight: FontWeight.w600,
          ),
        );
      case ProviderStatus.available:
        return Text(
          l10n.setSyncStatusTapToEnable,
          style: AppTypography.caption.copyWith(color: colorScheme.primary),
        );
      case ProviderStatus.unavailable:
        return Text(
          l10n.setSyncStatusNotAvailable,
          style: AppTypography.caption.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        );
      case ProviderStatus.comingSoon:
        return Text(
          l10n.setSyncStatusComingSoon,
          style: AppTypography.caption.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        );
      case ProviderStatus.loading:
        return const SizedBox(width: 16, height: 16, child: AppLoader(size: 6));
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
          SyncHealth.allSynced => AppSemanticTheme.of(context).stateMastery,
          SyncHealth.syncing => Colors.blue,
          SyncHealth.pendingUpload => Colors.amber,
          SyncHealth.error => Colors.red,
          SyncHealth.noProviders => Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.3),
        },
      ),
    );
  }
}
