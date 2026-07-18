import 'dart:io';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/connectivity_service.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/sync/asset_hash_service.dart';
import 'package:breakdex/core/sync/asset_sync_engine.dart';
import 'package:breakdex/core/sync/cloud_provider.dart';
import 'package:breakdex/core/sync/network_policy.dart';
import 'package:breakdex/core/sync/safety_guard.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

class _TrackedFakeProvider implements CloudProvider {
  final List<String> uploadedLocalPaths = [];
  final List<String> downloadedRemotePaths = [];
  final List<String> deletedRemotePaths = [];
  final List<String> verifiedRemotePaths = [];
  bool shouldThrowOnUpload = false;
  bool shouldThrowOnDownload = false;

  /// Test hook fired after each successful upload (e.g. to pause mid-drain).
  void Function()? onUpload;

  final String _providerType;
  _TrackedFakeProvider({final String providerType = 'icloud'})
    : _providerType = providerType;

  @override
  String get providerType => _providerType;

  @override
  String get displayName => 'Fake $_providerType';

  @override
  Set<CloudProviderCapability> get capabilities => {
    CloudProviderCapability.serverSideHash,
  };

  @override
  Future<bool> authenticate() async => true;

  @override
  Future<void> deauthenticate() async {}

  @override
  Future<bool> get isAuthenticated async => true;

  @override
  Future<RemoteAsset> upload({
    required final String localPath,
    required final String remotePath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) async {
    if (shouldThrowOnUpload) throw Exception('Upload failed');
    uploadedLocalPaths.add(localPath);
    onUpload?.call();
    return RemoteAsset(remotePath: remotePath, sizeBytes: 1024);
  }

  @override
  Future<void> download({
    required final String remotePath,
    required final String localPath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) async {
    if (shouldThrowOnDownload) throw Exception('Download failed');
    downloadedRemotePaths.add(remotePath);
  }

  @override
  Future<bool> verify({
    required final String remotePath,
    final String? expectedHash,
    final int? expectedSize,
  }) async {
    verifiedRemotePaths.add(remotePath);
    return true;
  }

  @override
  Future<List<RemoteAsset>> list({required final String directory}) async => [];

  @override
  Future<void> delete({required final String remotePath}) async {
    deletedRemotePaths.add(remotePath);
  }

  @override
  Future<({int totalBytes, int usedBytes})?> quota() async => null;
}

/// Policy that defers files over [deferOverBytes] to WiFi — the per-file
/// deferral shape (oversized file on a capped link) the sweep must skip past.
class _SizeGatedPolicy extends NetworkPolicy {
  _SizeGatedPolicy(super.prefs, {required this.deferOverBytes});

  final int deferOverBytes;

  @override
  TransferDecision canTransfer(
    final int sizeBytes,
    final ConnectionType connectionType, {
    final TransferIntent intent = TransferIntent.backgroundSync,
  }) {
    if (sizeBytes > deferOverBytes) return TransferDecision.waitForWifi;
    return super.canTransfer(sizeBytes, connectionType, intent: intent);
  }
}

Future<void> _seedManifest(
  final AppDatabase db, {
  required final String hash,
  final String? localPath,
  final DateTime? deletedAt,
  final int fileSizeBytes = 1024,
}) async {
  await db.assetManifestDao.upsert(AssetManifestCompanion(
    contentHash: Value(hash),
    fileSizeBytes: Value(fileSizeBytes),
    sourceType: const Value('camera'),
    importedAt: Value(DateTime.now()),
    localPath: Value(localPath),
    deletedAt: Value(deletedAt),
  ));
}

Future<void> _seedCopy(
  final AppDatabase db, {
  required final String id,
  required final String hash,
  required final String provider,
  final String? remotePath,
  final String status = 'verified',
}) async {
  await db.assetCopiesDao.insertCopy(AssetCopiesCompanion(
    id: Value(id),
    contentHash: Value(hash),
    provider: Value(provider),
    remotePath: Value(remotePath),
    status: Value(status),
    createdAt: Value(DateTime.now()),
    updatedAt: Value(DateTime.now()),
  ));
}

Future<void> _seedOperation(
  final AppDatabase db, {
  required final String id,
  required final String hash,
  required final String operationType,
  final String providerId = 'icloud',
  final String status = 'queued',
  final int priority = 1,
}) async {
  await db.syncOperationsDao.insertOperation(
    SyncOperationsCompanion(
      id: Value(id),
      contentHash: Value(hash),
      providerId: Value(providerId),
      operationType: Value(operationType),
      status: Value(status),
      priority: Value(priority),
      createdAt: Value(DateTime.now()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late AssetSyncEngine engine;
  late _TrackedFakeProvider fakeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('breakdex_sync_test_');
    VideoPathResolver.docsPathOverride = tempDir.path;

    db = createTestDatabase();
    final prefs = await SharedPreferences.getInstance();

    fakeProvider = _TrackedFakeProvider();

    engine = AssetSyncEngine(
      manifestDao: db.assetManifestDao,
      copiesDao: db.assetCopiesDao,
      opsDao: db.syncOperationsDao,
      hashService: AssetHashService(),
      networkPolicy: NetworkPolicy(prefs),
      safetyGuard: SafetyGuard(db.assetManifestDao, db.assetCopiesDao),
      providers: [fakeProvider],
    );
  });

  tearDown(() async {
    engine.dispose();
    await db.close();
    try {
      tempDir.deleteSync(recursive: true);
    } on Object catch (_) {}
  });

  group('operation routing', () {
    test('routes upload op to provider', () async {
      // Create a real temp file the engine can read
      final testFile = File('${tempDir.path}/test_upload.mp4');
      await testFile.writeAsBytes(List.filled(64, 0));
      const relativePath = 'test_upload.mp4';

      await _seedManifest(db, hash: 'abc123', localPath: relativePath);
      await _seedOperation(
        db,
        id: 'op-1',
        hash: 'abc123',
        operationType: 'upload',
      );

      await engine.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.uploadedLocalPaths.isNotEmpty, isTrue);
    });

    test('ignores operation when provider is missing', () async {
      await _seedOperation(
        db,
        id: 'op-2',
        hash: 'abc999',
        operationType: 'upload',
        providerId: 'gdrive',
      );

      await engine.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.uploadedLocalPaths, isEmpty);
    });

    test('routes download op to provider', () async {
      await _seedManifest(db, hash: 'def456', localPath: 'video.mp4');
      await _seedCopy(
        db,
        id: 'copy-3',
        hash: 'def456',
        provider: 'icloud',
        remotePath: '/cloud/video.mp4',
      );
      await _seedOperation(
        db,
        id: 'op-3',
        hash: 'def456',
        operationType: 'download',
      );

      await engine.runSyncCycle(ConnectionType.wifi);

      if (fakeProvider.downloadedRemotePaths.isEmpty) {
        final ops = await db.syncOperationsDao.getRetryable();
        final failedOp = ops.where((final o) => o.id == 'op-3').firstOrNull;
        if (failedOp != null) {
          fail('Download op failed: ${failedOp.errorMessage}');
        }
      }
      expect(fakeProvider.downloadedRemotePaths, contains('/cloud/video.mp4'));
    });

    test('routes verify op to provider', () async {
      await _seedManifest(db, hash: 'ghi789');
      await _seedCopy(
        db,
        id: 'copy-4',
        hash: 'ghi789',
        provider: 'icloud',
        remotePath: '/cloud/asset.bin',
      );
      await _seedOperation(
        db,
        id: 'op-4',
        hash: 'ghi789',
        operationType: 'verify',
      );

      await engine.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.verifiedRemotePaths, contains('/cloud/asset.bin'));
    });

    test('routes delete_remote op to provider', () async {
      await _seedManifest(
        db,
        hash: 'jkl012',
        deletedAt: DateTime.now(),
      );
      await _seedCopy(
        db,
        id: 'copy-5',
        hash: 'jkl012',
        provider: 'icloud',
        remotePath: '/cloud/stale.mp4',
      );
      await _seedOperation(
        db,
        id: 'op-5',
        hash: 'jkl012',
        operationType: 'delete_remote',
      );

      await engine.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.deletedRemotePaths, contains('/cloud/stale.mp4'));
    });

    test('marks operation failed when provider throws', () async {
      fakeProvider.shouldThrowOnUpload = true;
      final testFile = File('${tempDir.path}/test_fail.mp4');
      await testFile.writeAsBytes(List.filled(64, 0));

      await _seedManifest(db, hash: 'fail01', localPath: 'test_fail.mp4');
      await _seedOperation(
        db,
        id: 'op-fail',
        hash: 'fail01',
        operationType: 'upload',
      );

      await engine.runSyncCycle(ConnectionType.wifi);

      final ops = await db.syncOperationsDao.getQueued();
      expect(ops.any((final o) => o.id == 'op-fail'), isFalse);
    });
  });

  group('provider registry', () {
    test('routes to correct provider by providerType', () async {
      final testFile = File('${tempDir.path}/test_multi.mp4');
      await testFile.writeAsBytes(List.filled(64, 0));

      final s3Fake = _TrackedFakeProvider(providerType: 's3');
      final engine2 = AssetSyncEngine(
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        opsDao: db.syncOperationsDao,
        hashService: AssetHashService(),
        networkPolicy: NetworkPolicy(await SharedPreferences.getInstance()),
        safetyGuard: SafetyGuard(db.assetManifestDao, db.assetCopiesDao),
        providers: [fakeProvider, s3Fake],
      );
      addTearDown(() => engine2.dispose());

      await _seedManifest(db, hash: 'multi1', localPath: 'test_multi.mp4');
      await _seedOperation(
        db,
        id: 'op-icloud',
        hash: 'multi1',
        operationType: 'upload',
        providerId: 'icloud',
      );
      await _seedOperation(
        db,
        id: 'op-s3',
        hash: 'multi1',
        operationType: 'upload',
        providerId: 's3',
      );

      await engine2.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.uploadedLocalPaths.isNotEmpty, isTrue);
      expect(s3Fake.uploadedLocalPaths.isNotEmpty, isTrue);
    });
  });

  group('upload sweep (skip, not abort)', () {
    test('deferred file does not block transferable files behind it', () async {
      // Big file FIRST in the sweep, small transferable file behind it.
      final bigFile = File('${tempDir.path}/big.mp4');
      await bigFile.writeAsBytes(List.filled(64, 1));
      final smallFile = File('${tempDir.path}/small.mp4');
      await smallFile.writeAsBytes(List.filled(64, 2));

      await _seedManifest(
        db,
        hash: 'big001',
        localPath: 'big.mp4',
        fileSizeBytes: 5000,
      );
      await _seedManifest(
        db,
        hash: 'small1',
        localPath: 'small.mp4',
        fileSizeBytes: 1024,
      );

      final gatedEngine = AssetSyncEngine(
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        opsDao: db.syncOperationsDao,
        hashService: AssetHashService(),
        networkPolicy: _SizeGatedPolicy(
          await SharedPreferences.getInstance(),
          deferOverBytes: 2000,
        ),
        safetyGuard: SafetyGuard(db.assetManifestDao, db.assetCopiesDao),
        providers: [fakeProvider],
      );
      addTearDown(gatedEngine.dispose);

      await gatedEngine.runSyncCycle(ConnectionType.wifi);

      expect(
        fakeProvider.uploadedLocalPaths.any((final p) => p.endsWith('small.mp4')),
        isTrue,
        reason: 'the transferable file behind a deferred one must still upload',
      );
      expect(
        fakeProvider.uploadedLocalPaths.any((final p) => p.endsWith('big.mp4')),
        isFalse,
        reason: 'the deferred file itself stays deferred',
      );
    });

    test('all-deferred sweep still surfaces waitingForWifi', () async {
      await _seedManifest(
        db,
        hash: 'big002',
        localPath: 'big2.mp4',
        fileSizeBytes: 5000,
      );
      await _seedManifest(
        db,
        hash: 'big003',
        localPath: 'big3.mp4',
        fileSizeBytes: 6000,
      );

      final gatedEngine = AssetSyncEngine(
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        opsDao: db.syncOperationsDao,
        hashService: AssetHashService(),
        networkPolicy: _SizeGatedPolicy(
          await SharedPreferences.getInstance(),
          deferOverBytes: 2000,
        ),
        safetyGuard: SafetyGuard(db.assetManifestDao, db.assetCopiesDao),
        providers: [fakeProvider],
      );
      addTearDown(gatedEngine.dispose);

      await gatedEngine.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.uploadedLocalPaths, isEmpty);
      expect(gatedEngine.state, SyncEngineState.waitingForWifi);
    });
  });

  group('queue drain loop', () {
    Future<void> seedUploads(final int count) async {
      for (var i = 0; i < count; i++) {
        final file = File('${tempDir.path}/drain_$i.mp4');
        await file.writeAsBytes(List.filled(64, i));
        await _seedManifest(db, hash: 'drain$i', localPath: 'drain_$i.mp4');
        await _seedOperation(
          db,
          id: 'op-drain-$i',
          hash: 'drain$i',
          operationType: 'upload',
        );
      }
    }

    test('one cycle drains the whole queue past maxConcurrent', () async {
      // WiFi caps a batch at 2 concurrent uploads — 5 queued ops must still
      // all complete in ONE cycle, not require ~3 manual sync taps.
      await seedUploads(5);

      await engine.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.uploadedLocalPaths.length, 5);
      expect(await db.syncOperationsDao.getQueued(), isEmpty);
    });

    test('pause interrupts the drain between operations', () async {
      await seedUploads(5);
      fakeProvider.onUpload = () {
        if (fakeProvider.uploadedLocalPaths.length == 2) engine.pause();
      };

      await engine.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.uploadedLocalPaths.length, 2);
      expect((await db.syncOperationsDao.getQueued()).length, 3,
          reason: 'paused mid-drain — remaining ops stay queued for resume');
      expect(engine.state, SyncEngineState.paused);
    });
  });

  group('state management', () {
    test('pause and resume', () async {
      engine.pause();
      expect(engine.state, SyncEngineState.paused);

      engine.resume(ConnectionType.wifi);
      expect(engine.state, SyncEngineState.idle);
    });
  });

  // Renames/category moves relocate the file and update the owning move —
  // not the manifest. The engine must re-derive the current path from the
  // owning entities, persist the heal, and upload; a file that is truly gone
  // fails with an honest message instead of reaching the provider.
  group('stale manifest path healing', () {
    const hash = 'stale01hash';

    test('heals localPath from the owning move and uploads', () async {
      final movedFile = File(
        '${tempDir.path}/Moves/Power/Windmill - stale01h.mp4',
      );
      await movedFile.parent.create(recursive: true);
      await movedFile.writeAsBytes(List.filled(64, 0));

      await db.movesDao.insertMove(const MovesCompanion(
        id: Value('move-1'),
        name: Value('Windmill'),
        category: Value('Power'),
        contentHash: Value(hash),
        videoPath: Value('Moves/Power/Windmill - stale01h.mp4'),
      ));
      await _seedManifest(db, hash: hash, localPath: 'Moves/Old/gone.mp4');
      await _seedOperation(db, id: 'op-heal', hash: hash, operationType: 'upload');

      await engine.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.uploadedLocalPaths, [movedFile.path]);
      final manifest = await db.assetManifestDao.getByHash(hash);
      expect(manifest!.localPath, 'Moves/Power/Windmill - stale01h.mp4');
    });

    // The 4.0 device read found 22 assets with NO owner of any kind — not
    // active, not archived, not soft-deleted — whose bytes were nevertheless
    // on disk under a different category directory. Lane 2 can only heal
    // toward an owner, so every one of them failed "Local file missing" and
    // re-queued forever. Identity is the hash in the filename, not the path.
    test('heals from the sandbox when no entity owns the content', () async {
      const hexHash = '69e13899aabbccdd';
      final strandedFile = File(
        '${tempDir.path}/Moves/Power moves/Air Flare - 69e13899.mp4',
      );
      await strandedFile.parent.create(recursive: true);
      await strandedFile.writeAsBytes(List.filled(64, 7));

      await _seedManifest(db, hash: hexHash, localPath: 'Moves/Old/gone.mp4');
      await _seedOperation(
        db,
        id: 'op-sandbox',
        hash: hexHash,
        operationType: 'upload',
      );

      await engine.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.uploadedLocalPaths, [strandedFile.path]);
      final manifest = await db.assetManifestDao.getByHash(hexHash);
      expect(manifest!.localPath, 'Moves/Power moves/Air Flare - 69e13899.mp4');
    });

    test('fails honestly when no owning entity has the file', () async {
      await _seedManifest(db, hash: hash, localPath: 'Moves/Old/gone.mp4');
      await _seedOperation(db, id: 'op-gone', hash: hash, operationType: 'upload');

      await engine.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.uploadedLocalPaths, isEmpty);
      final op = await (db.select(db.syncOperations)
            ..where((final t) => t.id.equals('op-gone')))
          .getSingle();
      expect(op.status, 'terminal');
      expect(op.errorMessage, contains('Bytes not found'));
      // The retry budget is untouched — terminal is a verdict, not an attempt.
      expect(op.retryCount, 0);
    });
  });

  group('terminal verdict (design D9, task 4.4)', () {
    const hash = 'gonehash01';

    /// D9's core defect: `operationExists` dedupes only against
    /// queued/in_progress, so each sweep re-inserted a fresh op with the
    /// retry budget reset — bounded per operation, unbounded per asset. The
    /// red must cover the SECOND cycle, where the sweep used to undo the
    /// verdict.
    test('terminal asset is not re-queued by the next sweep', () async {
      await _seedManifest(db, hash: hash, localPath: 'Moves/Old/gone.mp4');
      await _seedOperation(db, id: 'op-t1', hash: hash, operationType: 'upload');

      await engine.runSyncCycle(ConnectionType.wifi);
      await engine.runSyncCycle(ConnectionType.wifi);

      final ops = await (db.select(db.syncOperations)
            ..where((final t) => t.contentHash.equals(hash)))
          .get();
      expect(ops, hasLength(1));
      expect(ops.single.status, 'terminal');
      expect(fakeProvider.uploadedLocalPaths, isEmpty);
    });

    test('provider failure stays retryable, never terminal', () async {
      final file = File('${tempDir.path}/present.mp4');
      await file.writeAsBytes(List.filled(64, 1));
      await _seedManifest(db, hash: hash, localPath: 'present.mp4');
      await _seedOperation(db, id: 'op-t2', hash: hash, operationType: 'upload');
      fakeProvider.shouldThrowOnUpload = true;

      await engine.runSyncCycle(ConnectionType.wifi);

      final op = await (db.select(db.syncOperations)
            ..where((final t) => t.id.equals('op-t2')))
          .getSingle();
      expect(op.status, 'failed');
    });

    /// D11's lesson applied forward: the 22 "gone" videos were in quarantine
    /// all along. Terminal means "nowhere as of the last known path" — new
    /// bytes are new evidence, and the verdict must not outlive it.
    test('clearTerminal revives the asset for the next sweep', () async {
      await _seedManifest(db, hash: hash, localPath: 'Moves/Old/gone.mp4');
      await _seedOperation(db, id: 'op-t3', hash: hash, operationType: 'upload');
      await engine.runSyncCycle(ConnectionType.wifi);

      // Bytes come back (a restore re-homes them) and the verdict is cleared.
      final restored = File('${tempDir.path}/Moves/Old/gone.mp4');
      restored.parent.createSync(recursive: true);
      await restored.writeAsBytes(List.filled(64, 2));
      await db.syncOperationsDao.clearTerminal(hash);

      await engine.runSyncCycle(ConnectionType.wifi);

      expect(fakeProvider.uploadedLocalPaths, [restored.path]);
    });
  });

  group('copy identity', () {
    /// D7: ids used to be a fresh UUID per upload, so `insertOnConflictUpdate`
    /// never conflicted — each re-upload appended a row and `copyCount` could
    /// satisfy the two-copy minimum on one real cloud copy.
    test('re-uploading to the same provider keeps one copy row', () async {
      const hash = 'dedupehash';
      final file = File('${tempDir.path}/dedupe.mp4');
      await file.writeAsBytes(List.filled(64, 0));
      await _seedManifest(db, hash: hash, localPath: 'dedupe.mp4');
      await _seedCopy(db, id: '${hash}_local', hash: hash, provider: 'local');

      for (final opId in ['op-up-1', 'op-up-2']) {
        await _seedOperation(
          db,
          id: opId,
          hash: hash,
          operationType: 'upload',
        );
        await engine.runSyncCycle(ConnectionType.wifi);
      }

      final copies = await db.assetCopiesDao.getByHash(hash);
      expect(copies.where((final c) => c.provider == 'icloud').length, 1);
      expect(copies.length, 2);

      final manifest = await db.assetManifestDao.getByHash(hash);
      expect(manifest!.copyCount, 2);
    });
  });

  group('progress emission', () {
    /// D6: emissions used to come only from `_setState` — one at cycle start,
    /// one at the end — so a long sweep showed a frozen "17/72" throughout.
    /// Each settled operation must emit, success or failure.
    test('emits a progress event per settled operation', () async {
      final events = <SyncProgress>[];
      final sub = engine.progressStream.listen(events.add);

      for (var i = 0; i < 3; i++) {
        final file = File('${tempDir.path}/op_$i.mp4');
        await file.writeAsBytes(List.filled(64, 0));
        await _seedManifest(db, hash: 'hash$i', localPath: 'op_$i.mp4');
        await _seedOperation(
          db,
          id: 'op-$i',
          hash: 'hash$i',
          operationType: 'upload',
        );
      }

      await engine.runSyncCycle(ConnectionType.wifi);
      await pumpEventQueue();
      await sub.cancel();

      // 2 state transitions (syncing, idle) + 1 per settled operation.
      expect(events.length, greaterThanOrEqualTo(5));
    });

    test('emits a progress event when an operation fails', () async {
      fakeProvider.shouldThrowOnUpload = true;
      final events = <SyncProgress>[];
      final sub = engine.progressStream.listen(events.add);

      final file = File('${tempDir.path}/fails.mp4');
      await file.writeAsBytes(List.filled(64, 0));
      await _seedManifest(db, hash: 'failhash', localPath: 'fails.mp4');
      await _seedOperation(
        db,
        id: 'op-fail',
        hash: 'failhash',
        operationType: 'upload',
      );

      await engine.runSyncCycle(ConnectionType.wifi);
      await pumpEventQueue();
      await sub.cancel();

      expect(events.length, greaterThanOrEqualTo(3));
    });
  });
}
