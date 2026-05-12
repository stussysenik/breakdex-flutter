import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/canonical_asset.dart';
import '../../core/providers.dart';
import '../../shared/widgets/settings_list_group.dart';
import '../../shared/widgets/source_origin_badge.dart';

class CanonicalTrashScreen extends ConsumerWidget {
  const CanonicalTrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashedAsync = ref.watch(trashedAssetsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    Icon(Icons.chevron_left, color: colorScheme.secondary, size: 20),
                    Text('Settings',
                        style: AppTypography.bodyMedium.copyWith(color: colorScheme.secondary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Canonical Trash',
                  style: AppTypography.titleLarge.copyWith(color: colorScheme.onSurface)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Assets deleted from Breakdex stay here for 30 days '
                'so you can restore them or remove them permanently.',
                style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: trashedAsync.when(
                  data: (assets) {
                    if (assets.isEmpty) {
                      return Center(
                        child: Text('No assets in trash.',
                            style: AppTypography.bodyMedium.copyWith(color: colorScheme.secondary)),
                      );
                    }
                    return ListView(
                      children: [
                        SettingsListGroup(
                          children: [
                            for (final asset in assets) _TrashedAssetRow(asset: asset),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text('Could not load trashed assets.',
                        style: AppTypography.bodyMedium.copyWith(color: colorScheme.secondary)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrashedAssetRow extends ConsumerWidget {
  const _TrashedAssetRow({required this.asset});
  final AssetManifestData asset;

  static const _trashedColor = Color(0xFFE0A030);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final daysLeft = _computeDaysLeft(asset.deletedAt!);
    final source = _parseSource(asset.sourceType);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      leading: Icon(Icons.video_file_outlined, color: _trashedColor, size: 28),
      title: Row(children: [
        Expanded(child: Text(asset.sourceName ?? _shortHash(asset.contentHash),
            style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface))),
        const SizedBox(width: AppSpacing.sm),
        SourceOriginBadge(source: source),
      ]),
      subtitle: Text(_formatSubtitle(asset, daysLeft),
          style: AppTypography.caption.copyWith(color: colorScheme.secondary)),
      trailing: PopupMenuButton<_TrashAction>(
        onSelected: (action) async {
          unawaited(HapticFeedback.mediumImpact());
          switch (action) {
            case _TrashAction.restore: await _restore(context, ref, asset);
            case _TrashAction.deletePermanently: await _deletePermanently(context, ref, asset);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: _TrashAction.restore, child: Text('Restore')),
          PopupMenuItem(value: _TrashAction.deletePermanently, child: Text('Delete permanently')),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref, AssetManifestData asset) async {
    try {
      await ref.read(assetManifestDaoProvider).upsert(AssetManifestCompanion.insert(
            contentHash: asset.contentHash,
            fileSizeBytes: asset.fileSizeBytes,
            localPath: Value(asset.localPath),
            sourceType: asset.sourceType,
            sourceName: Value(asset.sourceName),
            importedAt: asset.importedAt,
            mimeType: Value(asset.mimeType),
          ));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset restored.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Restore failed: $error')));
    }
  }

  Future<void> _deletePermanently(
      BuildContext context, WidgetRef ref, AssetManifestData asset) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
            'This removes the asset from Breakdex permanently '
            '(${_formatFileSize(asset.fileSizeBytes)}).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.actionAgain))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(assetManifestDaoProvider).hardDelete(asset.contentHash);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Asset deleted permanently.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  static int _computeDaysLeft(DateTime deletedAt) {
    final remaining = deletedAt.add(const Duration(days: 30)).difference(DateTime.now());
    return remaining.inDays.clamp(0, 30);
  }

  static AssetSource _parseSource(String sourceType) => switch (sourceType) {
        'camera' => AssetSource.camera,
        'photos' => AssetSource.photos,
        'files' => AssetSource.files,
        'cloud' || 'cloud_download' => AssetSource.cloud,
        'legacy_migration' => AssetSource.legacy,
        _ => AssetSource.files,
      };

  static String _shortHash(String hash) =>
      '${hash.substring(0, 4)}\u2026${hash.substring(hash.length - 4)}';

  static String _formatSubtitle(AssetManifestData asset, int daysLeft) {
    final size = _formatFileSize(asset.fileSizeBytes);
    final reason = asset.tombstoneReason ?? 'Deleted';
    if (daysLeft <= 0) return '$reason \u2014 $size \u2014 Expiring soon';
    final dayLabel = daysLeft == 1 ? 'day' : 'days';
    return '$reason \u2014 $size \u2014 $daysLeft $dayLabel remaining';
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }
}

enum _TrashAction { restore, deletePermanently }
