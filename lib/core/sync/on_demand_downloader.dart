import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../database/database.dart';
import '../database/daos/asset_copies_dao.dart';
import '../database/daos/asset_manifest_dao.dart';
import '../services/app_storage_paths.dart';
import 'asset_hash_service.dart';
import 'cloud_provider.dart';

/// Downloads a video from cloud storage on demand when the local copy has been
/// freed via [SpaceManager].
///
/// Flow:
/// 1. Check if local file already exists → return immediately
/// 2. Find verified cloud copy from any provider
/// 3. Download to local videos directory
/// 4. Verify hash matches content hash
/// 5. Update manifest.localPath and local copy record
class OnDemandDownloader {
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;
  final AssetHashService _hashService;
  final List<CloudProvider> Function() _getProviders;

  OnDemandDownloader({
    required AssetManifestDao manifestDao,
    required AssetCopiesDao copiesDao,
    required AssetHashService hashService,
    required List<CloudProvider> Function() getProviders,
  })  : _manifestDao = manifestDao,
        _copiesDao = copiesDao,
        _hashService = hashService,
        _getProviders = getProviders;

  /// Ensure a local copy exists for the given content hash.
  ///
  /// Returns the local file path, or null if download failed.
  /// Calls [onProgress] with (bytesDownloaded, totalBytes) during transfer.
  Future<String?> ensureLocal(
    String contentHash, {
    TransferProgress? onProgress,
    CancellationToken? cancel,
  }) async {
    // Check if already local
    final manifest = await _manifestDao.getByHash(contentHash);
    if (manifest == null) {
      debugPrint('[OnDemandDownloader] Unknown hash: $contentHash');
      return null;
    }

    if (manifest.localPath != null) {
      final file = File(manifest.localPath!);
      if (await file.exists()) return manifest.localPath;
    }

    // Find a verified remote copy
    final copies = await _copiesDao.getByHash(contentHash);
    final remoteCopy = copies.where(
      (c) => c.provider != 'local' && c.status == 'verified',
    ).firstOrNull;

    if (remoteCopy == null) {
      debugPrint('[OnDemandDownloader] No verified remote copy for $contentHash');
      return null;
    }

    // Find the matching provider
    final providers = _getProviders();
    final provider = providers.where(
      (p) => p.providerType == remoteCopy.provider,
    ).firstOrNull;

    if (provider == null) {
      debugPrint(
        '[OnDemandDownloader] Provider ${remoteCopy.provider} not available',
      );
      return null;
    }

    try {
      // Download to videos directory
      final dir = await AppStoragePaths.documentsDirectory();
      final videosDir = Directory(p.join(dir.path, 'videos'));
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }
      final localPath = p.join(videosDir.path, '$contentHash.mp4');

      debugPrint('[OnDemandDownloader] Downloading $contentHash…');
      await provider.download(
        remotePath: remoteCopy.remotePath ?? contentHash,
        localPath: localPath,
        onProgress: onProgress,
        cancel: cancel,
      );

      // Verify hash integrity
      final verified = await _hashService.verifyHash(localPath, contentHash);
      if (!verified) {
        debugPrint('[OnDemandDownloader] Hash mismatch! Deleting corrupt file.');
        await File(localPath).delete();
        return null;
      }

      // Update manifest with new local path
      await _manifestDao.upsert(AssetManifestCompanion(
        contentHash: Value(contentHash),
        localPath: Value(localPath),
        localVerifiedAt: Value(DateTime.now()),
      ));

      // Upsert local copy record
      final now = DateTime.now();
      await _copiesDao.upsertCopy(AssetCopiesCompanion.insert(
        id: '${contentHash}_local_redownload',
        contentHash: contentHash,
        provider: 'local',
        status: const Value('verified'),
        verifiedAt: Value(now),
        createdAt: now,
        updatedAt: now,
      ));

      await _manifestDao.updateCopyCount(contentHash);

      debugPrint('[OnDemandDownloader] Downloaded to $localPath');
      return localPath;
    } catch (e) {
      debugPrint('[OnDemandDownloader] Download failed: $e');
      return null;
    }
  }
}
