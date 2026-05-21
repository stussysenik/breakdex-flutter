import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';

import '../data/repositories.dart';
import '../database/daos/moves_dao.dart';
import '../database/database.dart';
import '../models/move_archive_reason.dart';
import '../models/move_creation.dart';
import '../models/reviewable_item.dart';
import 'media_cleanup_service.dart';
import 'move_creation_service.dart';
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
    required this.historicalAssetsDiscovered,
    required this.historicalAssetsUntracked,
    required this.historicalAssetsRecovered,
    required this.historicalRestoreFailures,
    required this.historicalMatchingAlbums,
    required this.historicalVideoAssetsSeen,
    required this.historicalAssetsSkippedMissingFilename,
    required this.completedAt,
  });

  final ManagedAlbumReconcileTrigger trigger;
  final int trackedMoves;
  final int archivedMoves;
  final int recoveredMoves;
  final PhotoLibraryAccessStatus accessStatus;
  final int historicalAssetsDiscovered;
  final int historicalAssetsUntracked;
  final int historicalAssetsRecovered;
  final int historicalRestoreFailures;
  final int historicalMatchingAlbums;
  final int historicalVideoAssetsSeen;
  final int historicalAssetsSkippedMissingFilename;
  final DateTime completedAt;

  int get historicalAssetsStillPending {
    final pending = historicalAssetsUntracked - historicalAssetsRecovered;
    return pending < 0 ? 0 : pending;
  }

  bool get hasStartupSignal =>
      accessStatus != PhotoLibraryAccessStatus.authorized ||
      historicalMatchingAlbums > 0 ||
      historicalAssetsRecovered > 0 ||
      historicalAssetsStillPending > 0;

  String get snackBarMessage {
    if (accessStatus == PhotoLibraryAccessStatus.denied ||
        accessStatus == PhotoLibraryAccessStatus.restricted) {
      return 'Photos access is off, so Breakdex cannot inspect historical albums yet.';
    }
    if (accessStatus == PhotoLibraryAccessStatus.limited) {
      return 'Photos access is limited, so some historical Breakdex albums may stay hidden.';
    }
    if (historicalAssetsRecovered > 0 && historicalAssetsStillPending > 0) {
      return 'Recovered $historicalAssetsRecovered historical album video${historicalAssetsRecovered == 1 ? '' : 's'}. $historicalAssetsStillPending still need attention.';
    }
    if (historicalAssetsRecovered > 0) {
      return 'Recovered $historicalAssetsRecovered historical album video${historicalAssetsRecovered == 1 ? '' : 's'} from Photos.';
    }
    if (historicalAssetsStillPending > 0) {
      return 'Found $historicalAssetsUntracked historical album video${historicalAssetsUntracked == 1 ? '' : 's'}, but $historicalAssetsStillPending could not be linked yet.';
    }
    if (historicalMatchingAlbums > 0 &&
        historicalAssetsSkippedMissingFilename > 0 &&
        historicalAssetsDiscovered == 0) {
      return 'Found $historicalMatchingAlbums Breakdex album${historicalMatchingAlbums == 1 ? '' : 's'}, but iPhone did not expose readable video filenames yet.';
    }
    if (historicalMatchingAlbums > 0 && historicalAssetsDiscovered == 0) {
      return 'Found $historicalMatchingAlbums Breakdex album${historicalMatchingAlbums == 1 ? '' : 's'}, but no recoverable videos were linked on startup.';
    }
    if (historicalMatchingAlbums == 0) {
      return 'No Breakdex historical albums were found in Photos on startup.';
    }
    return 'Checked historical Breakdex albums on startup.';
  }
}

class _HistoricalRecoverySummary {
  const _HistoricalRecoverySummary({
    required this.discoveredAssets,
    required this.untrackedAssets,
    required this.recoveredAssets,
    required this.restoreFailures,
    required this.matchingAlbums,
    required this.videoAssetsSeen,
    required this.skippedMissingFilenameAssets,
  });

  final int discoveredAssets;
  final int untrackedAssets;
  final int recoveredAssets;
  final int restoreFailures;
  final int matchingAlbums;
  final int videoAssetsSeen;
  final int skippedMissingFilenameAssets;
}

class ManagedAlbumReconciliationService {
  ManagedAlbumReconciliationService({
    required MovesDao movesDao,
    required MoveRepository moveRepository,
    required MoveCreationService moveCreationService,
    required MediaCleanupService mediaCleanupService,
    required NativeVideoAlbum videoAlbum,
    required VideoService videoService,
    ProvenanceJournalService? provenanceJournal,
    DateTime Function()? now,
  }) : _movesDao = movesDao,
       _moveRepository = moveRepository,
       _moveCreationService = moveCreationService,
       _mediaCleanupService = mediaCleanupService,
       _videoAlbum = videoAlbum,
       _videoService = videoService,
       _provenanceJournal = provenanceJournal,
       _now = now ?? DateTime.now;

  final MovesDao _movesDao;
  final MoveRepository _moveRepository;
  final MoveCreationService _moveCreationService;
  final MediaCleanupService _mediaCleanupService;
  final NativeVideoAlbum _videoAlbum;
  final VideoService _videoService;
  final ProvenanceJournalService? _provenanceJournal;
  final DateTime Function() _now;

  Future<ManagedAlbumReconcileReport> reconcileExternalDeletes({
    ManagedAlbumReconcileTrigger trigger = ManagedAlbumReconcileTrigger.startup,
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
        historicalAssetsDiscovered: 0,
        historicalAssetsUntracked: 0,
        historicalAssetsRecovered: 0,
        historicalRestoreFailures: 0,
        historicalMatchingAlbums: 0,
        historicalVideoAssetsSeen: 0,
        historicalAssetsSkippedMissingFilename: 0,
        completedAt: _now(),
      );
      await _recordReconcileReport(report);
      return report;
    }

    final trackedReferences = trackedMoves
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

    final historicalRecovery = await _recoverHistoricalManagedAssets(
      activeMoves.where((move) => !archivedMoveIds.contains(move.id)).toList(),
    );
    recoveredCount += historicalRecovery.recoveredAssets;

    final report = ManagedAlbumReconcileReport(
      trigger: trigger,
      trackedMoves: trackedMoves.length,
      archivedMoves: archivedCount,
      recoveredMoves: recoveredCount,
      accessStatus: reconcileResult.accessStatus,
      historicalAssetsDiscovered: historicalRecovery.discoveredAssets,
      historicalAssetsUntracked: historicalRecovery.untrackedAssets,
      historicalAssetsRecovered: historicalRecovery.recoveredAssets,
      historicalRestoreFailures: historicalRecovery.restoreFailures,
      historicalMatchingAlbums: historicalRecovery.matchingAlbums,
      historicalVideoAssetsSeen: historicalRecovery.videoAssetsSeen,
      historicalAssetsSkippedMissingFilename:
          historicalRecovery.skippedMissingFilenameAssets,
      completedAt: _now(),
    );
    await _recordReconcileReport(report);
    return report;
  }

  Future<void> _recordReconcileReport(
    ManagedAlbumReconcileReport report,
  ) async {
    final message =
        'trigger=${report.trigger.name} '
        'tracked=${report.trackedMoves} '
        'archived=${report.archivedMoves} '
        'recovered=${report.recoveredMoves} '
        'albums=${report.historicalMatchingAlbums} '
        'videos=${report.historicalVideoAssetsSeen} '
        'discoverable=${report.historicalAssetsDiscovered} '
        'untracked=${report.historicalAssetsUntracked} '
        'restored=${report.historicalAssetsRecovered} '
        'restoreFailures=${report.historicalRestoreFailures} '
        'missingFilename=${report.historicalAssetsSkippedMissingFilename} '
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

  bool _hasManagedAlbumAssetId(Move move) {
    final assetId = move.managedAlbumAssetId?.trim();
    return assetId != null && assetId.isNotEmpty;
  }

  bool _hasManagedAlbumMetadata(Move move) {
    final assetId = move.managedAlbumAssetId?.trim();
    final filename = move.managedAlbumFilename?.trim();
    final albumName = move.managedAlbumName?.trim();
    return assetId != null &&
        assetId.isNotEmpty &&
        filename != null &&
        filename.isNotEmpty &&
        albumName != null &&
        albumName.isNotEmpty;
  }

  Future<bool> _hasReadyLocalVideo(Move move) async {
    final resolvedVideoPath = move.resolvedVideoPath;
    if (resolvedVideoPath == null) return false;
    final videoStatus = await _videoService.checkVideoFileWithRetry(
      resolvedVideoPath,
    );
    return videoStatus == VideoFileStatus.ready;
  }

  bool _isHistoricalRecoveryCandidate(Move move, bool hasReadyLocalVideo) =>
      !_hasManagedAlbumMetadata(move) ||
      (!hasReadyLocalVideo && !_hasManagedAlbumAssetId(move));

  Future<_HistoricalRecoverySummary> _recoverHistoricalManagedAssets(
    List<Move> moves,
  ) async {
    final candidates = <({Move move, bool hasReadyLocalVideo})>[];
    for (final move in moves) {
      final hasReadyLocalVideo = await _hasReadyLocalVideo(move);
      if (_isHistoricalRecoveryCandidate(move, hasReadyLocalVideo)) {
        candidates.add((move: move, hasReadyLocalVideo: hasReadyLocalVideo));
      }
    }

    final discovery = await _videoAlbum.discoverRecoverableManagedAssets();
    if (!discovery.accessStatus.allowsReadAccess) {
      return const _HistoricalRecoverySummary(
        discoveredAssets: 0,
        untrackedAssets: 0,
        recoveredAssets: 0,
        restoreFailures: 0,
        matchingAlbums: 0,
        videoAssetsSeen: 0,
        skippedMissingFilenameAssets: 0,
      );
    }

    if (discovery.assets.isEmpty) {
      return _HistoricalRecoverySummary(
        discoveredAssets: 0,
        untrackedAssets: 0,
        recoveredAssets: 0,
        restoreFailures: 0,
        matchingAlbums: discovery.matchingAlbumCount,
        videoAssetsSeen: discovery.videoAssetCount,
        skippedMissingFilenameAssets: discovery.skippedMissingFilenameCount,
      );
    }

    final trackedAssetIds = moves
        .map((move) => move.managedAlbumAssetId?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet();
    final usedAssetIds = {...trackedAssetIds};
    final untrackedAssets = discovery.assets
        .where((asset) => !trackedAssetIds.contains(asset.assetLocalIdentifier))
        .length;
    var recoveredCount = 0;
    var restoreFailures = 0;
    for (final candidate in candidates) {
      final match = _matchRecoverableManagedAsset(
        candidate.move,
        discovery.assets,
        usedAssetIds,
      );
      if (match == null) continue;

      ManagedAssetRestoreResult? restored;
      if (!candidate.hasReadyLocalVideo) {
        try {
          restored = await _videoAlbum.restoreManagedAsset(
            match.assetLocalIdentifier,
          );
        } catch (_) {
          restoreFailures++;
          continue;
        }
        if (restored == null) {
          restoreFailures++;
          continue;
        }
      }

      await _moveRepository.update(
        MovesCompanion(
          id: Value(candidate.move.id),
          managedAlbumAssetId: Value(match.assetLocalIdentifier),
          managedAlbumFilename: Value(match.filename),
          managedAlbumName: Value(match.albumName),
          videoPath: restored == null
              ? const Value.absent()
              : Value(VideoPathResolver.toRelative(restored.localPath)),
          originalVideoName:
              restored != null &&
                  (candidate.move.originalVideoName == null ||
                      candidate.move.originalVideoName!.trim().isEmpty)
              ? Value(restored.originalFileName)
              : const Value.absent(),
        ),
      );
      usedAssetIds.add(match.assetLocalIdentifier);
      recoveredCount++;
    }

    for (final asset in discovery.assets) {
      if (usedAssetIds.contains(asset.assetLocalIdentifier)) continue;

      final moveDraft = _draftRecoveredMove(asset);
      ManagedAssetRestoreResult? restored;
      try {
        restored = await _videoAlbum.restoreManagedAsset(
          asset.assetLocalIdentifier,
        );
      } catch (_) {
        restoreFailures++;
        continue;
      }
      if (restored == null) {
        restoreFailures++;
        continue;
      }

      await _moveCreationService.createRecoveredMove(
        CreateRecoveredMoveRequest(
          preferredName: moveDraft.name,
          category: moveDraft.category,
          localVideoPath: restored.localPath,
          originalVideoName: restored.originalFileName,
          managedAlbumAssetId: asset.assetLocalIdentifier,
          managedAlbumFilename: asset.filename,
          managedAlbumName: asset.albumName,
        ),
      );
      usedAssetIds.add(asset.assetLocalIdentifier);
      recoveredCount++;
    }
    return _HistoricalRecoverySummary(
      discoveredAssets: discovery.assets.length,
      untrackedAssets: untrackedAssets,
      recoveredAssets: recoveredCount,
      restoreFailures: restoreFailures,
      matchingAlbums: discovery.matchingAlbumCount,
      videoAssetsSeen: discovery.videoAssetCount,
      skippedMissingFilenameAssets: discovery.skippedMissingFilenameCount,
    );
  }

  RecoverableManagedAsset? _matchRecoverableManagedAsset(
    Move move,
    List<RecoverableManagedAsset> assets,
    Set<String> usedAssetIds,
  ) {
    final comparisonKeys = _comparisonKeysForMove(move);
    if (comparisonKeys.isEmpty) return null;

    RecoverableManagedAsset? bestMatch;
    var bestScore = 0;
    for (final asset in assets) {
      if (usedAssetIds.contains(asset.assetLocalIdentifier)) continue;
      final score = _historicalMatchScore(
        move,
        asset,
        comparisonKeys: comparisonKeys,
      );
      if (score > bestScore) {
        bestScore = score;
        bestMatch = asset;
      }
    }
    return bestScore >= 160 ? bestMatch : null;
  }

  Set<String> _comparisonKeysForMove(Move move) {
    final keys = <String>{};

    void add(String? value) {
      final normalized = _normalizedComparisonKey(value);
      if (normalized.isNotEmpty) keys.add(normalized);
    }

    add(move.originalVideoName);
    add(move.managedAlbumFilename);
    add(move.name);
    if (move.category.trim().isNotEmpty && move.category.trim() != 'default') {
      add('${move.name} ${move.category}');
    }

    for (final extension in _fileExtensionCandidates(move)) {
      add(
        NativeVideoAlbum.semanticFilename(
          assetTitle: move.name,
          category: move.category,
          fileExtension: extension,
        ),
      );
      add(
        NativeVideoAlbum.semanticFilename(
          assetTitle: move.name,
          fileExtension: extension,
        ),
      );
    }
    return keys;
  }

  int _historicalMatchScore(
    Move move,
    RecoverableManagedAsset asset, {
    required Set<String> comparisonKeys,
  }) {
    final assetFilenameKey = _normalizedComparisonKey(asset.filename);
    final assetAlbumKey = _normalizedComparisonKey(asset.albumName);
    final assetCombinedKey = [
      assetFilenameKey,
      assetAlbumKey,
    ].where((value) => value.isNotEmpty).join(' ');
    final moveNameKey = _normalizedComparisonKey(move.name);
    final moveNameTokens = _comparisonTokens(move.name);
    final categoryTokens = move.category.trim().toLowerCase() == 'default'
        ? const <String>{}
        : _comparisonTokens(move.category);

    if (comparisonKeys.contains(assetFilenameKey)) {
      return 1000 + _historicalAlbumSignalScore(assetAlbumKey);
    }

    var score = 0;
    for (final key in comparisonKeys) {
      if (key.isEmpty) continue;
      if (assetFilenameKey.contains(key) || key.contains(assetFilenameKey)) {
        score = score < 700 ? 700 : score;
      } else if (assetCombinedKey.contains(key) ||
          key.contains(assetCombinedKey)) {
        score = score < 620 ? 620 : score;
      }
    }

    final combinedTokens = {
      ..._comparisonTokens(asset.filename),
      ..._comparisonTokens(asset.albumName),
    };
    final nameOverlap = _tokenOverlapCount(moveNameTokens, combinedTokens);
    final categoryOverlap = _tokenOverlapCount(categoryTokens, combinedTokens);

    if (moveNameKey.isNotEmpty && assetFilenameKey.contains(moveNameKey)) {
      score += 180;
    } else if (moveNameKey.isNotEmpty &&
        assetCombinedKey.contains(moveNameKey)) {
      score += 90;
    }

    score += nameOverlap * 120;
    score += categoryOverlap * 35;
    if (categoryTokens.isNotEmpty && categoryOverlap == categoryTokens.length) {
      score += 40;
    }
    score += _historicalAlbumSignalScore(assetAlbumKey);
    return score;
  }

  Set<String> _comparisonTokens(String? value) {
    final normalized = _normalizedComparisonKey(value);
    if (normalized.isEmpty) return const <String>{};
    return normalized.split(' ').where((token) => token.isNotEmpty).toSet();
  }

  int _tokenOverlapCount(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    var count = 0;
    for (final token in a) {
      if (b.contains(token)) count++;
    }
    return count;
  }

  int _historicalAlbumSignalScore(String albumKey) {
    if (albumKey.isEmpty) return 0;
    if (NativeVideoAlbum.breakdexAlbumPattern.hasMatch(albumKey)) {
      return 30;
    }
    return 0;
  }

  ({String name, String category}) _draftRecoveredMove(
    RecoverableManagedAsset asset,
  ) {
    final baseName = asset.filename
        .trim()
        .replaceFirst(RegExp(r'\.[^.]+$'), '')
        .trim();
    if (baseName.isEmpty) {
      return (name: 'Recovered Clip', category: 'default');
    }

    final segments = baseName
        .split(RegExp(r'\s+-\s+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (segments.length < 2) {
      return (name: baseName, category: 'default');
    }

    final category = segments.removeLast();
    final preferredName = segments.join(' - ').trim();
    return (
      name: preferredName.isEmpty ? baseName : preferredName,
      category: category.isEmpty ? 'default' : category,
    );
  }

  Set<String> _fileExtensionCandidates(Move move) => {
    'mp4',
    'mov',
    ?_fileExtensionFrom(move.originalVideoName),
    ?_fileExtensionFrom(move.managedAlbumFilename),
    ?_fileExtensionFrom(move.videoPath),
  };

  String? _fileExtensionFrom(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final dotIndex = trimmed.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == trimmed.length - 1) return null;
    return trimmed.substring(dotIndex + 1).toLowerCase();
  }

  String _normalizedComparisonKey(String? value) {
    final trimmed = value?.trim().toLowerCase() ?? '';
    if (trimmed.isEmpty) return '';
    final withoutExtension = trimmed.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return withoutExtension
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
  final StreamController<ManagedAlbumReconcileReport> _reports =
      StreamController<ManagedAlbumReconcileReport>.broadcast();

  StreamSubscription<Map<String, dynamic>>? _photoChangesSub;
  Future<void>? _runningSweep;
  ManagedAlbumReconcileReport? _latestReport;

  Stream<ManagedAlbumReconcileReport> get reports => _reports.stream;
  ManagedAlbumReconcileReport? get latestReport => _latestReport;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_ensureObservationAndSweep());
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _photoChangesSub?.cancel();
    await _reports.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(
      _ensureObservationAndSweep(trigger: ManagedAlbumReconcileTrigger.resume),
    );
  }

  Future<void> _ensureObservationAndSweep({
    ManagedAlbumReconcileTrigger trigger = ManagedAlbumReconcileTrigger.startup,
  }) async {
    final sweep = _runningSweep;
    if (sweep != null) return sweep;

    final future = () async {
      final report = await _service.reconcileExternalDeletes(trigger: trigger);
      _latestReport = report;
      if (!_reports.isClosed) {
        _reports.add(report);
      }
      if (report.accessStatus.allowsReadAccess && _photoChangesSub == null) {
        _photoChangesSub = _videoAlbum.libraryChangeStream.listen((event) {
          if (event['type'] != 'libraryChanged') return;
          unawaited(
            _ensureObservationAndSweep(
              trigger: ManagedAlbumReconcileTrigger.libraryChanged,
            ),
          );
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
