import 'package:flutter/material.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';

/// Help page explaining the asset sync system to users.
///
/// Covers: content fingerprinting, 2-copy guarantee, 30-day trash,
/// file locations, sync settings, cloud providers, and troubleshooting.
class AssetSyncHelpScreen extends StatelessWidget {
  const AssetSyncHelpScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Video Backup & Sync',
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
          _HelpSection(
            icon: Icons.fingerprint,
            title: 'How Your Videos Are Protected',
            colorScheme: colorScheme,
            content: 'Every video is fingerprinted with a SHA-256 hash when '
                'you import it. This unique fingerprint lets Breakdex:\n\n'
                '- Detect if a file has been corrupted or modified\n'
                '- Avoid storing duplicate copies of the same video\n'
                '- Verify that cloud backups match your originals\n\n'
                'The system enforces a 2-copy minimum: your video must exist '
                'both locally and in at least one cloud provider before the '
                'local file can be removed.',
          ),
          _HelpSection(
            icon: Icons.delete_outline,
            title: '30-Day Trash',
            colorScheme: colorScheme,
            content: 'When you delete a video, it enters a 30-day grace '
                'period. During this time:\n\n'
                '- The file stays on your device\n'
                '- Cloud copies are preserved\n'
                '- You can recover it from Settings > Sync Status\n\n'
                'After 30 days, the file and all copies are permanently '
                'removed.',
          ),
          _HelpSection(
            icon: Icons.folder_outlined,
            title: 'Where Your Files Live',
            colorScheme: colorScheme,
            content: 'Local videos are stored in your app\'s Documents/'
                'Moves/ folder with UUID filenames (e.g. a1b2c3d4.mp4).\n\n'
                'Cloud copies are organized by content hash in a Breakdex '
                'folder on each provider:\n\n'
                '- iCloud: iCloud Drive > Breakdex\n'
                '- Google Drive: Hidden app data folder\n'
                '- S3: Your configured bucket > breakdex/',
          ),
          _HelpSection(
            icon: Icons.wifi,
            title: 'Sync Settings',
            colorScheme: colorScheme,
            content: 'By default, sync only runs on WiFi to protect your '
                'mobile data plan.\n\n'
                'You can enable mobile data sync in Settings > Sync Status '
                'with a configurable monthly cap (default: 100 MB).\n\n'
                'On WiFi: up to 2 concurrent uploads, 3 downloads\n'
                'On mobile: 1 upload, 1 download, 256 KB/s throttle\n\n'
                'Background sync runs every 15 minutes when your device '
                'is on WiFi and charging.',
          ),
          _HelpSection(
            icon: Icons.cloud_outlined,
            title: 'Cloud Providers',
            colorScheme: colorScheme,
            content: 'You can configure multiple cloud providers. Each '
                'provider gets its own copy of every video.\n\n'
                'iCloud Drive: Automatic with your Apple ID. Uses your '
                'iCloud storage quota.\n\n'
                'Google Drive: Requires sign-in. Videos stored in a hidden '
                'app folder that won\'t clutter your Drive.\n\n'
                'S3 Compatible: Works with Amazon S3, Cloudflare R2, '
                'Backblaze B2, MinIO, and more. You provide the endpoint, '
                'bucket, and credentials.\n\n'
                'To add or remove providers, go to Settings > Cloud '
                'Providers.',
          ),
          _HelpSection(
            icon: Icons.build_outlined,
            title: 'Troubleshooting',
            colorScheme: colorScheme,
            content: 'Video shows as missing?\n'
                'Check Sync Status for download progress. If the video is '
                'backed up to cloud, it will auto-download when you need it.\n\n'
                'Sync stuck or slow?\n'
                'Check your network connection. Sync pauses automatically '
                'when offline or on mobile data (if WiFi-only is enabled).\n\n'
                'Integrity error?\n'
                'Run "Verify Integrity" in Sync Status. If a file is '
                'corrupted, it will be re-downloaded from cloud automatically.\n\n'
                'Can\'t delete a video?\n'
                'The 2-copy safety check prevents deletion until the video '
                'is backed up to at least one cloud provider. Wait for sync '
                'to complete.',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final ColorScheme colorScheme;

  const _HelpSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.colorScheme,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            content,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
