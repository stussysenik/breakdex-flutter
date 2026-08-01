import 'dart:io';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/sync/sync_diagnostics.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  // `getAll()` orders `importedAt DESC`, so report order is fixture data, not
  // insertion order. Stamping every row `DateTime.now()` made the assertions
  // below pass only while two inserts landed in one clock tick — under load the
  // timestamps separated, h2 sorted ahead of h1, and the suite disagreed with
  // itself. Explicit descending stamps make the expected order a property of
  // the fixture instead of the machine.
  var seedClock = DateTime.utc(2026, 7, 30, 12);

  Future<void> seedManifest(
    final String hash, {
    final int copyCount = 0,
    final DateTime? deletedAt,
  }) async {
    final importedAt = seedClock;
    seedClock = seedClock.subtract(const Duration(minutes: 1));
    await db.assetManifestDao.upsert(AssetManifestCompanion(
      contentHash: Value(hash),
      fileSizeBytes: const Value(1024),
      sourceType: const Value('camera'),
      importedAt: Value(importedAt),
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

    expect(lines, hasLength(13));
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
    // Positive control: with no moves seeded at all, 0/2 is the *correct*
    // reading and the ORPHAN verdicts below are trustworthy only because the
    // control is separately proven to fire (see the test that seeds a move).
    expect(lines[7], 'owner-join control: 0/2 live manifest hashes match ≥1 move');
    // The rescue/gone split — the reading that decides whether an unreachable
    // asset is 4.7's business (bytes on disk) or 4.8's (bytes truly gone).
    expect(
      lines[8],
      'sandbox rescue: 0 of 2 unreachable assets have bytes on disk',
    );
    expect(lines[9], 'unresolvable assets: 2 (ORPHAN: 2)');
    expect(lines[10], contains('ORPHAN — terminal: manifest row has no owning'));
    expect(
      lines[11],
      startsWith('  ORPHAN h1 owners=0(0 archived, 0 deleted)+0combo'),
    );
    expect(lines[11], endsWith('bytes not found in sandbox'));
    expect(
      lines[12],
      startsWith('  ORPHAN h2 owners=0(0 archived, 0 deleted)+0combo'),
    );
  });

  Future<void> seedMove(
    final String id,
    final String hash, {
    final DateTime? deletedAt,
  }) async {
    await db.into(db.moves).insert(MovesCompanion.insert(
          id: id,
          name: 'Move $id',
          contentHash: Value(hash),
          deletedAt: Value(deletedAt),
        ));
  }

  // The positive control earns its place only if it can read non-zero. Without
  // this test, "owner-join control: 0/N" on a device is indistinguishable from
  // a join that never matches — which is precisely the doubt it exists to kill.
  test('owner-join control counts hashes that do match a move', () async {
    await seedManifest('h1');
    await seedManifest('h2');
    await seedMove('m1', 'h1');

    final report = await SyncDiagnostics(db).dump();

    expect(
      report,
      contains('owner-join control: 1/2 live manifest hashes match ≥1 move'),
    );
  });

  // The split earns its place only if it can read non-zero — the same doubt
  // the owner-join control exists to kill. A report that always says "0 have
  // bytes on disk" would send every unreachable asset to the tombstone lane.
  test('an unreachable asset whose bytes are in the sandbox reads found',
      () async {
    final docs = Directory.systemTemp.createTempSync('diag_sandbox');
    addTearDown(() => docs.deleteSync(recursive: true));
    VideoPathResolver.docsPathOverride = docs.path;

    final stranded = File(
      p.join(docs.path, 'Moves', 'Power moves', 'Air Flare - 69e13899.mp4'),
    );
    stranded.parent.createSync(recursive: true);
    stranded.writeAsBytesSync(List.filled(16, 3));

    await seedManifest('69e13899aabb');

    final report = await SyncDiagnostics(db).dump();

    expect(
      report,
      contains('sandbox rescue: 1 of 1 unreachable assets have bytes on disk'),
    );
    expect(
      report,
      contains('bytes found on disk at Moves/Power moves/Air Flare - 69e13899.mp4'),
    );
  });

  // A soft-deleted owner is recoverable; a missing one is not. Reporting both
  // as ORPHAN would point the fix at the wrong repair.
  test('a soft-deleted owner reads DELETED-OWNER, not ORPHAN', () async {
    await seedManifest('h1');
    await seedMove('m1', 'h1', deletedAt: DateTime.now());

    final report = await SyncDiagnostics(db).dump();

    expect(report, contains('unresolvable assets: 1 (DELETED-OWNER: 1)'));
    expect(report, contains('DELETED-OWNER h1 owners=0(0 archived, 1 deleted)'));
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
        'owner-join control: 0/0 live manifest hashes match ≥1 move',
        // An empty database has nothing unreachable — the section must say so
        // rather than going silent, so "no line" never reads as "not checked".
        'unresolvable assets: none',
      ],
    );
  });
}
