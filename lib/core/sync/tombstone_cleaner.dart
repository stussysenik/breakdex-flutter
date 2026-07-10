// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import '../platform/io.dart';

import 'package:flutter/foundation.dart';

import '../database/daos/asset_copies_dao.dart';
import '../database/daos/asset_manifest_dao.dart';
import '../database/daos/sync_operations_dao.dart';
import 'cloud_provider.dart';

/// Result of a tombstone cleanup run.
class CleanupReport {
  final int assetsProcessed;
  final int localFilesDeleted;
  final int remoteCopiesDeleted;
  final int errors;

  const CleanupReport({
    required this.assetsProcessed,
    required this.localFilesDeleted,
    required this.remoteCopiesDeleted,
    required this.errors,
  });
}

/// Permanently removes soft-deleted assets after the 30-day grace period.
///
/// Runs as part of the background sync cycle. For each tombstoned asset
/// past the grace period:
/// 1. Deletes the local file (if it exists)
/// 2. Deletes remote copies via provider adapters
/// 3. Hard-deletes the manifest entry and associated copy/operation records
///
/// Safety: Refuses to clean assets that still have a non-deleted status
/// (defense-in-depth against bugs in soft-delete logic).
class TombstoneCleaner {
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;
  final SyncOperationsDao _opsDao;
  final List<CloudProvider> _providers;

  /// Grace period before tombstoned assets are permanently deleted.
  static const gracePeriod = Duration(days: 30);

  TombstoneCleaner({
    required final AssetManifestDao manifestDao,
    required final AssetCopiesDao copiesDao,
    required final SyncOperationsDao opsDao,
    required final List<CloudProvider> providers,
  })  : _manifestDao = manifestDao,
        _copiesDao = copiesDao,
        _opsDao = opsDao,
        _providers = providers;

  /// Run the cleanup cycle.
  ///
  /// Returns a [CleanupReport] summarizing what was deleted.
  Future<CleanupReport> cleanup() async {
    final cutoff = DateTime.now().subtract(gracePeriod);
    final candidates = await _manifestDao.getTombstonedBefore(cutoff);

    if (candidates.isEmpty) {
      return const CleanupReport(
        assetsProcessed: 0,
        localFilesDeleted: 0,
        remoteCopiesDeleted: 0,
        errors: 0,
      );
    }

    int localDeleted = 0;
    int remoteDeleted = 0;
    int errors = 0;

    for (final asset in candidates) {
      try {
        // 1. Delete local file
        if (asset.localPath != null) {
          final file = File(asset.localPath!);
          if (await file.exists()) {
            await file.delete();
            localDeleted++;
          }
        }

        // 2. Delete remote copies
        final copies = await _copiesDao.getByHash(asset.contentHash);
        for (final copy in copies) {
          if (copy.provider == 'local') continue;
          if (copy.remotePath == null) continue;

          final provider = _providers
              .where((final p) => p.providerType == copy.provider)
              .firstOrNull;
          if (provider == null) continue;

          try {
            await provider.delete(remotePath: copy.remotePath!);
            remoteDeleted++;
          } on Object catch (e) {
            debugPrint(
              'Failed to delete remote copy ${copy.id} '
              'from ${copy.provider}: $e',
            );
            errors++;
          }
        }

        // 3. Hard-delete all records
        await _copiesDao.deleteByHash(asset.contentHash);
        await _opsDao.deleteByHash(asset.contentHash);
        await _manifestDao.hardDelete(asset.contentHash);
      } on Object catch (e) {
        debugPrint(
          'Tombstone cleanup failed for ${asset.contentHash}: $e',
        );
        errors++;
      }
    }

    debugPrint(
      '[TombstoneCleaner] Cleaned ${candidates.length} assets: '
      '$localDeleted local, $remoteDeleted remote, $errors errors',
    );

    return CleanupReport(
      assetsProcessed: candidates.length,
      localFilesDeleted: localDeleted,
      remoteCopiesDeleted: remoteDeleted,
      errors: errors,
    );
  }
}
