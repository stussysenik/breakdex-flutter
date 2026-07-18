import 'dart:io';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/storage_janitor.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../helpers/test_database.dart';

/// Design D11 task 4.9: the janitor consults the manifest registry before
/// quarantining. Pre-fix, ownership truth was entities only — a manifest-known
/// file at a stale path was "identity unknown" and moved to `.lost+found`,
/// which is the exact mechanism that stranded the 22 orphans of 2026-07-19.
void main() {
  late AppDatabase db;
  late Directory docs;
  late StorageJanitor janitor;

  setUp(() {
    db = createTestDatabase();
    docs = Directory.systemTemp.createTempSync('janitor');
    VideoPathResolver.docsPathOverride = docs.path;
    janitor = StorageJanitor(db: db);
  });

  tearDown(() async {
    await db.close();
    docs.deleteSync(recursive: true);
  });

  File placeVideo(final String relative) {
    final file = File(p.join(docs.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(List.filled(16, 1));
    return file;
  }

  Future<void> seedManifest(final String hash) =>
      db.assetManifestDao.upsert(AssetManifestCompanion(
        contentHash: Value(hash),
        fileSizeBytes: const Value(16),
        sourceType: const Value('camera'),
        importedAt: Value(DateTime.now()),
        localPath: const Value('Moves/Old/gone.mp4'),
      ));

  test('a manifest-known file at a stale path is never quarantined', () async {
    const hash = 'aabbccdd00112233aabbccdd00112233'
        'aabbccdd00112233aabbccdd00112233';
    await seedManifest(hash);
    // No move/combo references this path — pre-fix, that alone meant orphan.
    final file = placeVideo('Moves/Power moves/Air Flare - aabbccdd.mp4');

    await janitor.reconcile();

    expect(file.existsSync(), isTrue,
        reason: 'manifest-known bytes must stay for the heal lane');
    expect(
      File(p.join(docs.path, 'Moves', '.lost+found',
              'Air Flare - aabbccdd.mp4'))
          .existsSync(),
      isFalse,
    );
  });

  test('a genuinely unknown file still quarantines', () async {
    final file = placeVideo('Moves/Power moves/IMG_4021.mov');

    await janitor.reconcile();

    expect(file.existsSync(), isFalse);
    expect(
      File(p.join(docs.path, 'Moves', '.lost+found', 'IMG_4021.mov'))
          .existsSync(),
      isTrue,
    );
  });

  test('a hash-named file whose manifest is tombstoned quarantines', () async {
    const hash = 'ffeeddcc00112233ffeeddcc00112233'
        'ffeeddcc00112233ffeeddcc00112233';
    await db.assetManifestDao.upsert(AssetManifestCompanion(
      contentHash: const Value(hash),
      fileSizeBytes: const Value(16),
      sourceType: const Value('camera'),
      importedAt: Value(DateTime.now()),
      deletedAt: Value(DateTime.now()),
    ));
    final file = placeVideo('Moves/X/Old clip - ffeeddcc.mp4');

    await janitor.reconcile();

    expect(file.existsSync(), isFalse,
        reason: 'a tombstoned manifest is not a live claim on the bytes');
  });

  test('an entity-referenced file is untouched, as before', () async {
    final file = placeVideo('Moves/Power moves/Owned - 12345678.mp4');
    await db.movesDao.insertMove(MovesCompanion.insert(
      id: 'm1',
      name: 'Owned',
      videoPath: const Value('Moves/Power moves/Owned - 12345678.mp4'),
    ));

    await janitor.reconcile();

    expect(file.existsSync(), isTrue);
  });
}
