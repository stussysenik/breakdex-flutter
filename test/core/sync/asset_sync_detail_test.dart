import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/asset_copies_dao.dart';
import 'package:breakdex/core/sync/asset_sync_detail.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

final _now = DateTime(2026, 7, 18, 12);

AssetManifestData _manifest({
  required final String hash,
  final String? localPath,
  final String? sourceName,
  final int fileSizeBytes = 1024,
  final DateTime? deletedAt,
}) =>
    AssetManifestData(
      contentHash: hash,
      fileSizeBytes: fileSizeBytes,
      mimeType: 'video/mp4',
      localPath: localPath,
      sourceType: 'camera',
      sourceName: sourceName,
      importedAt: _now,
      deletedAt: deletedAt,
      copyCount: 1,
    );

AssetCopy _copy({
  required final String hash,
  required final String provider,
  final String status = 'verified',
}) =>
    AssetCopy(
      id: AssetCopiesDao.copyId(hash, provider),
      contentHash: hash,
      provider: provider,
      status: status,
      createdAt: _now,
      updatedAt: _now,
    );

SyncOperation _op({
  required final String hash,
  required final String status,
  final String id = 'op1',
  final int bytesTransferred = 0,
  final int retryCount = 0,
  final int maxRetries = 3,
  final String? errorMessage,
  final DateTime? completedAt,
}) =>
    SyncOperation(
      id: id,
      contentHash: hash,
      providerId: 'gdrive',
      operationType: 'upload',
      status: status,
      priority: 0,
      retryCount: retryCount,
      maxRetries: maxRetries,
      errorMessage: errorMessage,
      bytesTransferred: bytesTransferred,
      totalBytes: 0,
      createdAt: _now,
      completedAt: completedAt,
    );

AssetSyncDetail _only(final List<AssetSyncDetail> details) {
  expect(details, hasLength(1));
  return details.single;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildAssetSyncDetails — classification', () {
    test('an in-progress operation reads as uploading, with byte progress', () {
      final detail = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1', fileSizeBytes: 1000)],
        copies: const [],
        operations: [
          _op(hash: 'h1', status: 'in_progress', bytesTransferred: 250),
        ],
      ));

      expect(detail.status, AssetSyncStatus.uploading);
      expect(detail.transferredBytes, 250);
      expect(detail.fraction, closeTo(0.25, 0.001));
    });

    test('a verified cloud copy reads as backed up', () {
      final detail = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1')],
        copies: [_copy(hash: 'h1', provider: 'gdrive')],
        operations: const [],
      ));

      expect(detail.status, AssetSyncStatus.backedUp);
    });

    test(
      'a verified LOCAL copy alone is never backed up — local bytes are not '
      'cloud protection',
      () {
        final detail = _only(buildAssetSyncDetails(
          manifests: [_manifest(hash: 'h1')],
          copies: [_copy(hash: 'h1', provider: 'local')],
          operations: const [],
        ));

        expect(detail.status, AssetSyncStatus.pending);
      },
    );

    test('an unverified cloud copy is not backed up', () {
      final detail = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1')],
        copies: [_copy(hash: 'h1', provider: 'gdrive', status: 'uploading')],
        operations: const [],
      ));

      expect(detail.status, AssetSyncStatus.pending);
    });

    test('in-flight work outranks an existing cloud copy', () {
      final detail = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1')],
        copies: [_copy(hash: 'h1', provider: 'gdrive')],
        operations: [_op(hash: 'h1', status: 'in_progress')],
      ));

      expect(detail.status, AssetSyncStatus.uploading);
    });

    test('a queued operation outranks a failure — a retry is under way', () {
      final detail = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1')],
        copies: const [],
        operations: [
          _op(
            hash: 'h1',
            id: 'old',
            status: 'failed',
            errorMessage: 'boom',
            completedAt: _now,
          ),
          _op(hash: 'h1', id: 'new', status: 'queued'),
        ],
      ));

      expect(detail.status, AssetSyncStatus.queued);
      expect(detail.errorMessage, isNull);
    });

    test('a failure surfaces the newest error message', () {
      final detail = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1')],
        copies: const [],
        operations: [
          _op(
            hash: 'h1',
            id: 'older',
            status: 'failed',
            errorMessage: 'stale error',
            completedAt: _now,
          ),
          _op(
            hash: 'h1',
            id: 'newer',
            status: 'failed',
            errorMessage: 'real error',
            completedAt: _now.add(const Duration(minutes: 5)),
          ),
        ],
      ));

      expect(detail.status, AssetSyncStatus.failed);
      expect(detail.errorMessage, 'real error');
    });

    test('only the terminal verdict marks a failure terminal (4.4)', () {
      // An exhausted budget is NOT terminal: the next sweep inserts a fresh
      // operation with the count reset, so this asset will be retried.
      final exhausted = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1')],
        copies: const [],
        operations: [
          _op(hash: 'h1', status: 'failed', retryCount: 3, maxRetries: 3),
        ],
      ));
      expect(exhausted.status, AssetSyncStatus.failed);
      expect(exhausted.isTerminal, isFalse);

      // The engine's bytes-nowhere verdict is — and it must still read as a
      // failure, never fall through to pending.
      final terminal = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1')],
        copies: const [],
        operations: [
          _op(hash: 'h1', status: 'terminal', errorMessage: 'Bytes not found'),
        ],
      ));
      expect(terminal.status, AssetSyncStatus.failed);
      expect(terminal.errorMessage, 'Bytes not found');
      expect(terminal.isTerminal, isTrue);
    });

    test('an untouched asset reads as pending, not failed', () {
      final detail = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1')],
        copies: const [],
        operations: const [],
      ));

      expect(detail.status, AssetSyncStatus.pending);
      expect(detail.errorMessage, isNull);
      expect(detail.isTerminal, isFalse);
    });

    test('a completed operation leaves no trace of its own', () {
      final detail = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1')],
        copies: [_copy(hash: 'h1', provider: 'gdrive')],
        operations: [_op(hash: 'h1', status: 'completed')],
      ));

      expect(detail.status, AssetSyncStatus.backedUp);
    });

    test('tombstoned assets are excluded — they await nothing', () {
      final details = buildAssetSyncDetails(
        manifests: [
          _manifest(hash: 'live'),
          _manifest(hash: 'dead', deletedAt: _now),
        ],
        copies: const [],
        operations: const [],
      );

      expect(details.map((final d) => d.contentHash), ['live']);
    });

    test('a zero-byte transfer reports no fraction rather than a fake 0%', () {
      final detail = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1', fileSizeBytes: 1000)],
        copies: const [],
        operations: [_op(hash: 'h1', status: 'in_progress')],
      ));

      expect(detail.fraction, isNull);
    });
  });

  group('buildAssetSyncDetails — presentation', () {
    test('label prefers the current on-disk name, which tracks renames', () {
      final detail = _only(buildAssetSyncDetails(
        manifests: [
          _manifest(
            hash: 'h1',
            localPath: '/videos/Power moves/flare.mp4',
            sourceName: 'IMG_0042.mov',
          ),
        ],
        copies: const [],
        operations: const [],
      ));

      expect(detail.label, 'flare.mp4');
    });

    test('label falls back to the import source, then to a short hash', () {
      final withSource = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1', sourceName: 'IMG_0042.mov')],
        copies: const [],
        operations: const [],
      ));
      expect(withSource.label, 'IMG_0042.mov');

      final bare = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'a' * 64)],
        copies: const [],
        operations: const [],
      ));
      expect(bare.label, 'a' * 12);
    });

    test('rows needing attention sort ahead of settled ones', () {
      final details = buildAssetSyncDetails(
        manifests: [
          _manifest(hash: 'done'),
          _manifest(hash: 'waiting'),
          _manifest(hash: 'broken'),
          _manifest(hash: 'moving'),
          _manifest(hash: 'untouched'),
        ],
        copies: [_copy(hash: 'done', provider: 'gdrive')],
        operations: [
          _op(hash: 'waiting', id: 'q', status: 'queued'),
          _op(hash: 'broken', id: 'f', status: 'failed', errorMessage: 'x'),
          _op(hash: 'moving', id: 'p', status: 'in_progress'),
        ],
      );

      expect(
        details.map((final d) => d.contentHash),
        ['moving', 'waiting', 'broken', 'untouched', 'done'],
      );
    });

    test('per-provider copy states are exposed, sorted by provider', () {
      final detail = _only(buildAssetSyncDetails(
        manifests: [_manifest(hash: 'h1')],
        copies: [
          _copy(hash: 'h1', provider: 'local'),
          _copy(hash: 'h1', provider: 'gdrive', status: 'uploading'),
        ],
        operations: const [],
      ));

      expect(detail.copies.map((final c) => c.provider), ['gdrive', 'local']);
      expect(detail.copies.first.status, 'uploading');
    });
  });

  group('AssetSyncTally — the three-way split', () {
    AssetSyncDetail row(
      final AssetSyncStatus status, {
      final bool isTerminal = false,
    }) =>
        AssetSyncDetail(
          contentHash: 'h',
          label: 'a.mp4',
          fileSizeBytes: 1000,
          status: status,
          transferredBytes: 0,
          errorMessage: null,
          isTerminal: isTerminal,
          copies: const [],
        );

    test('queued and pending are one "waiting" bucket — both mean nothing '
        'is moving', () {
      final tally = AssetSyncTally.from([
        row(AssetSyncStatus.queued),
        row(AssetSyncStatus.pending),
      ]);

      expect(tally.waiting, 2);
      expect(tally.uploading, 0);
    });

    test('a failed asset splits on its retry budget, not on being failed', () {
      final tally = AssetSyncTally.from([
        row(AssetSyncStatus.failed),
        row(AssetSyncStatus.failed, isTerminal: true),
      ]);

      expect(tally.retrying, 1);
      expect(tally.unbackupable, 1);
    });

    test('the buckets partition the library — total equals the row count and '
        'no asset is counted twice', () {
      final rows = [
        row(AssetSyncStatus.uploading),
        row(AssetSyncStatus.queued),
        row(AssetSyncStatus.pending),
        row(AssetSyncStatus.failed),
        row(AssetSyncStatus.failed, isTerminal: true),
        row(AssetSyncStatus.backedUp),
      ];

      final tally = AssetSyncTally.from(rows);

      expect(tally.total, rows.length);
      expect(
        tally.uploading +
            tally.waiting +
            tally.retrying +
            tally.unbackupable +
            tally.backedUp,
        rows.length,
      );
    });

    test('unprotected counts everything without a verified cloud copy', () {
      final tally = AssetSyncTally.from([
        row(AssetSyncStatus.backedUp),
        row(AssetSyncStatus.backedUp),
        row(AssetSyncStatus.pending),
        row(AssetSyncStatus.failed, isTerminal: true),
      ]);

      expect(tally.unprotected, 2);
      expect(tally.backedUp, 2);
    });

    test('an empty library tallies to zero, not to a fabricated total', () {
      final tally = AssetSyncTally.from(const []);

      expect(tally.total, 0);
      expect(tally.unprotected, 0);
    });
  });

  group('watchSyncDetails — live over three tables', () {
    late AppDatabase db;

    setUp(() => db = createTestDatabase());
    tearDown(() => db.close());

    Future<void> seedManifest(final String hash) =>
        db.assetManifestDao.upsert(AssetManifestCompanion(
          contentHash: Value(hash),
          fileSizeBytes: const Value(1024),
          sourceType: const Value('camera'),
          localPath: Value('/videos/$hash.mp4'),
          importedAt: Value(_now),
          copyCount: const Value(0),
        ));

    test('re-emits when a COPY changes, without touching the manifest', () async {
      await seedManifest('h1');

      final stream = db.assetManifestDao.watchSyncDetails();
      expect(
        (await stream.first).single.status,
        AssetSyncStatus.pending,
      );

      await db.assetCopiesDao.upsertCopy(AssetCopiesCompanion.insert(
        id: AssetCopiesDao.copyId('h1', 'gdrive'),
        contentHash: 'h1',
        provider: 'gdrive',
        status: const Value('verified'),
        createdAt: _now,
        updatedAt: _now,
      ));

      expect((await stream.first).single.status, AssetSyncStatus.backedUp);
    });

    test('re-emits when an OPERATION changes', () async {
      await seedManifest('h1');
      final stream = db.assetManifestDao.watchSyncDetails();

      await db.syncOperationsDao.insertOperation(SyncOperationsCompanion.insert(
        id: 'op1',
        contentHash: 'h1',
        providerId: 'gdrive',
        operationType: 'upload',
        status: const Value('in_progress'),
        bytesTransferred: const Value(512),
        createdAt: _now,
      ));

      final detail = (await stream.first).single;
      expect(detail.status, AssetSyncStatus.uploading);
      expect(detail.transferredBytes, 512);
    });

    test(
      'the copies × operations join fans out but yields one row per asset',
      () async {
        await seedManifest('h1');
        for (final provider in ['local', 'gdrive', 'icloud']) {
          await db.assetCopiesDao.upsertCopy(AssetCopiesCompanion.insert(
            id: AssetCopiesDao.copyId('h1', provider),
            contentHash: 'h1',
            provider: provider,
            createdAt: _now,
            updatedAt: _now,
          ));
        }
        for (final id in ['op1', 'op2']) {
          await db.syncOperationsDao
              .insertOperation(SyncOperationsCompanion.insert(
            id: id,
            contentHash: 'h1',
            providerId: 'gdrive',
            operationType: 'upload',
            status: const Value('queued'),
            createdAt: _now,
          ));
        }

        final details = await db.assetManifestDao.watchSyncDetails().first;

        expect(details, hasLength(1));
        expect(details.single.copies, hasLength(3));
        expect(details.single.status, AssetSyncStatus.queued);
      },
    );

    test('tombstoned assets never reach the list', () async {
      await seedManifest('live');
      await seedManifest('dead');
      await db.assetManifestDao.softDelete('dead', 'user');

      final details = await db.assetManifestDao.watchSyncDetails().first;

      expect(details.map((final d) => d.contentHash), ['live']);
    });
  });
}
