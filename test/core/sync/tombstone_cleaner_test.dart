import 'dart:io';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/cloud_provider.dart';
import 'package:breakdex/core/sync/tombstone_cleaner.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

/// A fake cloud provider for testing tombstone cleanup.
class FakeCloudProvider implements CloudProvider {
  final List<String> deletedPaths = [];
  bool shouldThrow = false;

  @override
  String get providerType => 'icloud';

  @override
  String get displayName => 'Fake iCloud';

  @override
  Set<CloudProviderCapability> get capabilities => {};

  @override
  Future<bool> authenticate() async => true;

  @override
  Future<void> deauthenticate() async {}

  @override
  Future<bool> get isAuthenticated async => true;

  @override
  Future<RemoteAsset> upload({
    required String localPath,
    required String remotePath,
    TransferProgress? onProgress,
    CancellationToken? cancel,
  }) async =>
      RemoteAsset(remotePath: remotePath, sizeBytes: 0);

  @override
  Future<void> download({
    required String remotePath,
    required String localPath,
    TransferProgress? onProgress,
    CancellationToken? cancel,
  }) async {}

  @override
  Future<bool> verify({
    required String remotePath,
    String? expectedHash,
    int? expectedSize,
  }) async =>
      true;

  @override
  Future<List<RemoteAsset>> list({required String directory}) async => [];

  @override
  Future<void> delete({required String remotePath}) async {
    if (shouldThrow) throw Exception('Cloud delete failed');
    deletedPaths.add(remotePath);
  }

  @override
  Future<({int totalBytes, int usedBytes})?> quota() async => null;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedManifest(
    AppDatabase db, {
    required String hash,
    String? localPath,
    DateTime? deletedAt,
    String? tombstoneReason,
  }) async {
    await db.assetManifestDao.upsert(AssetManifestCompanion(
      contentHash: Value(hash),
      fileSizeBytes: const Value(1024),
      sourceType: const Value('camera'),
      importedAt: Value(DateTime.now()),
      localPath: Value(localPath),
      deletedAt: Value(deletedAt),
      tombstoneReason: Value(tombstoneReason),
    ));
  }

  Future<void> seedCopy(
    AppDatabase db, {
    required String id,
    required String hash,
    required String provider,
    String? remotePath,
    String status = 'verified',
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

  Future<void> seedOperation(
    AppDatabase db, {
    required String id,
    required String hash,
  }) async {
    await db.syncOperationsDao.insertOperation(SyncOperationsCompanion(
      id: Value(id),
      contentHash: Value(hash),
      providerId: const Value('provider-1'),
      operationType: const Value('upload'),
      createdAt: Value(DateTime.now()),
    ));
  }

  group('TombstoneCleaner', () {
    test('returns empty report when no tombstoned assets exist', () async {
      final cleaner = TombstoneCleaner(
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        opsDao: db.syncOperationsDao,
        providers: [],
      );

      final report = await cleaner.cleanup();

      expect(report.assetsProcessed, 0);
      expect(report.localFilesDeleted, 0);
      expect(report.remoteCopiesDeleted, 0);
      expect(report.errors, 0);
    });

    test('skips assets deleted less than 30 days ago', () async {
      final cleaner = TombstoneCleaner(
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        opsDao: db.syncOperationsDao,
        providers: [],
      );

      // Deleted 15 days ago — within grace period
      await seedManifest(db,
          hash: 'recent',
          deletedAt: DateTime.now().subtract(const Duration(days: 15)),
          tombstoneReason: 'user');

      final report = await cleaner.cleanup();

      expect(report.assetsProcessed, 0);

      // Verify the manifest still exists
      final manifest = await db.assetManifestDao.getByHash('recent');
      expect(manifest, isNotNull);
    });

    test('cleans assets deleted more than 30 days ago', () async {
      final cleaner = TombstoneCleaner(
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        opsDao: db.syncOperationsDao,
        providers: [],
      );

      // Deleted 31 days ago — past grace period
      await seedManifest(db,
          hash: 'old_asset',
          deletedAt: DateTime.now().subtract(const Duration(days: 31)),
          tombstoneReason: 'user');

      final report = await cleaner.cleanup();

      expect(report.assetsProcessed, 1);

      // Verify the manifest was hard-deleted
      final manifest = await db.assetManifestDao.getByHash('old_asset');
      expect(manifest, isNull);
    });

    test('deletes local file when it exists', () async {
      final dir = Directory.systemTemp.createTempSync('tombstone_test_');
      final file = File('${dir.path}/old_video.mp4')
        ..writeAsBytesSync([1, 2, 3]);

      final cleaner = TombstoneCleaner(
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        opsDao: db.syncOperationsDao,
        providers: [],
      );

      await seedManifest(db,
          hash: 'file_asset',
          localPath: file.path,
          deletedAt: DateTime.now().subtract(const Duration(days: 31)),
          tombstoneReason: 'user');

      final report = await cleaner.cleanup();

      expect(report.localFilesDeleted, 1);
      expect(file.existsSync(), isFalse);

      dir.deleteSync(recursive: true);
    });

    test('deletes remote copies via cloud provider', () async {
      final fakeProvider = FakeCloudProvider();

      final cleaner = TombstoneCleaner(
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        opsDao: db.syncOperationsDao,
        providers: [fakeProvider],
      );

      await seedManifest(db,
          hash: 'remote_asset',
          deletedAt: DateTime.now().subtract(const Duration(days: 31)),
          tombstoneReason: 'user');
      await seedCopy(db,
          id: 'c1',
          hash: 'remote_asset',
          provider: 'icloud',
          remotePath: '/videos/remote_asset.mp4');

      final report = await cleaner.cleanup();

      expect(report.remoteCopiesDeleted, 1);
      expect(fakeProvider.deletedPaths, ['/videos/remote_asset.mp4']);

      // Verify copies and manifest are hard-deleted
      final copies = await db.assetCopiesDao.getByHash('remote_asset');
      expect(copies, isEmpty);
      final manifest = await db.assetManifestDao.getByHash('remote_asset');
      expect(manifest, isNull);
    });

    test('skips local copies when deleting remote', () async {
      final fakeProvider = FakeCloudProvider();

      final cleaner = TombstoneCleaner(
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        opsDao: db.syncOperationsDao,
        providers: [fakeProvider],
      );

      await seedManifest(db,
          hash: 'mixed_asset',
          deletedAt: DateTime.now().subtract(const Duration(days: 31)),
          tombstoneReason: 'user');
      await seedCopy(db,
          id: 'local-1',
          hash: 'mixed_asset',
          provider: 'local');
      await seedCopy(db,
          id: 'remote-1',
          hash: 'mixed_asset',
          provider: 'icloud',
          remotePath: '/videos/mixed.mp4');

      final report = await cleaner.cleanup();

      // Only the icloud copy triggers a provider delete
      expect(report.remoteCopiesDeleted, 1);
      expect(fakeProvider.deletedPaths, ['/videos/mixed.mp4']);
    });

    test('hard-deletes sync operations for cleaned assets', () async {
      final cleaner = TombstoneCleaner(
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        opsDao: db.syncOperationsDao,
        providers: [],
      );

      await seedManifest(db,
          hash: 'ops_asset',
          deletedAt: DateTime.now().subtract(const Duration(days: 31)),
          tombstoneReason: 'user');
      await seedOperation(db, id: 'op-1', hash: 'ops_asset');

      await cleaner.cleanup();

      // Verify operations were cleaned up
      final ops = await db.syncOperationsDao.getQueued(limit: 100);
      final matching = ops.where((o) => o.contentHash == 'ops_asset');
      expect(matching, isEmpty);
    });

    test('counts errors when cloud delete fails', () async {
      final fakeProvider = FakeCloudProvider()..shouldThrow = true;

      final cleaner = TombstoneCleaner(
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        opsDao: db.syncOperationsDao,
        providers: [fakeProvider],
      );

      await seedManifest(db,
          hash: 'error_asset',
          deletedAt: DateTime.now().subtract(const Duration(days: 31)),
          tombstoneReason: 'user');
      await seedCopy(db,
          id: 'c1',
          hash: 'error_asset',
          provider: 'icloud',
          remotePath: '/videos/error.mp4');

      final report = await cleaner.cleanup();

      expect(report.errors, 1);
      // Manifest is still hard-deleted despite the remote copy error
      expect(report.assetsProcessed, 1);
    });
  });
}
