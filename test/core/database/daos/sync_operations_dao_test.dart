import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

import '../../../helpers/test_database.dart';

void main() {
  group('SyncOperationsDao.purgeResolvedFailed', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> insertManifest(final String hash) =>
        db.assetManifestDao.upsert(AssetManifestCompanion.insert(
          contentHash: hash,
          fileSizeBytes: 1024,
          sourceType: 'photos',
          importedAt: DateTime.utc(2026, 7, 1),
        ));

    Future<void> insertCopy(
      final String hash,
      final String provider,
      final String status,
    ) =>
        db.into(db.assetCopies).insert(AssetCopiesCompanion.insert(
              id: '${hash}_$provider',
              contentHash: hash,
              provider: provider,
              status: Value(status),
              createdAt: DateTime.utc(2026, 7, 1),
              updatedAt: DateTime.utc(2026, 7, 1),
            ));

    Future<void> insertOp(
      final String id,
      final String hash,
      final String status, {
      final String provider = 'gdrive',
    }) =>
        db.syncOperationsDao.insertOperation(SyncOperationsCompanion.insert(
          id: id,
          contentHash: hash,
          providerId: provider,
          operationType: 'upload',
          status: Value(status),
          createdAt: DateTime.utc(2026, 7, 1),
        ));

    Future<List<SyncOperation>> allOps() =>
        db.select(db.syncOperations).get();

    test('deletes failed ops superseded by a verified copy on that provider',
        () async {
      await insertManifest('hash-resolved');
      await insertCopy('hash-resolved', 'gdrive', 'verified');
      await insertOp('op-stale', 'hash-resolved', 'failed');

      final purged = await db.syncOperationsDao.purgeResolvedFailed();

      expect(purged, 1);
      expect(await allOps(), isEmpty);
    });

    test('keeps failed ops for assets still without a verified copy',
        () async {
      await insertManifest('hash-live');
      await insertCopy('hash-live', 'gdrive', 'pending');
      await insertOp('op-live', 'hash-live', 'failed');

      final purged = await db.syncOperationsDao.purgeResolvedFailed();

      expect(purged, 0);
      expect((await allOps()).map((final o) => o.id), ['op-live']);
    });

    test('a verified copy on a different provider resolves nothing', () async {
      await insertManifest('hash-cross');
      await insertCopy('hash-cross', 'local', 'verified');
      await insertOp('op-cross', 'hash-cross', 'failed');

      final purged = await db.syncOperationsDao.purgeResolvedFailed();

      expect(purged, 0);
      expect((await allOps()).map((final o) => o.id), ['op-cross']);
    });

    test('only failed rows are touched — queued, completed, and terminal stay',
        () async {
      await insertManifest('hash-mixed');
      await insertCopy('hash-mixed', 'gdrive', 'verified');
      await insertOp('op-queued', 'hash-mixed', 'queued');
      await insertOp('op-done', 'hash-mixed', 'completed');
      // Terminal is a live verdict revoked only by clearTerminal when bytes
      // re-home (task 4.4) — a sweep must never silently erase it.
      await insertOp('op-terminal', 'hash-mixed', 'terminal');
      await insertOp('op-failed', 'hash-mixed', 'failed');

      final purged = await db.syncOperationsDao.purgeResolvedFailed();

      expect(purged, 1);
      expect(
        (await allOps()).map((final o) => o.id).toSet(),
        {'op-queued', 'op-done', 'op-terminal'},
      );
    });
  });
}
