// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.  discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: avoid_slow_async_io, discarded_futures

import 'dart:async';
import 'package:breakdex/core/platform/io.dart';

import 'package:drift/drift.dart' show Value;

import 'package:breakdex/core/database/daos/asset_copies_dao.dart';
import 'package:breakdex/core/database/daos/asset_manifest_dao.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/canonical_asset.dart';
import 'package:breakdex/core/sync/asset_hash_service.dart';
import 'package:breakdex/core/services/canonical_folder_service.dart';
import 'package:breakdex/core/services/canonical_import_gate.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';

enum ImportPhase {
  idle,
  hashing,
  gateCheck,
  copying,
  verifying,
  recordingManifest,
  complete,
  failed,
}

class ImportStateMachine {
  final CanonicalImportGate _gate;
  final CanonicalFolderService _folderService;
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;
  final AssetHashService _hashService;

  final _stateController = StreamController<ImportState>.broadcast();
  final _timeoutController = StreamController<bool>.broadcast();

  Timer? _phaseTimer;
  ImportState _current = const ImportState.idle();

  ImportState get state => _current;
  Stream<ImportState> get stateStream => _stateController.stream;

  ImportStateMachine({
    required final CanonicalImportGate gate,
    required final CanonicalFolderService folderService,
    required final AssetManifestDao manifestDao,
    required final AssetCopiesDao copiesDao,
    required final AssetHashService hashService,
    this.phaseTimeout = const Duration(seconds: 60),
  }) : _gate = gate,
       _folderService = folderService,
       _manifestDao = manifestDao,
       _copiesDao = copiesDao,
       _hashService = hashService;

  final Duration phaseTimeout;

  Future<CanonicalAssetLive> import({
    required final String sourcePath,
    required final String displayName,
    required final AssetSource source,
  }) async {
    _transition(ImportPhase.hashing, progress: 0.0);

    try {
      final hash = await _withPhaseTimeout(
        _hashService.computeHash(sourcePath),
        ImportPhase.hashing,
      );
      _transition(ImportPhase.hashing, progress: 1.0, hash: hash);

      _transition(ImportPhase.gateCheck, progress: 0.0, hash: hash);
      final gateResult = await _withPhaseTimeout(
        _gate.check(sourcePath: sourcePath, displayName: displayName),
        ImportPhase.gateCheck,
      );

      switch (gateResult) {
        case GateAllowed():
          _transition(ImportPhase.gateCheck, progress: 1.0);
        case GateDuplicateContent():
          final h = gateResult.existingHash;
          _transition(ImportPhase.complete, progress: 1.0, hash: h);
          return CanonicalAssetLive(
            localPath: await _folderService.canonicalPathForHash(h),
            hash: h,
            fileSizeBytes: await File(sourcePath).length(),
            source: source,
            importedAt: DateTime.now(),
          );
        case GateBlocked():
          throw _ImportException(gateResult.reason);
        case GateNameConflict():
          throw _ImportException(
            'Name conflict: "${gateResult.conflictingName}" already exists',
          );
      }

      _transition(ImportPhase.copying, progress: 0.0);
      final canonicalPath = await _withPhaseTimeout(
        _folderService.copyToCanonical(sourcePath, _current.hash),
        ImportPhase.copying,
      );
      _transition(ImportPhase.copying, progress: 1.0);

      _transition(ImportPhase.verifying, progress: 0.0);
      final canonicalHash = await _withPhaseTimeout(
        _hashService.computeHash(canonicalPath),
        ImportPhase.verifying,
      );
      if (canonicalHash != _current.hash) {
        throw const _ImportException(
          'Content hash mismatch after copy — integrity check failed',
        );
      }
      _transition(ImportPhase.verifying, progress: 1.0);

      _transition(ImportPhase.recordingManifest, progress: 0.0);
      final file = File(canonicalPath);
      final stat = await file.stat();
      final now = DateTime.now();

      await _withPhaseTimeout(
        _manifestDao.upsert(
          AssetManifestCompanion.insert(
            contentHash: canonicalHash,
            fileSizeBytes: stat.size,
            localPath: Value(VideoPathResolver.toRelative(canonicalPath)),
            localVerifiedAt: Value(now),
            sourceType: source.name,
            sourceName: Value(displayName),
            importedAt: now,
            mimeType: const Value('video/mp4'),
          ),
        ),
        ImportPhase.recordingManifest,
      );

      final copyId = AssetCopiesDao.copyId(canonicalHash, 'local');
      await _copiesDao.upsertCopy(
        AssetCopiesCompanion.insert(
          id: copyId,
          contentHash: canonicalHash,
          provider: 'local',
          status: const Value('verified'),
          verifiedAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _manifestDao.updateCopyCount(canonicalHash);

      await _folderService.upsertLedgerEntry(
        LedgerEntry(
          fileName: canonicalPath.split('/').last,
          fileSizeBytes: stat.size,
          lastSeenAt: stat.modified,
          recordedAt: now,
        ),
      );

      final result = CanonicalAssetLive(
        localPath: canonicalPath,
        hash: canonicalHash,
        fileSizeBytes: stat.size,
        source: source,
        importedAt: now,
        lastVerifiedAt: now,
        copyCount: 1,
        provenance: const ProvenanceTrail.empty().add(
          AssetProvenanceEntry(
            eventType: 'imported',
            recordedAt: now,
            detail: 'source: ${source.name}, name: $displayName',
          ),
        ),
      );

      _transition(ImportPhase.complete, progress: 1.0, asset: result);
      return result;
    } on _ImportException {
      _transition(ImportPhase.failed, progress: 0.0, error: state.error);
      rethrow;
    } catch (e) {
      _transition(ImportPhase.failed, progress: 0.0, error: '$e');
      rethrow;
    } finally {
      _clearPhaseTimer();
    }
  }

  void _transition(
    final ImportPhase phase, {
    final double? progress,
    final String? hash,
    final CanonicalAssetLive? asset,
    final String? error,
  }) {
    _current = ImportState(
      phase: phase,
      progress: progress ?? _current.progress,
      hash: hash ?? _current.hash,
      asset: asset,
      error: error,
    );
    _stateController.add(_current);
  }

  Future<T> _withPhaseTimeout<T>(final Future<T> operation, final ImportPhase phase) async {
    _startPhaseTimer(phase);
    try {
      return await operation.timeout(
        phaseTimeout,
        onTimeout: () => throw _ImportException(
          '${phase.name} phase timed out after ${phaseTimeout.inSeconds}s',
        ),
      );
    } finally {
      _clearPhaseTimer();
    }
  }

  void _startPhaseTimer(final ImportPhase phase) {
    _clearPhaseTimer();
    _phaseTimer = Timer(phaseTimeout, () {
      _timeoutController.add(true);
    });
  }

  void _clearPhaseTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
  }

  void dispose() {
    _clearPhaseTimer();
    _stateController.close();
    _timeoutController.close();
  }
}

class ImportState {
  final ImportPhase phase;
  final double progress;
  final String hash;
  final CanonicalAssetLive? asset;
  final String? error;

  const ImportState({
    this.phase = ImportPhase.idle,
    this.progress = 0.0,
    this.hash = '',
    this.asset,
    this.error,
  });

  const ImportState.idle()
    : phase = ImportPhase.idle,
      progress = 0.0,
      hash = '',
      asset = null,
      error = null;

  bool get isTerminal =>
      phase == ImportPhase.complete || phase == ImportPhase.failed;
  bool get isComplete => phase == ImportPhase.complete;
  bool get hasError => phase == ImportPhase.failed || error != null;
}

class _ImportException implements Exception {
  final String message;
  const _ImportException(this.message);
  @override
  String toString() => message;
}
