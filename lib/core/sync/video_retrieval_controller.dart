import 'dart:async';
import 'dart:collection';

import '../database/daos/asset_manifest_dao.dart';
import '../database/daos/sync_dao.dart';
import '../services/connectivity_service.dart';
import '../services/provenance_journal_service.dart';
import 'network_policy.dart';
import 'on_demand_downloader.dart';

enum VideoRetrievalState {
  idle,
  queued,
  waitingForConnection,
  waitingForWifi,
  waitingForBudget,
  downloading,
  available,
  failed,
}

class VideoRetrievalSnapshot {
  const VideoRetrievalSnapshot({
    required this.contentHash,
    required this.state,
    required this.progress,
    required this.updatedAt,
    this.localPath,
    this.message,
  });

  final String contentHash;
  final VideoRetrievalState state;
  final double progress;
  final DateTime updatedAt;
  final String? localPath;
  final String? message;

  factory VideoRetrievalSnapshot.idle(String contentHash) {
    return VideoRetrievalSnapshot(
      contentHash: contentHash,
      state: VideoRetrievalState.idle,
      progress: 0,
      updatedAt: DateTime.now(),
    );
  }

  bool get isActive =>
      state == VideoRetrievalState.queued ||
      state == VideoRetrievalState.waitingForConnection ||
      state == VideoRetrievalState.waitingForWifi ||
      state == VideoRetrievalState.waitingForBudget ||
      state == VideoRetrievalState.downloading;

  VideoRetrievalSnapshot copyWith({
    VideoRetrievalState? state,
    double? progress,
    String? localPath,
    String? message,
    bool clearLocalPath = false,
    bool clearMessage = false,
  }) {
    return VideoRetrievalSnapshot(
      contentHash: contentHash,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      updatedAt: DateTime.now(),
      localPath: clearLocalPath ? null : (localPath ?? this.localPath),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class _PendingRetrievalRequest {
  const _PendingRetrievalRequest({
    required this.contentHash,
    required this.intent,
    required this.message,
  });

  final String contentHash;
  final TransferIntent intent;
  final String message;

  _PendingRetrievalRequest copyWith({TransferIntent? intent, String? message}) {
    return _PendingRetrievalRequest(
      contentHash: contentHash,
      intent: intent ?? this.intent,
      message: message ?? this.message,
    );
  }
}

/// Coordinates user-initiated video retrieval without pushing transfer logic
/// into widgets.
///
/// The UI fires a request once. This controller decides when the request can
/// run based on current connectivity and network policy, then resumes pending
/// requests automatically as conditions improve.
class VideoRetrievalController {
  VideoRetrievalController({
    required LocalAssetRetriever retriever,
    required AssetManifestDao manifestDao,
    required NetworkPolicy networkPolicy,
    required Future<ConnectionType> Function() getConnectionType,
    required Stream<ConnectionType> connectionTypeStream,
    ProvenanceJournalService? provenanceJournal,
    SyncDao? syncDao,
  }) : _retriever = retriever,
       _manifestDao = manifestDao,
       _networkPolicy = networkPolicy,
       _getConnectionType = getConnectionType,
       _provenanceJournal = provenanceJournal,
       _syncDao = syncDao {
    _connectionSub = connectionTypeStream.listen((_) {
      unawaited(_pumpQueue());
    });
  }

  final LocalAssetRetriever _retriever;
  final AssetManifestDao _manifestDao;
  final NetworkPolicy _networkPolicy;
  final Future<ConnectionType> Function() _getConnectionType;
  final ProvenanceJournalService? _provenanceJournal;
  final SyncDao? _syncDao;

  final LinkedHashMap<String, _PendingRetrievalRequest> _pending =
      LinkedHashMap<String, _PendingRetrievalRequest>();
  final Map<String, VideoRetrievalSnapshot> _snapshots = {};
  final Map<String, StreamController<VideoRetrievalSnapshot>> _controllers = {};
  late final StreamSubscription<ConnectionType> _connectionSub;

  bool _pumping = false;
  bool _repumpRequested = false;

  Stream<VideoRetrievalSnapshot> watch(String contentHash) async* {
    yield snapshotFor(contentHash);
    // ignore: close_sinks
    final controller = _controllers.putIfAbsent(
      contentHash,
      () => StreamController<VideoRetrievalSnapshot>.broadcast(),
    );
    yield* controller.stream;
  }

  VideoRetrievalSnapshot snapshotFor(String contentHash) {
    return _snapshots[contentHash] ?? VideoRetrievalSnapshot.idle(contentHash);
  }

  Future<void> requestPlayback(String contentHash) async {
    await requestAutomaticRecovery(
      contentHash,
      intent: TransferIntent.userInitiatedPlayback,
      message: 'User requested local playback recovery.',
    );
  }

  Future<void> requestAutomaticRecovery(
    String contentHash, {
    TransferIntent intent = TransferIntent.backgroundSync,
    String? message,
  }) async {
    final snapshot = snapshotFor(contentHash);
    if (snapshot.state == VideoRetrievalState.downloading ||
        snapshot.state == VideoRetrievalState.available ||
        (_pending[contentHash]?.intent ==
                TransferIntent.userInitiatedPlayback &&
            intent == TransferIntent.backgroundSync)) {
      return;
    }

    final existing = _pending[contentHash];
    final effectiveMessage =
        message ??
        (intent == TransferIntent.userInitiatedPlayback
            ? 'User requested local playback recovery.'
            : 'Automatic launch recovery requested local restore.');
    if (existing != null) {
      _pending[contentHash] = existing.copyWith(
        intent: intent == TransferIntent.userInitiatedPlayback
            ? intent
            : existing.intent,
        message: intent == TransferIntent.userInitiatedPlayback
            ? effectiveMessage
            : existing.message,
      );
    } else {
      _pending[contentHash] = _PendingRetrievalRequest(
        contentHash: contentHash,
        intent: intent,
        message: effectiveMessage,
      );
    }
    _emit(
      contentHash,
      snapshot.copyWith(
        state: VideoRetrievalState.queued,
        progress: 0,
        message: 'Request queued',
        clearLocalPath: true,
      ),
    );

    await _log(contentHash: contentHash, action: 'retrieval_requested');
    await _logProvenance(
      contentHash: contentHash,
      eventType: 'request_queued',
      status: 'queued',
      message: effectiveMessage,
    );

    await _pumpQueue();
    await _waitForSettledState(contentHash);
  }

  Future<void> _pumpQueue() async {
    if (_pumping) {
      _repumpRequested = true;
      return;
    }
    _pumping = true;

    try {
      while (_pending.isNotEmpty) {
        final request = _pending.values.first;
        final contentHash = request.contentHash;
        final manifest = await _manifestDao.getByHash(contentHash);
        if (manifest == null) {
          _pending.remove(contentHash);
          _emit(
            contentHash,
            snapshotFor(contentHash).copyWith(
              state: VideoRetrievalState.failed,
              progress: 0,
              message: 'Video manifest entry is missing',
              clearLocalPath: true,
            ),
          );
          await _logProvenance(
            contentHash: contentHash,
            eventType: 'manifest_missing',
            status: 'failed',
            message: 'Video manifest entry is missing.',
          );
          continue;
        }

        final connectionType = await _getConnectionType();
        final decision = _networkPolicy.canTransfer(
          manifest.fileSizeBytes,
          connectionType,
          intent: request.intent,
        );

        switch (decision) {
          case TransferDecision.offline:
            _emit(
              contentHash,
              snapshotFor(contentHash).copyWith(
                state: VideoRetrievalState.waitingForConnection,
                progress: 0,
                message: 'Waiting for a network connection',
                clearLocalPath: true,
              ),
            );
            await _logProvenance(
              contentHash: contentHash,
              eventType: 'blocked_offline',
              status: 'waiting_for_connection',
              connectionType: connectionType.name,
              message: request.intent == TransferIntent.userInitiatedPlayback
                  ? 'Waiting for a network connection.'
                  : 'Automatic recovery is waiting for a network connection.',
            );
            return;
          case TransferDecision.waitForWifi:
            _emit(
              contentHash,
              snapshotFor(contentHash).copyWith(
                state: VideoRetrievalState.waitingForWifi,
                progress: 0,
                message: 'Waiting for WiFi',
                clearLocalPath: true,
              ),
            );
            await _logProvenance(
              contentHash: contentHash,
              eventType: 'blocked_wifi',
              status: 'waiting_for_wifi',
              connectionType: connectionType.name,
              message: request.intent == TransferIntent.userInitiatedPlayback
                  ? 'Waiting for WiFi.'
                  : 'Automatic recovery is waiting for WiFi.',
            );
            return;
          case TransferDecision.dataCapExceeded:
            _emit(
              contentHash,
              snapshotFor(contentHash).copyWith(
                state: VideoRetrievalState.waitingForBudget,
                progress: 0,
                message: 'Mobile data budget reached',
                clearLocalPath: true,
              ),
            );
            await _logProvenance(
              contentHash: contentHash,
              eventType: 'blocked_budget',
              status: 'waiting_for_budget',
              connectionType: connectionType.name,
              message: request.intent == TransferIntent.userInitiatedPlayback
                  ? 'Mobile data budget reached.'
                  : 'Automatic recovery paused because the mobile data budget was reached.',
            );
            return;
          case TransferDecision.allow:
            break;
        }

        _emit(
          contentHash,
          snapshotFor(contentHash).copyWith(
            state: VideoRetrievalState.downloading,
            progress: 0,
            message: connectionType == ConnectionType.mobile
                ? 'Downloading on mobile data'
                : 'Downloading from cloud',
            clearLocalPath: true,
          ),
        );
        await _logProvenance(
          contentHash: contentHash,
          eventType: 'download_started',
          status: 'downloading',
          connectionType: connectionType.name,
          message: request.intent == TransferIntent.userInitiatedPlayback
              ? (connectionType == ConnectionType.mobile
                    ? 'Downloading on mobile data.'
                    : 'Downloading from cloud.')
              : (connectionType == ConnectionType.mobile
                    ? 'Automatic recovery is downloading on mobile data.'
                    : 'Automatic recovery is downloading from cloud.'),
        );

        var lastTransferred = 0;
        final localPath = await _retriever.ensureLocal(
          contentHash,
          onProgress: (transferred, total) {
            final delta = transferred - lastTransferred;
            lastTransferred = transferred;
            if (delta > 0 && connectionType == ConnectionType.mobile) {
              unawaited(_networkPolicy.recordMobileUsage(delta));
            }
            _emit(
              contentHash,
              snapshotFor(contentHash).copyWith(
                state: VideoRetrievalState.downloading,
                progress: total > 0 ? transferred / total : 0,
                message: connectionType == ConnectionType.mobile
                    ? 'Downloading on mobile data'
                    : 'Downloading from cloud',
                clearLocalPath: true,
              ),
            );
          },
        );

        _pending.remove(contentHash);

        if (localPath == null) {
          _emit(
            contentHash,
            snapshotFor(contentHash).copyWith(
              state: VideoRetrievalState.failed,
              progress: 0,
              message: 'Download failed. Check your connection.',
              clearLocalPath: true,
            ),
          );
          await _log(contentHash: contentHash, action: 'retrieval_failed');
          await _logProvenance(
            contentHash: contentHash,
            eventType: 'download_failed',
            status: 'failed',
            connectionType: connectionType.name,
            message: 'Download failed. Check your connection.',
          );
          continue;
        }

        _emit(
          contentHash,
          snapshotFor(contentHash).copyWith(
            state: VideoRetrievalState.available,
            progress: 1,
            localPath: localPath,
            message: 'Video restored locally',
          ),
        );
        await _log(contentHash: contentHash, action: 'retrieval_available');
        await _logProvenance(
          contentHash: contentHash,
          eventType: 'download_restored',
          status: 'available',
          connectionType: connectionType.name,
          localPath: localPath,
          message: 'Video restored locally.',
        );
      }
    } finally {
      _pumping = false;
      if (_repumpRequested) {
        _repumpRequested = false;
        unawaited(_pumpQueue());
      }
    }
  }

  void _emit(String contentHash, VideoRetrievalSnapshot snapshot) {
    _snapshots[contentHash] = snapshot;
    _controllers[contentHash]?.add(snapshot);
  }

  Future<void> _log({
    required String contentHash,
    required String action,
  }) async {
    if (_syncDao == null) return;
    try {
      await _syncDao.logChange(
        entityId: contentHash,
        table: 'asset_manifest',
        action: action,
      );
    } catch (_) {
      // Retrieval audit logs are helpful but not critical to user flows.
    }
  }

  Future<void> _logProvenance({
    required String contentHash,
    required String eventType,
    required String status,
    String? connectionType,
    String? localPath,
    String? message,
  }) async {
    if (_provenanceJournal == null) return;
    try {
      await _provenanceJournal.log(
        scope: 'video_retrieval',
        eventType: eventType,
        status: status,
        entityType: 'asset_manifest',
        entityId: contentHash,
        contentHash: contentHash,
        connectionType: connectionType,
        localPath: localPath,
        message: message,
      );
    } catch (_) {
      // Provenance improves debuggability but should never block playback.
    }
  }

  Future<void> _waitForSettledState(String contentHash) async {
    while (true) {
      final snapshot = snapshotFor(contentHash);
      if (snapshot.state != VideoRetrievalState.queued &&
          snapshot.state != VideoRetrievalState.downloading) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  void dispose() {
    _connectionSub.cancel();
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}
