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
    final String status, {
    final String? errorMessage,
  }) async {
    await db.syncOperationsDao.insertOperation(SyncOperationsCompanion(
      id: Value(id),
      contentHash: Value(hash),
      providerId: const Value('gdrive'),
      operationType: const Value('upload'),
      status: Value(status),
      errorMessage: Value(errorMessage),
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
    await seedOp('o2', 'h2', 'failed', errorMessage: 'DetailedApiRequestError');
    await seedOp('o3', 'h1', 'queued');
    await seedOp('o4', 'h1', 'failed', errorMessage: 'DetailedApiRequestError');
    await seedOp('o5', 'h3', 'failed');

    final report = await SyncDiagnostics(db).dump();
    final lines = report.split('\n');

    expect(lines, hasLength(11));
    expect(
      lines[0],
      'asset_manifest: 3 rows (2 live, 1 underprotected, 1 tombstoned)',
    );
    // The 4.0 question, answerable from the dump: live assets whose bytes are
    // on disk but which carry no `local` copy row. Nothing here resolves to a
    // real file, so the honest answer is 0 rather than a guess.
    expect(lines[1], 'on disk without a local copy row: 0');
    expect(
      lines[2],
      'asset_copies: gdrive×failed: 1 · gdrive×verified: 1 · local×verified: 1',
    );
    expect(lines[3], 'sync_operations: failed: 3 · queued: 2');
    // Failed-op errors, grouped by message, most frequent first.
    expect(lines[4], 'failed op errors:');
    expect(lines[5], '  2× DetailedApiRequestError');
    expect(lines[6], '  1× (no error message)');
    // Per-asset forensics (design D8). These fixtures have no owning move or
    // combo at all, so both live assets are ORPHAN — the one verdict that
    // widening the heal's query could never recover. Asserting the verdict,
    // not just the count, is the point: an ORPHAN misreported as BYTES-GONE
    // would send the fix at the wrong query.
    expect(lines[7], 'unresolvable assets: 2 (ORPHAN: 2)');
    expect(lines[8], contains('ORPHAN — terminal: manifest row has no owning'));
    expect(lines[9], startsWith('  ORPHAN h1 owners=0(0 archived)+0combo'));
    expect(lines[10], startsWith('  ORPHAN h2 owners=0(0 archived)+0combo'));
  });

  test('dump on an empty database reports zeros, not errors', () async {
    final report = await SyncDiagnostics(db).dump();

    expect(
      report.split('\n'),
      [
        'asset_manifest: 0 rows (0 live, 0 underprotected, 0 tombstoned)',
        'on disk without a local copy row: 0',
        'asset_copies: (none)',
        'sync_operations: (none)',
        // An empty database has nothing unreachable — the section must say so
        // rather than going silent, so "no line" never reads as "not checked".
        'unresolvable assets: none',
      ],
    );
  });
}
