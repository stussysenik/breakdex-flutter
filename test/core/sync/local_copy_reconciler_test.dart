import 'dart:io';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/asset_copies_dao.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/sync/local_copy_reconciler.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

Future<void> _seedManifest(
  final AppDatabase db, {
  required final String hash,
  final String? localPath,
  final DateTime? deletedAt,
}) async {
  await db.assetManifestDao.upsert(AssetManifestCompanion(
    contentHash: Value(hash),
    fileSizeBytes: const Value(1024),
    sourceType: const Value('camera'),
    importedAt: Value(DateTime.now()),
    localPath: Value(localPath),
    deletedAt: Value(deletedAt),
    copyCount: const Value(0),
  ));
}

Future<void> _seedCopy(
  final AppDatabase db, {
  required final String hash,
  required final String provider,
}) async {
  await db.assetCopiesDao.upsertCopy(AssetCopiesCompanion.insert(
    id: AssetCopiesDao.copyId(hash, provider),
    contentHash: hash,
    provider: provider,
    status: const Value('verified'),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late LocalCopyReconciler reconciler;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('breakdex_reconcile_');
    VideoPathResolver.docsPathOverride = tempDir.path;
    db = createTestDatabase();
    reconciler = LocalCopyReconciler(
      manifestDao: db.assetManifestDao,
      copiesDao: db.assetCopiesDao,
    );
  });

  tearDown(() async {
    await db.close();
    try {
      tempDir.deleteSync(recursive: true);
    } on Object catch (_) {}
  });

  Future<void> writeFile(final String relative) async {
    final file = File('${tempDir.path}/$relative');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(List.filled(32, 0));
  }

  group('LocalCopyReconciler', () {
    /// The 4.3 defect: the cloud upload succeeded, so a `gdrive` row exists and
    /// the bytes are on disk — but with no `local` row the asset reads one copy
    /// short and stays underprotected forever.
    test('inserts a local copy for an on-disk asset that lacks one', () async {
      await writeFile('Moves/Power/windmill.mp4');
      await _seedManifest(
        db,
        hash: 'onDisk',
        localPath: 'Moves/Power/windmill.mp4',
      );
      await _seedCopy(db, hash: 'onDisk', provider: 'gdrive');

      // The defect, before the fix: cloud upload succeeded and the bytes are
      // on disk, yet the asset reads one copy short of the two-copy minimum.
      final before = await db.assetManifestDao.getByHash('onDisk');
      expect(before!.copyCount, lessThan(2));
      expect(
        await db.assetManifestDao.watchUnderprotectedCount().first,
        1,
      );

      expect(await reconciler.reconcile(), 1);
      expect(await db.assetManifestDao.watchUnderprotectedCount().first, 0);

      final copies = await db.assetCopiesDao.getByHash('onDisk');
      expect(copies.map((final c) => c.provider).toSet(), {'local', 'gdrive'});

      final manifest = await db.assetManifestDao.getByHash('onDisk');
      expect(manifest!.copyCount, 2);
    });

    test('inserts nothing when the file is genuinely gone', () async {
      await _seedManifest(
        db,
        hash: 'missing',
        localPath: 'Moves/Power/vanished.mp4',
      );
      await _seedCopy(db, hash: 'missing', provider: 'gdrive');

      expect(await reconciler.reconcile(), 0);

      final copies = await db.assetCopiesDao.getByHash('missing');
      expect(copies.map((final c) => c.provider).toList(), ['gdrive']);

      // A missing video must never read as protected.
      final manifest = await db.assetManifestDao.getByHash('missing');
      expect(manifest!.copyCount, lessThan(2));
    });

    test('is idempotent — a second run inserts nothing', () async {
      await writeFile('Moves/Power/again.mp4');
      await _seedManifest(
        db,
        hash: 'again',
        localPath: 'Moves/Power/again.mp4',
      );

      expect(await reconciler.reconcile(), 1);
      expect(await reconciler.reconcile(), 0);
      expect((await db.assetCopiesDao.getByHash('again')).length, 1);
    });

    test('skips tombstoned assets even when the file lingers', () async {
      await writeFile('Moves/Power/deleted.mp4');
      await _seedManifest(
        db,
        hash: 'tombstoned',
        localPath: 'Moves/Power/deleted.mp4',
        deletedAt: DateTime.now(),
      );

      expect(await reconciler.reconcile(), 0);
      expect((await db.assetCopiesDao.getByHash('tombstoned')), isEmpty);
    });

    test('skips assets that already have a local row', () async {
      await writeFile('Moves/Power/healthy.mp4');
      await _seedManifest(
        db,
        hash: 'healthy',
        localPath: 'Moves/Power/healthy.mp4',
      );
      await _seedCopy(db, hash: 'healthy', provider: 'local');

      expect(await reconciler.reconcile(), 0);
    });

    test('findMissingLocalCopies reports the gap without writing', () async {
      await writeFile('Moves/Power/a.mp4');
      await _seedManifest(db, hash: 'a', localPath: 'Moves/Power/a.mp4');
      await _seedManifest(db, hash: 'b', localPath: 'Moves/Power/gone.mp4');

      expect(await reconciler.findMissingLocalCopies(), ['a']);
      expect((await db.assetCopiesDao.getByHash('a')), isEmpty);
    });
  });
}
