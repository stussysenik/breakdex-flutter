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
import 'provenance_journal_service.dart';

enum ManagedAlbumReconcileTrigger { startup, resume, libraryChanged }

class ManagedAlbumReconcileReport {
  const ManagedAlbumReconcileReport({
    required this.trigger,
    required this.trackedMoves,
    required this.archivedMoves,
    required this.recoveredMoves,
    required this.accessStatus,
    required this.completedAt,
  });

  final ManagedAlbumReconcileTrigger trigger;
  final int trackedMoves;
  final int archivedMoves;
  final int recoveredMoves;
  final PhotoLibraryAccessStatus accessStatus;
  final DateTime completedAt;

  bool get hasStartupSignal =>
      (accessStatus != PhotoLibraryAccessStatus.authorized &&
          accessStatus != PhotoLibraryAccessStatus.limited) ||
      archivedMoves > 0 ||
      recoveredMoves > 0;

  bool get hasDiscovery => archivedMoves > 0 || recoveredMoves > 0;

  String get snackBarMessage {
    if (recoveredMoves > 0) {
      return 'Recovered $recoveredMoves video${recoveredMoves == 1 ? '' : 's'} from your Photos library.';
    }
    if (archivedMoves > 0) {
      return 'Archived $archivedMoves move${archivedMoves == 1 ? '' : 's'} because their original videos were deleted.';
    }
    if (accessStatus == PhotoLibraryAccessStatus.denied ||
        accessStatus == PhotoLibraryAccessStatus.restricted) {
      return 'Photos access is off, so Breakdex cannot verify managed albums.';
    }
    return '';
  }
}

class ManagedAlbumReconciliationService {
  ManagedAlbumReconciliationService({
    required final MovesDao movesDao,
    required final MoveRepository moveRepository,
    required final MediaCleanupService mediaCleanupService,
    required final NativeVideoAlbum videoAlbum,
    required final VideoService videoService,
    final ProvenanceJournalService? provenanceJournal,
    final DateTime Function()? now,
  }) : _movesDao = movesDao,
       _moveRepository = moveRepository,
       _mediaCleanupService = mediaCleanupService,
       _videoAlbum = videoAlbum,
       _videoService = videoService,
       _provenanceJournal = provenanceJournal,
       _now = now ?? DateTime.now;

  final MovesDao _movesDao;
  final MoveRepository _moveRepository;
  final MediaCleanupService _mediaCleanupService;
  final NativeVideoAlbum _videoAlbum;
  final VideoService _videoService;
  final ProvenanceJournalService? _provenanceJournal;
  final DateTime Function() _now;

  Future<ManagedAlbumReconcileReport> reconcileExternalDeletes({
    final ManagedAlbumReconcileTrigger trigger = ManagedAlbumReconcileTrigger.startup,
  }) async {
    final activeMoves = await _movesDao.getAll();
    final trackedMoves = activeMoves.where(_hasManagedAlbumAssetId).toList();

    final accessStatus = await _videoAlbum.requestReadAccess();
    if (!accessStatus.allowsReadAccess) {
      final report = ManagedAlbumReconcileReport(
        trigger: trigger,
        trackedMoves: trackedMoves.length,
        archivedMoves: 0,
        recoveredMoves: 0,
        accessStatus: accessStatus,
        completedAt: _now(),
      );
      await _recordReconcileReport(report);
      return report;
    }

    final trackedReferences = trackedMoves
        .map((final move) {
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
        .toList();
    final reconcileResult = trackedReferences.isEmpty
        ? ManagedAssetReconcileResult.empty(accessStatus: accessStatus)
        : await _videoAlbum.reconcileManagedAssets(
            trackedReferences,
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

    final report = ManagedAlbumReconcileReport(
      trigger: trigger,
      trackedMoves: trackedMoves.length,
      archivedMoves: archivedCount,
      recoveredMoves: recoveredCount,
      accessStatus: reconcileResult.accessStatus,
      completedAt: _now(),
    );
    await _recordReconcileReport(report);
    return report;
  }

  Future<void> _recordReconcileReport(
    final ManagedAlbumReconcileReport report,
  ) async {
    final message =
        'trigger=${report.trigger.name} '
        'tracked=${report.trackedMoves} '
        'archived=${report.archivedMoves} '
        'recovered=${report.recoveredMoves} '
        'access=${report.accessStatus.name}';
    debugPrint('[ManagedAlbumRecovery] $message');
    final journal = _provenanceJournal;
    if (journal == null) return;
    await journal.log(
      scope: 'managed_album_recovery',
      eventType: 'reconcile_sweep_completed',
      status: report.accessStatus.name,
      entityType: 'photos_library',
      entityId: report.trigger.name,
      message: message,
    );
  }

  Future<void> restoreArchivedMove(final Move move) async {
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

  Future<void> permanentlyDeleteArchivedMove(final Move move) async {
    await _mediaCleanupService.cleanupMoveMedia(move);
    await _moveRepository.delete(move.id);
  }

  Future<int> purgeExpiredArchivedMoves({
    final Duration retention = moveArchiveRetention,
  }) async {
    final cutoff = _now().subtract(retention);
    final expiredMoves = await _movesDao.getExpiredArchived(cutoff);
    for (final move in expiredMoves) {
      await permanentlyDeleteArchivedMove(move);
    }
    return expiredMoves.length;
  }

  bool _hasManagedAlbumAssetId(final Move move) {
    final assetId = move.managedAlbumAssetId?.trim();
    return assetId != null && assetId.isNotEmpty;
  }

  Future<String> _ensureLocalVideoAvailable(final Move move) async {
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

  Future<bool> _recoverMissingLocalVideo(final Move move) async {
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
    } on Object catch (_) {
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
    required final ManagedAlbumReconciliationService service,
    required final NativeVideoAlbum videoAlbum,
  }) : _service = service,
       _videoAlbum = videoAlbum;

  final ManagedAlbumReconciliationService _service;
  final NativeVideoAlbum _videoAlbum;
  final StreamController<ManagedAlbumReconcileReport> _reports =
      StreamController<ManagedAlbumReconcileReport>.broadcast();

  StreamSubscription<Map<String, dynamic>>? _photoChangesSub;
  Future<void>? _runningSweep;
  ManagedAlbumReconcileReport? _latestReport;
  Timer? _debounceTimer;

  Stream<ManagedAlbumReconcileReport> get reports => _reports.stream;
  ManagedAlbumReconcileReport? get latestReport => _latestReport;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_ensureObservationAndSweep());
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    await _photoChangesSub?.cancel();
    await _reports.close();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(
      _ensureObservationAndSweep(trigger: ManagedAlbumReconcileTrigger.resume),
    );
  }

  Future<void> _ensureObservationAndSweep({
    final ManagedAlbumReconcileTrigger trigger = ManagedAlbumReconcileTrigger.startup,
  }) async {
    final sweep = _runningSweep;
    if (sweep != null) return sweep;

    final future = () async {
      final report = await _service.reconcileExternalDeletes(trigger: trigger);
      _latestReport = report;
      if (!_reports.isClosed) {
        _reports.add(report);
      }
      
      final shouldListen = report.accessStatus.allowsReadAccess && report.trackedMoves > 0;
      
      if (shouldListen && _photoChangesSub == null) {
        _photoChangesSub = _videoAlbum.libraryChangeStream.listen((final event) {
          if (event['type'] != 'libraryChanged') return;
          
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(seconds: 2), () {
            unawaited(
              _ensureObservationAndSweep(
                trigger: ManagedAlbumReconcileTrigger.libraryChanged,
              ),
            );
          });
        });
      } else if (!shouldListen && _photoChangesSub != null) {
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
