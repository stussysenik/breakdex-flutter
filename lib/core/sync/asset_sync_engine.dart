import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../database/daos/asset_copies_dao.dart';
import '../database/daos/asset_manifest_dao.dart';
import '../database/daos/sync_dao.dart';
import '../database/daos/sync_operations_dao.dart';
import '../services/connectivity_service.dart';
import 'asset_hash_service.dart';
import 'cloud_provider.dart';
import 'network_policy.dart';
import 'safety_guard.dart';

/// Overall sync progress snapshot for UI display.
class SyncProgress {
  final int totalAssets;
  final int syncedAssets;
  final int pendingUploads;
  final int pendingDownloads;
  final int activeTransfers;
  final String? currentAssetHash;
  final SyncEngineState state;

  const SyncProgress({
    required this.totalAssets,
    required this.syncedAssets,
    required this.pendingUploads,
    required this.pendingDownloads,
    required this.activeTransfers,
    this.currentAssetHash,
    required this.state,
  });

  static const idle = SyncProgress(
    totalAssets: 0,
    syncedAssets: 0,
    pendingUploads: 0,
    pendingDownloads: 0,
    activeTransfers: 0,
    state: SyncEngineState.idle,
  );

  double get fraction =>
      totalAssets > 0 ? syncedAssets / totalAssets : 1.0;

  String get statusLabel => switch (state) {
        SyncEngineState.idle => 'All synced',
        SyncEngineState.hashing => 'Hashing files...',
        SyncEngineState.uploading =>
          '$pendingUploads video${pendingUploads == 1 ? '' : 's'} uploading',
        SyncEngineState.downloading =>
          '$pendingDownloads video${pendingDownloads == 1 ? '' : 's'} downloading',
        SyncEngineState.verifying => 'Verifying copies...',
        SyncEngineState.waitingForWifi => 'Waiting for WiFi',
        SyncEngineState.error => 'Sync error',
        SyncEngineState.paused => 'Sync paused',
      };
}

/// State machine for the sync engine.
///
/// ```
/// idle → hashing → uploading → verifying → idle
///                       ↓                    ↓
///                     error ← retry     downloading
/// ```
enum SyncEngineState {
  idle,
  hashing,
  uploading,
  downloading,
  verifying,
  waitingForWifi,
  error,
  paused,
}

/// Orchestrates video asset synchronization across cloud providers.
///
/// The sync engine runs a cycle that:
/// 1. Verifies local files not checked recently
/// 2. Hashes any unhashed assets
/// 3. Uploads assets below the 2-copy minimum
/// 4. Downloads assets that are remote-only (new device restore)
/// 5. Cleans up tombstoned assets past the 30-day grace period
///
/// Each step respects [NetworkPolicy] constraints and can be paused/resumed.
class AssetSyncEngine {
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;
  final SyncOperationsDao _opsDao;
  final AssetHashService _hashService;
  final NetworkPolicy _networkPolicy;
  // ignore: unused_field
  final SafetyGuard _safetyGuard;
  final List<CloudProvider> _providers;
  final SyncDao? _syncDao;

  static const _uuid = Uuid();

  final _progressController =
      StreamController<SyncProgress>.broadcast();
  SyncEngineState _state = SyncEngineState.idle;
  bool _running = false;

  AssetSyncEngine({
    required AssetManifestDao manifestDao,
    required AssetCopiesDao copiesDao,
    required SyncOperationsDao opsDao,
    required AssetHashService hashService,
    required NetworkPolicy networkPolicy,
    required SafetyGuard safetyGuard,
    required List<CloudProvider> providers,
    SyncDao? syncDao,
  })  : _manifestDao = manifestDao,
        _copiesDao = copiesDao,
        _opsDao = opsDao,
        _hashService = hashService,
        _networkPolicy = networkPolicy,
        _safetyGuard = safetyGuard,
        _providers = providers,
        _syncDao = syncDao;

  /// Stream of sync progress updates.
  Stream<SyncProgress> get progressStream => _progressController.stream;

  /// Current engine state.
  SyncEngineState get state => _state;

  /// Run a full sync cycle. No-op if already running.
  Future<void> runSyncCycle(ConnectionType connectionType) async {
    if (_running) return;
    _running = true;

    try {
      // Step 0: Recover stale in_progress ops from a previous crashed session
      await _recoverStaleOps();

      // Step 1: Upload underprotected assets
      await _uploadUnderprotected(connectionType);

      // Step 2: Process queued operations
      await _processQueue(connectionType);

      // Step 3: Retry failed operations with exponential backoff
      await _retryFailed(connectionType);

      _setState(SyncEngineState.idle);
    } catch (e) {
      debugPrint('Sync cycle error: $e');
      _setState(SyncEngineState.error);
    } finally {
      _running = false;
    }
  }

  /// Queue an upload for an asset to all enabled providers.
  Future<void> queueUpload(String contentHash) async {
    for (final provider in _providers) {
      final alreadyExists = await _opsDao.operationExists(
        contentHash: contentHash,
        providerId: provider.providerType,
        operationType: 'upload',
      );
      if (alreadyExists) continue;

      final manifest = await _manifestDao.getByHash(contentHash);
      if (manifest == null) continue;

      await _opsDao.insertOperation(SyncOperationsCompanion.insert(
        id: _uuid.v4(),
        contentHash: contentHash,
        providerId: provider.providerType,
        operationType: 'upload',
        totalBytes: Value(manifest.fileSizeBytes),
        createdAt: DateTime.now(),
      ));
    }
  }

  /// Queue a download for an asset from the first available provider.
  Future<void> queueDownload(String contentHash) async {
    final copies = await _copiesDao.getByHash(contentHash);
    final remoteCopy = copies.where(
      (c) => c.provider != 'local' && c.status == 'verified',
    ).firstOrNull;

    if (remoteCopy == null) return;

    final alreadyExists = await _opsDao.operationExists(
      contentHash: contentHash,
      providerId: remoteCopy.provider,
      operationType: 'download',
    );
    if (alreadyExists) return;

    await _opsDao.insertOperation(SyncOperationsCompanion.insert(
      id: _uuid.v4(),
      contentHash: contentHash,
      providerId: remoteCopy.provider,
      operationType: 'download',
      createdAt: DateTime.now(),
    ));
  }

  void pause() => _setState(SyncEngineState.paused);

  void resume(ConnectionType connectionType) {
    if (_state == SyncEngineState.paused) {
      _setState(SyncEngineState.idle);
      runSyncCycle(connectionType);
    }
  }

  void dispose() {
    _progressController.close();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _uploadUnderprotected(ConnectionType connectionType) async {
    final underprotected = await _manifestDao.getUnderprotected();
    if (underprotected.isEmpty) return;

    _setState(SyncEngineState.uploading);

    for (final asset in underprotected) {
      if (_state == SyncEngineState.paused) return;

      final decision = _networkPolicy.canTransfer(
        asset.fileSizeBytes,
        connectionType,
      );
      if (decision == TransferDecision.waitForWifi) {
        _setState(SyncEngineState.waitingForWifi);
        return;
      }
      if (decision != TransferDecision.allow) continue;

      await queueUpload(asset.contentHash);
    }
  }

  Future<void> _processQueue(ConnectionType connectionType) async {
    final maxConcurrent =
        _networkPolicy.maxConcurrentUploads(connectionType);
    final queued = await _opsDao.getQueued(limit: maxConcurrent);

    for (final op in queued) {
      if (_state == SyncEngineState.paused) return;

      final decision = _networkPolicy.canTransfer(
        op.totalBytes,
        connectionType,
      );
      if (decision != TransferDecision.allow) continue;

      await _executeOperation(op, connectionType);
    }
  }

  Future<void> _executeOperation(
    SyncOperation op,
    ConnectionType connectionType,
  ) async {
    final provider = _providers
        .where((p) => p.providerType == op.providerId)
        .firstOrNull;
    if (provider == null) {
      await _opsDao.markFailed(op.id, 'Provider not configured');
      return;
    }

    await _opsDao.markInProgress(op.id);

    try {
      switch (op.operationType) {
        case 'upload':
          await _executeUpload(op, provider, connectionType);
        case 'download':
          await _executeDownload(op, provider, connectionType);
        case 'verify':
          await _executeVerify(op, provider);
        case 'delete_remote':
          await _executeDeleteRemote(op, provider);
        default:
          await _opsDao.markFailed(op.id, 'Unknown operation type');
      }
    } catch (e) {
      await _opsDao.markFailed(op.id, e.toString());
    }
  }

  Future<void> _executeUpload(
    SyncOperation op,
    CloudProvider provider,
    ConnectionType connectionType,
  ) async {
    final manifest = await _manifestDao.getByHash(op.contentHash);
    if (manifest?.localPath == null) {
      await _opsDao.markFailed(op.id, 'No local file to upload');
      return;
    }

    final remotePath = 'breakdex/${op.contentHash}';
    final token = CancellationToken();

    final result = await provider.upload(
      localPath: manifest!.localPath!,
      remotePath: remotePath,
      onProgress: (transferred, total) {
        _opsDao.updateProgress(op.id, transferred);
        if (connectionType == ConnectionType.mobile) {
          _networkPolicy.recordMobileUsage(transferred);
        }
      },
      cancel: token,
    );

    // Record the copy
    await _copiesDao.upsertCopy(AssetCopiesCompanion.insert(
      id: _uuid.v4(),
      contentHash: op.contentHash,
      provider: provider.providerType,
      remotePath: Value(result.remotePath),
      remoteEtag: Value(result.etag),
      status: const Value('verified'),
      verifiedAt: Value(DateTime.now()),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await _manifestDao.updateCopyCount(op.contentHash);
    await _opsDao.markCompleted(op.id);
  }

  Future<void> _executeDownload(
    SyncOperation op,
    CloudProvider provider,
    ConnectionType connectionType,
  ) async {
    final copies = await _copiesDao.getByHash(op.contentHash);
    final remoteCopy = copies
        .where((c) => c.provider == provider.providerType)
        .firstOrNull;

    if (remoteCopy?.remotePath == null) {
      await _opsDao.markFailed(op.id, 'No remote path available');
      return;
    }

    final manifest = await _manifestDao.getByHash(op.contentHash);
    final localPath = manifest?.localPath ??
        '/Documents/Moves/${op.contentHash}.mp4'; // Fallback path

    final token = CancellationToken();

    await provider.download(
      remotePath: remoteCopy!.remotePath!,
      localPath: localPath,
      onProgress: (transferred, total) {
        _opsDao.updateProgress(op.id, transferred);
        if (connectionType == ConnectionType.mobile) {
          _networkPolicy.recordMobileUsage(transferred);
        }
      },
      cancel: token,
    );

    // Verify downloaded file
    final hashMatches = await _hashService.verifyHash(
      localPath,
      op.contentHash,
    );
    if (!hashMatches) {
      await _opsDao.markFailed(op.id, 'Downloaded file hash mismatch');
      return;
    }

    // Update manifest with local path
    await _manifestDao.upsert(AssetManifestCompanion(
      contentHash: Value(op.contentHash),
      localPath: Value(localPath),
      localVerifiedAt: Value(DateTime.now()),
    ));

    await _opsDao.markCompleted(op.id);
  }

  Future<void> _executeVerify(
    SyncOperation op,
    CloudProvider provider,
  ) async {
    final copies = await _copiesDao.getByHash(op.contentHash);
    final remoteCopy = copies
        .where((c) => c.provider == provider.providerType)
        .firstOrNull;

    if (remoteCopy?.remotePath == null) {
      await _opsDao.markFailed(op.id, 'No remote path to verify');
      return;
    }

    final manifest = await _manifestDao.getByHash(op.contentHash);
    final isValid = await provider.verify(
      remotePath: remoteCopy!.remotePath!,
      expectedSize: manifest?.fileSizeBytes,
    );

    if (isValid) {
      await _copiesDao.markVerified(remoteCopy.id);
      await _opsDao.markCompleted(op.id);
    } else {
      await _copiesDao.markFailed(
        remoteCopy.id,
        'Remote verification failed',
      );
      await _opsDao.markFailed(op.id, 'Remote verification failed');
    }
  }

  Future<void> _executeDeleteRemote(
    SyncOperation op,
    CloudProvider provider,
  ) async {
    // Safety check: only delete remote if this is a tombstoned asset
    final manifest = await _manifestDao.getByHash(op.contentHash);
    if (manifest?.deletedAt == null) {
      await _opsDao.markFailed(
        op.id,
        'Cannot delete remote copy of non-tombstoned asset',
      );
      return;
    }

    final copies = await _copiesDao.getByHash(op.contentHash);
    final remoteCopy = copies
        .where((c) => c.provider == provider.providerType)
        .firstOrNull;

    if (remoteCopy?.remotePath == null) {
      await _opsDao.markCompleted(op.id); // Nothing to delete
      return;
    }

    await provider.delete(remotePath: remoteCopy!.remotePath!);
    await _copiesDao.deleteCopy(remoteCopy.id);
    await _opsDao.markCompleted(op.id);
  }

  /// Recover operations stuck in `in_progress` from a previous session crash.
  /// Re-queues them so they'll be processed in the normal queue pass.
  Future<void> _recoverStaleOps() async {
    final stale = await _opsDao.getInProgress();
    if (stale.isEmpty) return;
    debugPrint('Recovering ${stale.length} stale in_progress ops');
    for (final op in stale) {
      await _opsDao.requeueForRetry(op.id);
    }
  }

  /// Retry failed operations using exponential backoff.
  ///
  /// Delay formula: `min(2^retryCount * 5s, 300s)` — i.e. 5s, 10s, 20s, 40s…
  /// up to a 5 minute ceiling. Only retries if enough time has elapsed since
  /// the operation's `completedAt` (failure timestamp).
  static const _maxBackoffSeconds = 300; // 5 minutes

  Future<void> _retryFailed(ConnectionType connectionType) async {
    final retryable = await _opsDao.getRetryable();
    if (retryable.isEmpty) return;

    final now = DateTime.now();
    for (final op in retryable) {
      if (_state == SyncEngineState.paused) return;

      // Compute backoff delay: 2^retryCount * 5 seconds, capped at 5 min
      final delaySecs = (1 << op.retryCount) * 5;
      final backoff = Duration(
        seconds: delaySecs.clamp(0, _maxBackoffSeconds),
      );

      // Only retry if enough time has passed since the failure
      final failedAt = op.completedAt ?? op.createdAt;
      if (now.difference(failedAt) < backoff) continue;

      debugPrint(
        'Retrying op ${op.id} (attempt ${op.retryCount + 1})',
      );
      await _opsDao.requeueForRetry(op.id);
      await _executeOperation(op, connectionType);
    }
  }

  /// Log a video asset state transition to sync_log for auditability.
  ///
  /// Creates a traceable record when a video moves between states:
  /// local → cloud_only, cloud_only → local, present → missing, etc.
  /// The [reason] field captures _why_ the transition happened (e.g.
  /// "user freed space", "on-demand download", "file not found").
  Future<void> logStateTransition({
    required String contentHash,
    required String fromState,
    required String toState,
    required String reason,
  }) async {
    if (_syncDao == null) return;
    try {
      await _syncDao.logChange(
        entityId: contentHash,
        table: 'asset_manifest',
        action: 'state_transition:${fromState}_to_$toState:$reason',
      );
      debugPrint(
        '[AssetSync] State transition: $contentHash $fromState → $toState ($reason)',
      );
    } catch (e) {
      debugPrint('[AssetSync] Failed to log state transition: $e');
    }
  }

  void _setState(SyncEngineState newState) {
    _state = newState;
    _emitProgress();
  }

  Future<void> _emitProgress() async {
    try {
      final total = await _manifestDao.countLive();
      final underprotected = await _manifestDao.getUnderprotected();
      _progressController.add(SyncProgress(
        totalAssets: total,
        syncedAssets: total - underprotected.length,
        pendingUploads: underprotected.length,
        pendingDownloads: 0,
        activeTransfers: 0,
        state: _state,
      ));
    } catch (_) {
      // Non-fatal — progress is informational
    }
  }
}
