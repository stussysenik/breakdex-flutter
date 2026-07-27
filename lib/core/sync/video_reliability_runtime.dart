import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import 'package:breakdex/core/data/repositories.dart';
import 'package:breakdex/core/database/daos/moves_dao.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/reviewable_item.dart';
import 'package:breakdex/core/services/connectivity_service.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/core/sync/video_retrieval_controller.dart';

enum VideoReliabilityTrigger { startup, resume, connectivityImproved }

enum VideoReliabilityDisposition {
  availableLocally,
  restoredLocally,
  waitingForConnection,
  waitingForWifi,
  waitingForBudget,
  failed,
}

class VideoReliabilityReport {
  const VideoReliabilityReport({
    required this.trigger,
    required this.scannedMoves,
    required this.availableLocally,
    required this.restoredLocally,
    required this.waitingForConnection,
    required this.waitingForWifi,
    required this.waitingForBudget,
    required this.failed,
    required this.completedAt,
  });

  final VideoReliabilityTrigger trigger;
  final int scannedMoves;
  final int availableLocally;
  final int restoredLocally;
  final int waitingForConnection;
  final int waitingForWifi;
  final int waitingForBudget;
  final int failed;
  final DateTime completedAt;

  bool get hasUserSignal =>
      restoredLocally > 0 ||
      waitingForConnection > 0 ||
      waitingForWifi > 0 ||
      waitingForBudget > 0 ||
      failed > 0;

  String get title {
    if (restoredLocally > 0) {
      return 'Cold start restored $restoredLocally video${restoredLocally == 1 ? '' : 's'}';
    }
    final blocked = waitingForConnection + waitingForWifi + waitingForBudget;
    if (blocked > 0) {
      return 'Cold start checked recent videos';
    }
    if (failed > 0) {
      return 'Cold start found videos that still need repair';
    }
    return 'Cold start checked your recent videos';
  }

  String get detail {
    if (restoredLocally > 0) {
      return 'Breakdex repaired recent library videos automatically so they are ready without manual recovery.';
    }
    if (waitingForWifi > 0) {
      return 'Automatic restore is waiting for WiFi for $waitingForWifi video${waitingForWifi == 1 ? '' : 's'}.';
    }
    if (waitingForConnection > 0) {
      return 'Automatic restore is waiting for a network connection for $waitingForConnection video${waitingForConnection == 1 ? '' : 's'}.';
    }
    if (waitingForBudget > 0) {
      return 'Automatic restore paused because the mobile data budget was reached for $waitingForBudget video${waitingForBudget == 1 ? '' : 's'}.';
    }
    if (failed > 0) {
      return 'Some recent cloud-backed videos still could not be restored automatically.';
    }
    return 'Breakdex verified $availableLocally recent video${availableLocally == 1 ? '' : 's'} that were already local.';
  }

  String get snackBarMessage {
    final parts = <String>[];
    if (restoredLocally > 0) {
      parts.add(
        'Restored $restoredLocally video${restoredLocally == 1 ? '' : 's'} from cloud backup.',
      );
    }
    if (failed > 0) {
      parts.add(
        "Couldn't restore $failed recent video${failed == 1 ? '' : 's'}.",
      );
    } else if (waitingForWifi > 0) {
      parts.add(
        '$waitingForWifi video${waitingForWifi == 1 ? ' is' : 's are'} waiting for WiFi.',
      );
    } else if (waitingForConnection > 0) {
      parts.add(
        '$waitingForConnection video${waitingForConnection == 1 ? ' is' : 's are'} waiting for a network connection.',
      );
    } else if (waitingForBudget > 0) {
      parts.add(
        '$waitingForBudget video${waitingForBudget == 1 ? ' is' : 's are'} paused by the mobile data budget.',
      );
    }
    if (parts.isEmpty) {
      return 'Checked recent videos on startup.';
    }
    return parts.join(' ');
  }
}

/// Bounded launch/runtime sweep that repairs a small set of recent cloud-backed
/// videos without requiring the user to visit each move detail screen.
class VideoReliabilityRuntime with WidgetsBindingObserver {
  VideoReliabilityRuntime({
    required final MovesDao movesDao,
    required final MoveRepository moveRepository,
    required final VideoService videoService,
    required final VideoRetrievalController retrievalController,
    required final Stream<ConnectionType> connectionTypeStream,
    final DateTime Function()? now,
    this.maxPriorityMoves = 12,
    this.maxAutomaticRecoveries = 4,
  }) : _movesDao = movesDao,
       _moveRepository = moveRepository,
       _videoService = videoService,
       _retrievalController = retrievalController,
       _connectionTypeStream = connectionTypeStream,
       _now = now ?? DateTime.now;

  final MovesDao _movesDao;
  final MoveRepository _moveRepository;
  final VideoService _videoService;
  final VideoRetrievalController _retrievalController;
  final Stream<ConnectionType> _connectionTypeStream;
  final DateTime Function() _now;
  final int maxPriorityMoves;
  final int maxAutomaticRecoveries;

  final StreamController<VideoReliabilityReport> _reports =
      StreamController<VideoReliabilityReport>.broadcast();
  StreamSubscription<ConnectionType>? _connectionSub;
  Future<VideoReliabilityReport>? _runningSweep;
  VideoReliabilityReport? _latestReport;
  ConnectionType? _lastConnectionType;
  bool _started = false;

  Stream<VideoReliabilityReport> get reports => _reports.stream;
  VideoReliabilityReport? get latestReport => _latestReport;

  void start() {
    // Self-healing operates on local on-disk video copies, which do not exist on
    // web; the sweep calls native file/path APIs that throw. No-op visibly on web.
    if (kIsWeb) return;
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _connectionSub ??= _connectionTypeStream.listen(_handleConnectionType);
    unawaited(runSweep(trigger: VideoReliabilityTrigger.startup));
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _connectionSub?.cancel();
    await _reports.close();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(runSweep(trigger: VideoReliabilityTrigger.resume));
  }

  Future<VideoReliabilityReport> runSweep({
    required final VideoReliabilityTrigger trigger,
  }) async {
    final activeSweep = _runningSweep;
    if (activeSweep != null) return activeSweep;

    final future = _runSweep(trigger: trigger);
    _runningSweep = future;
    try {
      return await future;
    } finally {
      _runningSweep = null;
    }
  }

  void _handleConnectionType(final ConnectionType next) {
    final previous = _lastConnectionType;
    _lastConnectionType = next;
    if (previous == null) return;
    if (!_isConnectivityImprovement(previous, next)) return;
    unawaited(runSweep(trigger: VideoReliabilityTrigger.connectivityImproved));
  }

  bool _isConnectivityImprovement(
    final ConnectionType previous,
    final ConnectionType next,
  ) {
    if (previous == ConnectionType.none && next != ConnectionType.none) {
      return true;
    }
    if (previous == ConnectionType.mobile &&
        (next == ConnectionType.wifi || next == ConnectionType.ethernet)) {
      return true;
    }
    return false;
  }

  Future<VideoReliabilityReport> _runSweep({
    required final VideoReliabilityTrigger trigger,
  }) async {
    final moves = await _movesDao.getAll();
    final priorityMoves = moves.take(maxPriorityMoves);
    final processedHashes = <String>{};
    var scannedMoves = 0;
    var availableLocally = 0;
    var restoredLocally = 0;
    var waitingForConnection = 0;
    var waitingForWifi = 0;
    var waitingForBudget = 0;
    var failed = 0;

    for (final move in priorityMoves) {
      scannedMoves += 1;
      final contentHash = move.contentHash?.trim();
      if (contentHash == null || contentHash.isEmpty) continue;
      if (!processedHashes.add(contentHash)) continue;

      final resolvedVideoPath = move.resolvedVideoPath;
      if (resolvedVideoPath != null) {
        final status = await _videoService.checkVideoFileWithRetry(
          resolvedVideoPath,
        );
        if (status == VideoFileStatus.ready) {
          availableLocally += 1;
          continue;
        }
      }

      if (restoredLocally +
              waitingForConnection +
              waitingForWifi +
              waitingForBudget +
              failed >=
          maxAutomaticRecoveries) {
        break;
      }

      await _retrievalController.requestAutomaticRecovery(
        contentHash,
        message: 'Automatic launch recovery requested local restore.',
      );
      final snapshot = _retrievalController.snapshotFor(contentHash);
      final disposition = _classify(snapshot);
      switch (disposition) {
        case VideoReliabilityDisposition.availableLocally:
          availableLocally += 1;
        case VideoReliabilityDisposition.restoredLocally:
          restoredLocally += 1;
          final localPath = snapshot.localPath;
          if (localPath != null) {
            await _attachLocalPathToMoves(contentHash, localPath);
          }
        case VideoReliabilityDisposition.waitingForConnection:
          waitingForConnection += 1;
        case VideoReliabilityDisposition.waitingForWifi:
          waitingForWifi += 1;
        case VideoReliabilityDisposition.waitingForBudget:
          waitingForBudget += 1;
        case VideoReliabilityDisposition.failed:
          failed += 1;
      }
    }

    final report = VideoReliabilityReport(
      trigger: trigger,
      scannedMoves: scannedMoves,
      availableLocally: availableLocally,
      restoredLocally: restoredLocally,
      waitingForConnection: waitingForConnection,
      waitingForWifi: waitingForWifi,
      waitingForBudget: waitingForBudget,
      failed: failed,
      completedAt: _now(),
    );
    _latestReport = report;
    if (!_reports.isClosed) {
      _reports.add(report);
    }
    return report;
  }

  VideoReliabilityDisposition _classify(final VideoRetrievalSnapshot snapshot) {
    switch (snapshot.state) {
      case VideoRetrievalState.available:
        return snapshot.progress >= 1
            ? VideoReliabilityDisposition.restoredLocally
            : VideoReliabilityDisposition.availableLocally;
      case VideoRetrievalState.waitingForConnection:
        return VideoReliabilityDisposition.waitingForConnection;
      case VideoRetrievalState.waitingForWifi:
        return VideoReliabilityDisposition.waitingForWifi;
      case VideoRetrievalState.waitingForBudget:
        return VideoReliabilityDisposition.waitingForBudget;
      case VideoRetrievalState.failed:
        return VideoReliabilityDisposition.failed;
      case VideoRetrievalState.idle:
      case VideoRetrievalState.queued:
      case VideoRetrievalState.downloading:
        return VideoReliabilityDisposition.failed;
    }
  }

  Future<void> _attachLocalPathToMoves(
    final String contentHash,
    final String localPath,
  ) async {
    final relativePath = VideoPathResolver.toRelative(localPath);
    final moves = await _movesDao.getActiveByContentHash(contentHash);
    for (final move in moves) {
      await _moveRepository.update(
        MovesCompanion(id: Value(move.id), videoPath: Value(relativePath)),
      );
    }
  }
}
