import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/daos/asset_copies_dao.dart';
import 'package:breakdex/core/database/database.dart';

import '../../../helpers/test_database.dart';

/// A tile may only claim "restorable from the cloud" when a cloud copy is
/// actually verified. Task 5.3: the grid used to key that claim off
/// `contentHash != null`, which means "we know this asset's hash" — an
/// assertion about bookkeeping, not about protection.
void main() {
  group('AssetCopiesDao.watchRestorableHashes', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seedAsset(final String hash) =>
        db.assetManifestDao.upsert(AssetManifestCompanion.insert(
          contentHash: hash,
          fileSizeBytes: 1024,
          sourceType: 'photos',
          importedAt: DateTime.utc(2026, 5, 1),
        ));

    Future<void> seedCopy(
      final String hash,
      final String provider,
      final String status,
    ) =>
        db.assetCopiesDao.upsertCopy(AssetCopiesCompanion.insert(
          id: AssetCopiesDao.copyId(hash, provider),
          contentHash: hash,
          provider: provider,
          status: Value(status),
          createdAt: DateTime.utc(2026, 5, 1),
          updatedAt: DateTime.utc(2026, 5, 1),
        ));

    test('reports only assets with a verified non-local copy', () async {
      for (final hash in ['verified', 'uploading', 'localOnly', 'failed']) {
        await seedAsset(hash);
      }
      // Every asset is "tracked" — each has a hash and a local copy. That is
      // exactly the state the old indicator could not tell apart.
      for (final hash in ['verified', 'uploading', 'localOnly', 'failed']) {
        await seedCopy(hash, 'local', 'verified');
      }
      await seedCopy('verified', 'gdrive', 'verified');
      await seedCopy('uploading', 'gdrive', 'uploading');
      await seedCopy('failed', 'gdrive', 'failed');

      final restorable = await db.assetCopiesDao.watchRestorableHashes().first;

      expect(restorable, {'verified'});
    });

    test('re-emits when an upload completes', () async {
      await seedAsset('hash-1');
      await seedCopy('hash-1', 'local', 'verified');
      await seedCopy('hash-1', 'gdrive', 'uploading');

      final stream = db.assetCopiesDao.watchRestorableHashes();
      expect(await stream.first, isEmpty);

      await db.assetCopiesDao
          .markVerified(AssetCopiesDao.copyId('hash-1', 'gdrive'));

      expect(await stream.first, {'hash-1'});
    });
  });
}
