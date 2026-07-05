// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:io';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/connectivity_service.dart';
import 'package:breakdex/core/services/provenance_journal_service.dart';
import 'package:breakdex/core/sync/cloud_provider.dart';
import 'package:breakdex/core/sync/network_policy.dart';
import 'package:breakdex/core/sync/on_demand_downloader.dart';
import 'package:breakdex/core/sync/video_retrieval_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late NetworkPolicy policy;
  late StreamController<ConnectionType> connectionController;
  late ConnectionType currentConnectionType;
  late Directory tempDir;
  late ProvenanceJournalService provenanceJournal;

  setUp(() async {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    policy = NetworkPolicy(prefs);
    connectionController = StreamController<ConnectionType>.broadcast();
    currentConnectionType = ConnectionType.none;
    tempDir = await Directory.systemTemp.createTemp(
      'breakdex-video-retrieval-',
    );
    provenanceJournal = ProvenanceJournalService(
      documentsDirectory: () async => tempDir,
      sessionIdGenerator: () => 'session-video-tests',
    );
  });

  tearDown(() async {
    await connectionController.close();
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('queues offline request and resumes when connection returns', () async {
    await db
        .into(db.assetManifest)
        .insert(
          AssetManifestCompanion.insert(
            contentHash: 'hash-123',
            fileSizeBytes: 4096,
            sourceType: 'cloud_download',
            importedAt: DateTime.utc(2026, 4, 30),
          ),
        );

    final retriever = _FakeRetriever(
      pathForHash: {'hash-123': '/tmp/hash-123.mp4'},
    );
    final controller = VideoRetrievalController(
      retriever: retriever,
      manifestDao: db.assetManifestDao,
      networkPolicy: policy,
      getConnectionType: () async => currentConnectionType,
      connectionTypeStream: connectionController.stream,
      provenanceJournal: provenanceJournal,
    );
    addTearDown(controller.dispose);

    await controller.requestPlayback('hash-123');
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.snapshotFor('hash-123').state,
      VideoRetrievalState.waitingForConnection,
    );
    expect(retriever.ensureLocalCalls, 0);

    currentConnectionType = ConnectionType.wifi;
    connectionController.add(ConnectionType.wifi);
    await _waitFor(
      () => controller.snapshotFor('hash-123').state,
      VideoRetrievalState.available,
    );

    final snapshot = controller.snapshotFor('hash-123');
    expect(snapshot.state, VideoRetrievalState.available);
    expect(snapshot.localPath, '/tmp/hash-123.mp4');
    expect(retriever.ensureLocalCalls, 1);

    final events = await provenanceJournal.readRecent(limit: 10);
    expect(
      events.where((final event) => event.eventType == 'blocked_offline'),
      isNotEmpty,
    );
    expect(
      events.where((final event) => event.eventType == 'download_restored'),
      isNotEmpty,
    );
  });

  test('marks request as failed when retriever cannot restore video', () async {
    await db
        .into(db.assetManifest)
        .insert(
          AssetManifestCompanion.insert(
            contentHash: 'hash-404',
            fileSizeBytes: 1024,
            sourceType: 'cloud_download',
            importedAt: DateTime.utc(2026, 4, 30),
          ),
        );

    final retriever = _FakeRetriever(pathForHash: const {});
    currentConnectionType = ConnectionType.mobile;

    final controller = VideoRetrievalController(
      retriever: retriever,
      manifestDao: db.assetManifestDao,
      networkPolicy: policy,
      getConnectionType: () async => currentConnectionType,
      connectionTypeStream: connectionController.stream,
      provenanceJournal: provenanceJournal,
    );
    addTearDown(controller.dispose);

    await controller.requestPlayback('hash-404');
    await _waitFor(
      () => controller.snapshotFor('hash-404').state,
      VideoRetrievalState.failed,
    );

    final snapshot = controller.snapshotFor('hash-404');
    expect(snapshot.state, VideoRetrievalState.failed);
    expect(snapshot.message, contains('Download failed'));
    expect(retriever.ensureLocalCalls, 1);

    final events = await provenanceJournal.readRecent(limit: 10);
    expect(
      events.where((final event) => event.eventType == 'download_failed'),
      isNotEmpty,
    );
  });

  test(
    'keeps automatic recovery on WiFi while still allowing a user-initiated mobile download',
    () async {
      await db
          .into(db.assetManifest)
          .insert(
            AssetManifestCompanion.insert(
              contentHash: 'hash-mobile',
              fileSizeBytes: 2048,
              sourceType: 'cloud_download',
              importedAt: DateTime.utc(2026, 4, 30),
            ),
          );

      final retriever = _FakeRetriever(
        pathForHash: {'hash-mobile': '/tmp/hash-mobile.mp4'},
      );
      currentConnectionType = ConnectionType.mobile;

      final controller = VideoRetrievalController(
        retriever: retriever,
        manifestDao: db.assetManifestDao,
        networkPolicy: policy,
        getConnectionType: () async => currentConnectionType,
        connectionTypeStream: connectionController.stream,
        provenanceJournal: provenanceJournal,
      );
      addTearDown(controller.dispose);

      await controller.requestAutomaticRecovery('hash-mobile');
      expect(
        controller.snapshotFor('hash-mobile').state,
        VideoRetrievalState.waitingForWifi,
      );
      expect(retriever.ensureLocalCalls, 0);

      await controller.requestPlayback('hash-mobile');
      await _waitFor(
        () => controller.snapshotFor('hash-mobile').state,
        VideoRetrievalState.available,
      );

      expect(
        controller.snapshotFor('hash-mobile').localPath,
        '/tmp/hash-mobile.mp4',
      );
      expect(retriever.ensureLocalCalls, 1);
    },
  );
}

Future<void> _waitFor<T>(
  final T Function() readValue,
  final T expected, {
  final Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (readValue() == expected) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _FakeRetriever implements LocalAssetRetriever {
  _FakeRetriever({required this.pathForHash});

  final Map<String, String> pathForHash;
  int ensureLocalCalls = 0;

  @override
  Future<String?> ensureLocal(
    final String contentHash, {
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) async {
    ensureLocalCalls += 1;
    onProgress?.call(512, 1024);
    onProgress?.call(1024, 1024);
    return pathForHash[contentHash];
  }
}
