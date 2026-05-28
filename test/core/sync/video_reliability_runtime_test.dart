import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:breakdex/core/data/drift_repositories.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/connectivity_service.dart';
import 'package:breakdex/core/services/provenance_journal_service.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/core/sync/cloud_provider.dart';
import 'package:breakdex/core/sync/network_policy.dart';
import 'package:breakdex/core/sync/on_demand_downloader.dart';
import 'package:breakdex/core/sync/video_reliability_runtime.dart';
import 'package:breakdex/core/sync/video_retrieval_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

class _FakeVideoService extends VideoService {
  final Map<String, VideoFileStatus> statusByPath = {};

  @override
  Future<VideoFileStatus> checkVideoFileWithRetry(
    String path, {
    int maxRetries = 2,
  }) async {
    return statusByPath[path] ?? VideoFileStatus.missing;
  }
}

class _FakeRetriever implements LocalAssetRetriever {
  _FakeRetriever({required this.pathForHash});

  final Map<String, String> pathForHash;

  @override
  Future<String?> ensureLocal(
    String contentHash, {
    TransferProgress? onProgress,
    CancellationToken? cancel,
  }) async {
    return pathForHash[contentHash];
  }
}

void main() {
  group('VideoReliabilityReport', () {
    test('formats a startup toast for blocked media recovery', () {
      final report = VideoReliabilityReport(
        trigger: VideoReliabilityTrigger.startup,
        scannedMoves: 4,
        availableLocally: 1,
        restoredLocally: 0,
        waitingForConnection: 2,
        waitingForWifi: 0,
        waitingForBudget: 0,
        failed: 0,
        completedAt: DateTime.utc(2026, 5, 1, 8),
      );

      expect(
        report.snackBarMessage,
        '2 videos are waiting for a network connection.',
      );
    });

    test('formats a startup toast for mixed recovery results', () {
      final report = VideoReliabilityReport(
        trigger: VideoReliabilityTrigger.startup,
        scannedMoves: 4,
        availableLocally: 0,
        restoredLocally: 1,
        waitingForConnection: 0,
        waitingForWifi: 1,
        waitingForBudget: 0,
        failed: 0,
        completedAt: DateTime.utc(2026, 5, 1, 8),
      );

      expect(
        report.snackBarMessage,
        'Restored 1 video from cloud backup. 1 video is waiting for WiFi.',
      );
    });

    test('hasUserSignal is true when only restoredLocally > 0', () {
      final report = VideoReliabilityReport(
        trigger: VideoReliabilityTrigger.startup,
        scannedMoves: 4,
        availableLocally: 0,
        restoredLocally: 3,
        waitingForConnection: 0,
        waitingForWifi: 0,
        waitingForBudget: 0,
        failed: 0,
        completedAt: DateTime.utc(2026, 5, 1, 8),
      );

      expect(report.hasUserSignal, true);
    });
  });

  late AppDatabase db;
  late SharedPreferences prefs;
  late NetworkPolicy policy;
  late StreamController<ConnectionType> connectionController;
  late ConnectionType currentConnectionType;
  late Directory tempDir;
  late ProvenanceJournalService provenanceJournal;
  late _FakeVideoService videoService;

  setUp(() async {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    policy = NetworkPolicy(prefs);
    connectionController = StreamController<ConnectionType>.broadcast();
    currentConnectionType = ConnectionType.none;
    tempDir = await Directory.systemTemp.createTemp(
      'breakdex-video-reliability-',
    );
    provenanceJournal = ProvenanceJournalService(
      documentsDirectory: () async => tempDir,
      sessionIdGenerator: () => 'session-reliability-tests',
    );
    VideoPathResolver.docsPathOverride = tempDir.path;
    videoService = _FakeVideoService();
  });

  tearDown(() async {
    VideoPathResolver.docsPathOverride = '';
    await connectionController.close();
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'restores recent cloud-backed videos on startup and updates move rows',
    () async {
      await db.movesDao.insertMove(
        MovesCompanion.insert(
          id: 'move-1',
          name: 'Windmill',
          category: const Value('power'),
          contentHash: const Value('hash-startup'),
        ),
      );
      await db
          .into(db.assetManifest)
          .insert(
            AssetManifestCompanion.insert(
              contentHash: 'hash-startup',
              fileSizeBytes: 2048,
              sourceType: 'cloud_download',
              importedAt: DateTime.utc(2026, 5, 1),
            ),
          );

      currentConnectionType = ConnectionType.wifi;
      final controller = VideoRetrievalController(
        retriever: _FakeRetriever(
          pathForHash: {
            'hash-startup': '${tempDir.path}/Moves/hash-startup.mp4',
          },
        ),
        manifestDao: db.assetManifestDao,
        networkPolicy: policy,
        getConnectionType: () async => currentConnectionType,
        connectionTypeStream: connectionController.stream,
        provenanceJournal: provenanceJournal,
      );
      addTearDown(controller.dispose);

      final runtime = VideoReliabilityRuntime(
        movesDao: db.movesDao,
        moveRepository: DriftMoveRepository(db.movesDao),
        videoService: videoService,
        retrievalController: controller,
        connectionTypeStream: connectionController.stream,
        now: () => DateTime.utc(2026, 5, 1, 8),
      );

      final report = await runtime.runSweep(
        trigger: VideoReliabilityTrigger.startup,
      );
      final move = await db.movesDao.getById('move-1');

      expect(report.restoredLocally, 1);
      expect(report.waitingForWifi, 0);
      expect(move.videoPath, 'Moves/hash-startup.mp4');
    },
  );

  test(
    'reports blocked startup recovery when recent videos need connectivity',
    () async {
      await db.movesDao.insertMove(
        MovesCompanion.insert(
          id: 'move-2',
          name: 'Halo',
          category: const Value('power'),
          contentHash: const Value('hash-offline'),
        ),
      );
      await db
          .into(db.assetManifest)
          .insert(
            AssetManifestCompanion.insert(
              contentHash: 'hash-offline',
              fileSizeBytes: 2048,
              sourceType: 'cloud_download',
              importedAt: DateTime.utc(2026, 5, 1),
            ),
          );

      final controller = VideoRetrievalController(
        retriever: _FakeRetriever(pathForHash: const {}),
        manifestDao: db.assetManifestDao,
        networkPolicy: policy,
        getConnectionType: () async => currentConnectionType,
        connectionTypeStream: connectionController.stream,
        provenanceJournal: provenanceJournal,
      );
      addTearDown(controller.dispose);

      final runtime = VideoReliabilityRuntime(
        movesDao: db.movesDao,
        moveRepository: DriftMoveRepository(db.movesDao),
        videoService: videoService,
        retrievalController: controller,
        connectionTypeStream: connectionController.stream,
        now: () => DateTime.utc(2026, 5, 1, 8),
      );

      final report = await runtime.runSweep(
        trigger: VideoReliabilityTrigger.startup,
      );
      final move = await db.movesDao.getById('move-2');

      expect(report.waitingForConnection, 1);
      expect(report.restoredLocally, 0);
      expect(move.videoPath, isNull);
    },
  );
}
