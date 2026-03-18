import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/safety_guard.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// Insert a manifest entry and optional copies for testing.
  Future<void> seedManifest(
    AppDatabase db, {
    required String hash,
    DateTime? deletedAt,
  }) async {
    await db.assetManifestDao.upsert(AssetManifestCompanion(
      contentHash: Value(hash),
      fileSizeBytes: const Value(1024),
      sourceType: const Value('camera'),
      importedAt: Value(DateTime.now()),
      deletedAt: Value(deletedAt),
    ));
  }

  Future<void> seedCopy(
    AppDatabase db, {
    required String id,
    required String hash,
    required String provider,
    String status = 'pending',
  }) async {
    await db.assetCopiesDao.insertCopy(AssetCopiesCompanion(
      id: Value(id),
      contentHash: Value(hash),
      provider: Value(provider),
      status: Value(status),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  group('SafetyGuard', () {
    group('canDeleteLocal', () {
      test('returns false when no copies exist', () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);
        await seedManifest(db, hash: 'abc123');

        final result = await guard.canDeleteLocal('abc123');

        expect(result, isFalse);
      });

      test('returns false when only local copy exists', () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);
        await seedManifest(db, hash: 'abc123');
        await seedCopy(db,
            id: 'c1',
            hash: 'abc123',
            provider: 'local',
            status: 'verified');

        final result = await guard.canDeleteLocal('abc123');

        expect(result, isFalse);
      });

      test('returns false when remote copy is pending (not verified)',
          () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);
        await seedManifest(db, hash: 'abc123');
        await seedCopy(db,
            id: 'c1',
            hash: 'abc123',
            provider: 'icloud',
            status: 'pending');

        final result = await guard.canDeleteLocal('abc123');

        expect(result, isFalse);
      });

      test('returns true when verified remote copy exists', () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);
        await seedManifest(db, hash: 'abc123');
        await seedCopy(db,
            id: 'c1',
            hash: 'abc123',
            provider: 'icloud',
            status: 'verified');

        final result = await guard.canDeleteLocal('abc123');

        expect(result, isTrue);
      });

      test('returns true when multiple verified remote copies exist',
          () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);
        await seedManifest(db, hash: 'abc123');
        await seedCopy(db,
            id: 'c1',
            hash: 'abc123',
            provider: 'icloud',
            status: 'verified');
        await seedCopy(db,
            id: 'c2',
            hash: 'abc123',
            provider: 'gdrive',
            status: 'verified');

        final result = await guard.canDeleteLocal('abc123');

        expect(result, isTrue);
      });
    });

    group('circuitBreakerCheck', () {
      test('returns true for empty deletion list', () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);

        final result = await guard.circuitBreakerCheck([]);

        expect(result, isTrue);
      });

      test('returns true when no live assets exist', () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);

        final result = await guard.circuitBreakerCheck(['hash1']);

        expect(result, isTrue);
      });

      test('returns true when deleting <= 25% of library', () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);
        // Seed 10 live assets
        for (int i = 0; i < 10; i++) {
          await seedManifest(db, hash: 'hash_$i');
        }

        // Deleting 2 of 10 = 20% — within threshold
        final result =
            await guard.circuitBreakerCheck(['hash_0', 'hash_1']);

        expect(result, isTrue);
      });

      test('returns true when deleting exactly 25% of library', () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);
        for (int i = 0; i < 4; i++) {
          await seedManifest(db, hash: 'hash_$i');
        }

        // Deleting 1 of 4 = 25% — exactly at threshold
        final result = await guard.circuitBreakerCheck(['hash_0']);

        expect(result, isTrue);
      });

      test('returns false when deleting > 25% of library', () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);
        for (int i = 0; i < 4; i++) {
          await seedManifest(db, hash: 'hash_$i');
        }

        // Deleting 2 of 4 = 50% — exceeds threshold
        final result =
            await guard.circuitBreakerCheck(['hash_0', 'hash_1']);

        expect(result, isFalse);
      });

      test('excludes soft-deleted assets from live count', () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);
        // 4 live + 2 deleted = only 4 count as live
        for (int i = 0; i < 4; i++) {
          await seedManifest(db, hash: 'live_$i');
        }
        for (int i = 0; i < 2; i++) {
          await seedManifest(db,
              hash: 'deleted_$i',
              deletedAt: DateTime.now().subtract(const Duration(days: 5)));
        }

        // Deleting 2 of 4 live = 50% — exceeds threshold
        final result =
            await guard.circuitBreakerCheck(['live_0', 'live_1']);

        expect(result, isFalse);
      });
    });

    group('assertSafeToDeleteLocal', () {
      test('throws SafetyException when no verified remote', () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);
        await seedManifest(db, hash: 'abc123');

        expect(
          () => guard.assertSafeToDeleteLocal('abc123'),
          throwsA(isA<SafetyException>()),
        );
      });

      test('does not throw when verified remote exists', () async {
        final guard = SafetyGuard(db.assetManifestDao, db.assetCopiesDao);
        await seedManifest(db, hash: 'abc123');
        await seedCopy(db,
            id: 'c1',
            hash: 'abc123',
            provider: 'icloud',
            status: 'verified');

        // Should not throw
        await guard.assertSafeToDeleteLocal('abc123');
      });
    });
  });
}
