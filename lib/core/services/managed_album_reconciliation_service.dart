import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';

import '../data/repositories.dart';
import '../database/daos/moves_dao.dart';
import '../database/database.dart';
import '../models/move_archive_reason.dart';
import '../models/reviewable_item.dart';
import 'media_cleanup_service.dart';
import 'native_video_album.dart';
import 'video_path_resolver.dart';
import 'video_service.dart';

class ManagedAlbumReconcileReport {
  const ManagedAlbumReconcileReport({
    required this.trackedMoves,
    required this.archivedMoves,
    required this.recoveredMoves,
    required this.accessStatus,
  });

  final int trackedMoves;
  final int archivedMoves;
  final int recoveredMoves;
  final PhotoLibraryAccessStatus accessStatus;
}

class ManagedAlbumReconciliationService {
  ManagedAlbumReconciliationService({
    required MovesDao movesDao,
    required MoveRepository moveRepository,
    required MediaCleanupService mediaCleanupService,
    required NativeVideoAlbum videoAlbum,
    required VideoService videoService,
    DateTime Function()? now,
  }) : _movesDao = movesDao,
       _moveRepository = moveRepository,
       _mediaCleanupService = mediaCleanupService,
       _videoAlbum = videoAlbum,
       _videoService = videoService,
       _now = now ?? DateTime.now;

  final MovesDao _movesDao;
  final MoveRepository _moveRepository;
  final MediaCleanupService _mediaCleanupService;
  final NativeVideoAlbum _videoAlbum;
  final VideoService _videoService;
  final DateTime Function() _now;

  Future<ManagedAlbumReconcileReport> reconcileExternalDeletes() async {
    final trackedMoves = await _movesDao.getTrackedManagedAlbumMoves();
    if (trackedMoves.isEmpty) {
      return const ManagedAlbumReconcileReport(
        trackedMoves: 0,
        archivedMoves: 0,
        recoveredMoves: 0,
        accessStatus: PhotoLibraryAccessStatus.unknown,
      );
    }

    final accessStatus = await _videoAlbum.requestReadAccess();
    if (!accessStatus.allowsReadAccess) {
      return ManagedAlbumReconcileReport(
        trackedMoves: trackedMoves.length,
        archivedMoves: 0,
        recoveredMoves: 0,
        accessStatus: accessStatus,
      );
    }

    final reconcileResult = await _videoAlbum.reconcileManagedAssets(
      trackedMoves
          .map((move) {
            final assetLocalIdentifier = move.managedAlbumAssetId;
            final albumName = move.managedAlbumName;
            if (assetLocalIdentifier == null || albumName == null) return null;
            return ManagedAssetReference(
              moveId: move.id,
              assetLocalIdentifier: assetLocalIdentifier,
              albumName: albumName,
            );
          })
          .whereType<ManagedAssetReference>()
          .toList(),
      source: 'sweep',
    );
    var archivedCount = 0;
    final archivedMoveIds = <String>{};
    final trackedById = {for (final move in trackedMoves) move.id: move};
    for (final event in reconcileResult.events) {
      final move = trackedById[event.moveId];
      if (move == null) continue;
      await _moveRepository.update(
        MovesCompanion(
          id: Value(move.id),
          archivedAt: Value(_now()),
          archiveReason: Value(switch (event.type) {
            ManagedAssetReconcileEventType.assetDeletedFromLibrary =>
              MoveArchiveReason.externalAlbumDelete.dbValue,
            ManagedAssetReconcileEventType.assetRemovedFromManagedAlbum =>
              MoveArchiveReason.removedFromManagedAlbum.dbValue,
          }),
          managedAlbumAssetId: const Value(null),
          managedAlbumFilename: const Value(null),
          managedAlbumName: const Value(null),
        ),
      );
      archivedMoveIds.add(move.id);
      archivedCount++;
    }

    var recoveredCount = 0;
    for (final move in trackedMoves) {
      if (archivedMoveIds.contains(move.id)) continue;
      final recovered = await _recoverMissingLocalVideo(move);
      if (recovered) recoveredCount++;
    }

    return ManagedAlbumReconcileReport(
      trackedMoves: trackedMoves.length,
      archivedMoves: archivedCount,
      recoveredMoves: recoveredCount,
      accessStatus: reconcileResult.accessStatus,
    );
  }

  Future<void> restoreArchivedMove(Move move) async {
    final resolvedVideoPath = await _ensureLocalVideoAvailable(move);
    final archiveReason = MoveArchiveReason.fromDbValue(move.archiveReason);

    ManagedAlbumCopy? managedCopy;
    if (archiveReason == MoveArchiveReason.externalAlbumDelete ||
        archiveReason == MoveArchiveReason.removedFromManagedAlbum) {
      managedCopy = await _videoAlbum.saveToAlbum(
        videoPath: resolvedVideoPath,
        albumName: NativeVideoAlbum.defaultAlbumName(),
        assetTitle: move.name,
        category: move.category,
      );
      if (managedCopy == null) {
        throw StateError('Breakdex could not recreate the managed album copy.');
      }
    }

    await _moveRepository.update(
      MovesCompanion(
        id: Value(move.id),
        archivedAt: const Value(null),
        archiveReason: const Value(null),
        managedAlbumAssetId: managedCopy == null
            ? const Value.absent()
            : Value(managedCopy.assetLocalIdentifier),
        managedAlbumFilename: managedCopy == null
            ? const Value.absent()
            : Value(managedCopy.filename),
        managedAlbumName: managedCopy == null
            ? const Value.absent()
            : Value(managedCopy.albumName),
      ),
    );
  }

  Future<void> permanentlyDeleteArchivedMove(Move move) async {
    await _mediaCleanupService.cleanupMoveMedia(move);
    await _moveRepository.delete(move.id);
  }

  Future<int> purgeExpiredArchivedMoves({
    Duration retention = moveArchiveRetention,
  }) async {
    final cutoff = _now().subtract(retention);
    final expiredMoves = await _movesDao.getExpiredArchived(cutoff);
    for (final move in expiredMoves) {
      await permanentlyDeleteArchivedMove(move);
    }
    return expiredMoves.length;
  }

  Future<String> _ensureLocalVideoAvailable(Move move) async {
    final resolvedVideoPath = move.resolvedVideoPath;
    if (resolvedVideoPath != null) {
      final videoStatus = await _videoService.checkVideoFileWithRetry(
        resolvedVideoPath,
      );
      if (videoStatus == VideoFileStatus.ready) {
        return resolvedVideoPath;
      }
    }

    final managedAlbumAssetId = move.managedAlbumAssetId;
    if (managedAlbumAssetId == null || managedAlbumAssetId.trim().isEmpty) {
      throw StateError('The archived move no longer has a recoverable video.');
    }

    final restored = await _videoAlbum.restoreManagedAsset(managedAlbumAssetId);
    if (restored == null) {
      throw StateError('Breakdex could not recover the managed Photos asset.');
    }

    await _moveRepository.update(
      MovesCompanion(
        id: Value(move.id),
        videoPath: Value(VideoPathResolver.toRelative(restored.localPath)),
        originalVideoName: move.originalVideoName == null
            ? Value(restored.originalFileName)
            : const Value.absent(),
      ),
    );
    return restored.localPath;
  }

  Future<bool> _recoverMissingLocalVideo(Move move) async {
    final resolvedVideoPath = move.resolvedVideoPath;
    if (resolvedVideoPath != null) {
      final videoStatus = await _videoService.checkVideoFileWithRetry(
        resolvedVideoPath,
      );
      if (videoStatus == VideoFileStatus.ready) {
        return false;
      }
    }

    final managedAlbumAssetId = move.managedAlbumAssetId;
    if (managedAlbumAssetId == null || managedAlbumAssetId.trim().isEmpty) {
      await _moveRepository.update(
        MovesCompanion(
          id: Value(move.id),
          archivedAt: Value(_now()),
          archiveReason: Value(MoveArchiveReason.missingLocalVideo.dbValue),
        ),
      );
      return false;
    }

    try {
      final restored = await _videoAlbum.restoreManagedAsset(
        managedAlbumAssetId,
      );
      if (restored == null) {
        throw StateError('Managed asset restore returned null');
      }

      await _moveRepository.update(
        MovesCompanion(
          id: Value(move.id),
          videoPath: Value(VideoPathResolver.toRelative(restored.localPath)),
          originalVideoName: move.originalVideoName == null
              ? Value(restored.originalFileName)
              : const Value.absent(),
        ),
      );
      return true;
    } catch (_) {
      await _moveRepository.update(
        MovesCompanion(
          id: Value(move.id),
          archivedAt: Value(_now()),
          archiveReason: Value(MoveArchiveReason.missingLocalVideo.dbValue),
        ),
      );
      return false;
    }
  }
}

class ManagedAlbumLifecycleController with WidgetsBindingObserver {
  ManagedAlbumLifecycleController({
    required ManagedAlbumReconciliationService service,
    required NativeVideoAlbum videoAlbum,
  }) : _service = service,
       _videoAlbum = videoAlbum;

  final ManagedAlbumReconciliationService _service;
  final NativeVideoAlbum _videoAlbum;

  StreamSubscription<Map<String, dynamic>>? _photoChangesSub;
  Future<void>? _runningSweep;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_ensureObservationAndSweep());
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _photoChangesSub?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_ensureObservationAndSweep());
  }

  Future<void> _ensureObservationAndSweep() async {
    final sweep = _runningSweep;
    if (sweep != null) return sweep;

    final future = () async {
      final report = await _service.reconcileExternalDeletes();
      if (report.accessStatus.allowsReadAccess && _photoChangesSub == null) {
        _photoChangesSub = _videoAlbum.libraryChangeStream.listen((event) {
          if (event['type'] != 'libraryChanged') return;
          unawaited(_service.reconcileExternalDeletes());
        });
      } else if (!report.accessStatus.allowsReadAccess &&
          _photoChangesSub != null) {
        await _photoChangesSub?.cancel();
        _photoChangesSub = null;
      }
      await _service.purgeExpiredArchivedMoves();
    }();

    _runningSweep = future;
    try {
      await future;
    } finally {
      _runningSweep = null;
    }
  }
}
