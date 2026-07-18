// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import '../platform/io.dart';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../database/database.dart';
import '../database/daos/asset_copies_dao.dart';
import '../database/daos/asset_manifest_dao.dart';
import '../database/daos/sync_dao.dart';
import '../services/app_storage_paths.dart';
import '../services/video_path_resolver.dart';
import 'asset_hash_service.dart';
import 'cloud_provider.dart';

abstract interface class LocalAssetRetriever {
  Future<String?> ensureLocal(
    final String contentHash, {
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  });
}

/// Downloads a video from cloud storage on demand when the local copy has been
/// freed via [SpaceManager].
///
/// Flow:
/// 1. Check if local file already exists → return immediately
/// 2. Find verified cloud copy from any provider
/// 3. Download to local videos directory
/// 4. Verify hash matches content hash
/// 5. Update manifest.localPath and local copy record
class OnDemandDownloader implements LocalAssetRetriever {
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;
  final AssetHashService _hashService;
  final List<CloudProvider> Function() _getProviders;
  final SyncDao? _syncDao;

  OnDemandDownloader({
    required final AssetManifestDao manifestDao,
    required final AssetCopiesDao copiesDao,
    required final AssetHashService hashService,
    required final List<CloudProvider> Function() getProviders,
    final SyncDao? syncDao,
  }) : _manifestDao = manifestDao,
       _copiesDao = copiesDao,
       _hashService = hashService,
       _getProviders = getProviders,
       _syncDao = syncDao;

  /// Ensure a local copy exists for the given content hash.
  ///
  /// Returns the local file path, or null if download failed.
  /// Calls [onProgress] with (bytesDownloaded, totalBytes) during transfer.
  @override
  Future<String?> ensureLocal(
    final String contentHash, {
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) async {
    // Check if already local
    final manifest = await _manifestDao.getByHash(contentHash);
    if (manifest == null) {
      debugPrint('[OnDemandDownloader] Unknown hash: $contentHash');
      return null;
    }

    if (manifest.localPath != null) {
      final absolutePath = VideoPathResolver.toAbsolute(manifest.localPath!);
      final file = File(absolutePath);
      if (await file.exists()) return absolutePath;
    }

    // Find a verified remote copy
    final copies = await _copiesDao.getByHash(contentHash);
    final remoteCopy = copies
        .where((final c) => c.provider != 'local' && c.status == 'verified')
        .firstOrNull;

    if (remoteCopy == null) {
      debugPrint(
        '[OnDemandDownloader] No verified remote copy for $contentHash',
      );
      return null;
    }

    // Find the matching provider
    final providers = _getProviders();
    final provider = providers
        .where((final p) => p.providerType == remoteCopy.provider)
        .firstOrNull;

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
        debugPrint(
          '[OnDemandDownloader] Hash mismatch! Deleting corrupt file.',
        );
        await File(localPath).delete();
        return null;
      }

      // Update manifest with new local path (relative for portability)
      await _manifestDao.updateLocalState(
        contentHash,
        localPath: Value(VideoPathResolver.toRelative(localPath)),
        localVerifiedAt: Value(DateTime.now()),
      );

      // Upsert local copy record
      final now = DateTime.now();
      await _copiesDao.upsertCopy(
        AssetCopiesCompanion.insert(
          id: AssetCopiesDao.copyId(contentHash, 'local'),
          contentHash: contentHash,
          provider: 'local',
          status: const Value('verified'),
          verifiedAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _manifestDao.updateCopyCount(contentHash);

      // Log the cloud → local state transition for audit trail
      if (_syncDao != null) {
        try {
          await _syncDao.logChange(
            entityId: contentHash,
            table: 'asset_manifest',
            action: 'download_restored',
          );
        } on Object catch (_) {
          // Non-fatal — logging is informational
        }
      }

      debugPrint('[OnDemandDownloader] Downloaded to $localPath');
      return localPath;
    } on Object catch (e) {
      debugPrint('[OnDemandDownloader] Download failed: $e');
      return null;
    }
  }
}
