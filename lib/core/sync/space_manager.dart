import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/database.dart';
import '../database/daos/asset_copies_dao.dart';
import '../database/daos/asset_manifest_dao.dart';
import 'safety_guard.dart';

/// Analysis result showing how much space can be freed.
class SpaceAnalysis {
  /// Content hashes of assets that have ≥2 copies (safe to free local).
  final List<String> freeableHashes;

  /// Total bytes that would be freed by deleting local copies.
  final int freeableBytes;

  /// Total number of synced assets (regardless of local copy status).
  final int totalSyncedAssets;

  const SpaceAnalysis({
    required this.freeableHashes,
    required this.freeableBytes,
    required this.totalSyncedAssets,
  });

  bool get canFree => freeableHashes.isNotEmpty;
}

/// Manages local storage by safely deleting video files that have verified
/// cloud backups. Uses [SafetyGuard] to enforce the two-copy minimum before
/// any deletion.
///
/// After freeing space, the manifest's `localPath` is set to null — the video
/// can be re-downloaded on demand via [OnDemandDownloader].
class SpaceManager {
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;
  final SafetyGuard _safetyGuard;

  SpaceManager({
    required AssetManifestDao manifestDao,
    required AssetCopiesDao copiesDao,
    required SafetyGuard safetyGuard,
  }) : _manifestDao = manifestDao,
       _copiesDao = copiesDao,
       _safetyGuard = safetyGuard;

  /// Analyze which assets can have their local copies safely deleted.
  ///
  /// An asset is freeable if:
  /// 1. It has a local file on disk (`localPath != null`)
  /// 2. It has ≥1 verified cloud copy (SafetyGuard check)
  Future<SpaceAnalysis> analyze() async {
    final allAssets = await _manifestDao.getAll();
    final freeableHashes = <String>[];
    int freeableBytes = 0;
    int totalSynced = 0;

    for (final asset in allAssets) {
      if (asset.deletedAt != null) continue;

      // Count verified cloud copies
      final verifiedCount = await _copiesDao.countVerified(asset.contentHash);
      if (verifiedCount > 1) totalSynced++; // Has at least one cloud copy

      // Check if local file exists and can be freed
      if (asset.localPath != null) {
        final canFree = await _safetyGuard.canDeleteLocal(asset.contentHash);
        if (canFree) {
          final file = File(asset.localPath!);
          if (await file.exists()) {
            freeableHashes.add(asset.contentHash);
            freeableBytes += asset.fileSizeBytes;
          }
        }
      }
    }

    return SpaceAnalysis(
      freeableHashes: freeableHashes,
      freeableBytes: freeableBytes,
      totalSyncedAssets: totalSynced,
    );
  }

  /// Free local storage for the given content hashes.
  ///
  /// For each hash:
  /// 1. Verify SafetyGuard allows deletion (≥1 verified cloud copy)
  /// 2. Delete the local video file (keep thumbnails!)
  /// 3. Set `asset_manifest.localPath = null`
  /// 4. Mark the local copy as 'deleted'
  ///
  /// Returns the number of bytes freed.
  Future<int> freeSpace(List<String> hashes) async {
    int freedBytes = 0;

    // Circuit breaker: prevent bulk deletion of >25% of assets
    final safe = await _safetyGuard.circuitBreakerCheck(hashes);
    if (!safe) {
      debugPrint('[SpaceManager] Circuit breaker tripped — aborting');
      return 0;
    }

    for (final hash in hashes) {
      try {
        // Re-verify safety (state may have changed since analysis)
        await _safetyGuard.assertSafeToDeleteLocal(hash);

        final manifest = await _manifestDao.getByHash(hash);
        if (manifest == null || manifest.localPath == null) continue;

        final file = File(manifest.localPath!);
        final size = manifest.fileSizeBytes;

        // Delete the video file
        if (await file.exists()) {
          await file.delete();
          debugPrint('[SpaceManager] Deleted ${manifest.localPath}');
        }

        // Clear localPath in manifest
        await _manifestDao.updateLocalState(
          hash,
          localPath: const Value(null),
          localVerifiedAt: const Value(null),
        );

        // Mark local copy as deleted
        final localCopy = await _copiesDao.getLocalCopy(hash);
        if (localCopy != null) {
          await _copiesDao.updateCopy(
            AssetCopiesCompanion(
              id: Value(localCopy.id),
              status: const Value('deleted'),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }

        // Update copy count
        await _manifestDao.updateCopyCount(hash);

        freedBytes += size;
      } catch (e) {
        debugPrint('[SpaceManager] Failed to free $hash: $e');
        // Continue with next — don't let one failure stop the batch
      }
    }

    debugPrint('[SpaceManager] Freed $freedBytes bytes');
    return freedBytes;
  }
}
