import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/sync_diagnostics.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedManifest(
    final String hash, {
    final int copyCount = 0,
    final DateTime? deletedAt,
  }) async {
    await db.assetManifestDao.upsert(AssetManifestCompanion(
      contentHash: Value(hash),
      fileSizeBytes: const Value(1024),
      sourceType: const Value('camera'),
      importedAt: Value(DateTime.now()),
      copyCount: Value(copyCount),
      deletedAt: Value(deletedAt),
    ));
  }

  Future<void> seedCopy(
    final String id,
    final String hash,
    final String provider,
    final String status,
  ) async {
    await db.assetCopiesDao.insertCopy(AssetCopiesCompanion(
      id: Value(id),
      contentHash: Value(hash),
      provider: Value(provider),
      status: Value(status),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> seedOp(
    final String id,
    final String hash,
    final String status,
  ) async {
    await db.syncOperationsDao.insertOperation(SyncOperationsCompanion(
      id: Value(id),
      contentHash: Value(hash),
      providerId: const Value('gdrive'),
      operationType: const Value('upload'),
      status: Value(status),
      createdAt: Value(DateTime.now()),
    ));
  }

  test('dump reports manifest counts, copies by provider×status, ops by status',
      () async {
    await seedManifest('h1', copyCount: 2);
    await seedManifest('h2');
    await seedManifest('h3', deletedAt: DateTime.now());
    await seedCopy('c1', 'h1', 'local', 'verified');
    await seedCopy('c2', 'h1', 'gdrive', 'verified');
    await seedCopy('c3', 'h2', 'gdrive', 'failed');
    await seedOp('o1', 'h2', 'queued');
    await seedOp('o2', 'h2', 'failed');
    await seedOp('o3', 'h1', 'queued');

    final report = await SyncDiagnostics(db).dump();
    final lines = report.split('\n');

    expect(lines, hasLength(3));
    expect(
      lines[0],
      'asset_manifest: 3 rows (2 live, 1 underprotected, 1 tombstoned)',
    );
    expect(
      lines[1],
      'asset_copies: gdrive×failed: 1 · gdrive×verified: 1 · local×verified: 1',
    );
    expect(lines[2], 'sync_operations: failed: 1 · queued: 2');
  });

  test('dump on an empty database reports zeros, not errors', () async {
    final report = await SyncDiagnostics(db).dump();

    expect(
      report.split('\n'),
      [
        'asset_manifest: 0 rows (0 live, 0 underprotected, 0 tombstoned)',
        'asset_copies: (none)',
        'sync_operations: (none)',
      ],
    );
  });
}
