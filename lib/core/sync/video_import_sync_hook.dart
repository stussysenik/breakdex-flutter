import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../database/daos/asset_copies_dao.dart';
import '../database/daos/asset_manifest_dao.dart';
import '../database/daos/moves_dao.dart';
import '../services/connectivity_service.dart';
import '../services/video_path_resolver.dart';
import 'asset_hash_service.dart';
import 'asset_sync_engine.dart';

/// Post-import hook that bridges video import → hash → manifest → upload.
///
/// When a user imports a video via the move creation flow, this orchestrator:
/// 1. Computes SHA-256 in a background isolate (non-blocking)
/// 2. Registers the asset in `asset_manifest` (content-addressable)
/// 3. Creates a `local` copy record in `asset_copies`
/// 4. Links the move to its content hash via `moves.contentHash`
/// 5. Queues upload operations for each enabled cloud provider
/// 6. Triggers a sync cycle to start uploading immediately
class VideoImportSyncHook {
  final AssetHashService _hashService;
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;
  final MovesDao _movesDao;
  final AssetSyncEngine _syncEngine;
  final ConnectivityService _connectivityService;

  VideoImportSyncHook({
    required final AssetHashService hashService,
    required final AssetManifestDao manifestDao,
    required final AssetCopiesDao copiesDao,
    required final MovesDao movesDao,
    required final AssetSyncEngine syncEngine,
    required final ConnectivityService connectivityService,
  })  : _hashService = hashService,
        _manifestDao = manifestDao,
        _copiesDao = copiesDao,
        _movesDao = movesDao,
        _syncEngine = syncEngine,
        _connectivityService = connectivityService;

  /// Called after a move with a video has been successfully inserted.
  ///
  /// Runs asynchronously — callers should fire-and-forget via [unawaited].
  /// Failures are logged but never propagated to the UI.
  Future<void> onVideoImported({
    required final String localPath,
    required final String moveId,
    final String? precomputedHash,
  }) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        debugPrint('[VideoImportSyncHook] File not found: $localPath');
        return;
      }

      // Step 1: Get SHA-256 hash (use precomputed if available)
      final contentHash = precomputedHash ?? await _hashService.computeHash(localPath);
      if (precomputedHash == null) {
        debugPrint('[VideoImportSyncHook] Hashing $localPath…');
        debugPrint('[VideoImportSyncHook] Hash: $contentHash');
      }

      // Step 2: Get file metadata
      final stat = await file.stat();
      final now = DateTime.now();

      // Step 3: Insert asset_manifest row (deduplicates by contentHash PK)
      // Store relative path so it survives iOS container UUID changes.
      await _manifestDao.upsert(AssetManifestCompanion.insert(
        contentHash: contentHash,
        fileSizeBytes: stat.size,
        localPath: Value(VideoPathResolver.toRelative(localPath)),
        localVerifiedAt: Value(now),
        sourceType: 'photos',
        importedAt: now,
      ));
      debugPrint('[VideoImportSyncHook] Manifest inserted');

      // Step 4: Insert local copy record in asset_copies
      final copyId = '${moveId}_local';
      await _copiesDao.upsertCopy(AssetCopiesCompanion.insert(
        id: copyId,
        contentHash: contentHash,
        provider: 'local',
        status: const Value('verified'),
        verifiedAt: Value(now),
        createdAt: now,
        updatedAt: now,
      ));
      debugPrint('[VideoImportSyncHook] Local copy registered');

      // Step 5: Link move to its content hash
      await _movesDao.updateMove(MovesCompanion(
        id: Value(moveId),
        contentHash: Value(contentHash),
      ));
      debugPrint('[VideoImportSyncHook] Move linked to hash');

      // Step 6: Queue uploads for all enabled cloud providers
      await _syncEngine.queueUpload(contentHash);
      debugPrint('[VideoImportSyncHook] Upload queued');

      // Step 7: Trigger sync cycle to start uploading immediately
      final connectionType = _connectivityService.currentType;
      unawaited(_syncEngine.runSyncCycle(connectionType));
      debugPrint('[VideoImportSyncHook] Sync cycle triggered');
    } catch (e, stack) {
      // Non-fatal — video is saved locally, sync will catch up later
      debugPrint('[VideoImportSyncHook] Failed: $e\n$stack');
    }
  }
}
