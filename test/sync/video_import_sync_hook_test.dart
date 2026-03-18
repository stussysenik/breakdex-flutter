import 'dart:io';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/connectivity_service.dart';
import 'package:breakdex/core/sync/asset_hash_service.dart';
import 'package:breakdex/core/sync/asset_sync_engine.dart';
import 'package:breakdex/core/sync/network_policy.dart';
import 'package:breakdex/core/sync/safety_guard.dart';
import 'package:breakdex/core/sync/video_import_sync_hook.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late AssetHashService hashService;
  late AssetSyncEngine syncEngine;
  late ConnectivityService connectivityService;
  late VideoImportSyncHook hook;

  setUp(() async {
    db = createTestDatabase();
    hashService = AssetHashService();
    connectivityService = ConnectivityService();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    syncEngine = AssetSyncEngine(
      manifestDao: db.assetManifestDao,
      copiesDao: db.assetCopiesDao,
      opsDao: db.syncOperationsDao,
      hashService: hashService,
      networkPolicy: NetworkPolicy(prefs),
      safetyGuard: SafetyGuard(db.assetManifestDao, db.assetCopiesDao),
      providers: [], // No cloud providers — just verify local pipeline
    );

    hook = VideoImportSyncHook(
      hashService: hashService,
      manifestDao: db.assetManifestDao,
      copiesDao: db.assetCopiesDao,
      movesDao: db.movesDao,
      syncEngine: syncEngine,
      connectivityService: connectivityService,
    );
  });

  tearDown(() async {
    syncEngine.dispose();
    connectivityService.dispose();
    await db.close();
  });

  group('VideoImportSyncHook', () {
    test('registers manifest, copy, and links move on import', () async {
      // Create a temporary video file to hash
      final tempDir = Directory.systemTemp.createTempSync('hook_test_');
      final tempFile = File('${tempDir.path}/test_video.mp4');
      await tempFile.writeAsBytes(List.generate(1024, (i) => i % 256));

      // Insert a move without contentHash
      const moveId = 'test-move-001';
      await db.movesDao.insertMove(MovesCompanion.insert(
        id: moveId,
        name: 'Test Move',
        videoPath: Value(tempFile.path),
      ));

      // Run the hook
      await hook.onVideoImported(
        localPath: tempFile.path,
        moveId: moveId,
      );

      // Verify: move now has a contentHash
      final move = await db.movesDao.getById(moveId);
      expect(move, isNotNull);
      expect(move!.contentHash, isNotNull);
      expect(move.contentHash!.length, equals(64)); // SHA-256 hex = 64 chars

      // Verify: asset_manifest entry exists
      final manifest =
          await db.assetManifestDao.getByHash(move.contentHash!);
      expect(manifest, isNotNull);
      expect(manifest!.fileSizeBytes, equals(1024));
      expect(manifest.sourceType, equals('photos'));
      expect(manifest.localPath, equals(tempFile.path));

      // Verify: local copy exists and is verified
      final copies = await db.assetCopiesDao.getByHash(move.contentHash!);
      expect(copies, hasLength(1));
      expect(copies.first.provider, equals('local'));
      expect(copies.first.status, equals('verified'));

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });

    test('handles missing file gracefully', () async {
      const moveId = 'test-move-002';
      await db.movesDao.insertMove(MovesCompanion.insert(
        id: moveId,
        name: 'Ghost Move',
      ));

      // Should not throw — just logs and returns
      await hook.onVideoImported(
        localPath: '/nonexistent/path/video.mp4',
        moveId: moveId,
      );

      // Move should NOT have a contentHash
      final move = await db.movesDao.getById(moveId);
      expect(move!.contentHash, isNull);
    });

    test('deduplicates on same content hash', () async {
      final tempDir = Directory.systemTemp.createTempSync('hook_dedup_');
      final tempFile = File('${tempDir.path}/same_video.mp4');
      await tempFile.writeAsBytes(List.generate(512, (i) => i % 256));

      // Import same file for two different moves
      const moveId1 = 'move-dup-1';
      const moveId2 = 'move-dup-2';
      await db.movesDao.insertMove(MovesCompanion.insert(
        id: moveId1,
        name: 'Dup Move A',
        videoPath: Value(tempFile.path),
      ));
      await db.movesDao.insertMove(MovesCompanion.insert(
        id: moveId2,
        name: 'Dup Move B',
        videoPath: Value(tempFile.path),
      ));

      await hook.onVideoImported(localPath: tempFile.path, moveId: moveId1);
      await hook.onVideoImported(localPath: tempFile.path, moveId: moveId2);

      // Both moves should share the same contentHash
      final move1 = await db.movesDao.getById(moveId1);
      final move2 = await db.movesDao.getById(moveId2);
      expect(move1!.contentHash, equals(move2!.contentHash));

      // Only one manifest entry (content-addressable)
      final manifest =
          await db.assetManifestDao.getByHash(move1.contentHash!);
      expect(manifest, isNotNull);

      tempDir.deleteSync(recursive: true);
    });
  });
}
