import 'dart:io';

import 'package:breakdex/core/data/drift_repositories.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/sync/asset_hash_service.dart';
import 'package:breakdex/core/sync/orphan_restore_service.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late Directory docs;
  late OrphanRestoreService service;
  final hasher = AssetHashService();

  setUp(() {
    db = createTestDatabase();
    docs = Directory.systemTemp.createTempSync('orphan_restore');
    VideoPathResolver.docsPathOverride = docs.path;
    service = OrphanRestoreService(
      db: db,
      moveRepository: DriftMoveRepository(db.movesDao),
    );
  });

  tearDown(() async {
    await db.close();
    docs.deleteSync(recursive: true);
  });

  Future<void> seedManifest(final String hash, {final String? localPath}) =>
      db.assetManifestDao.upsert(AssetManifestCompanion(
        contentHash: Value(hash),
        fileSizeBytes: const Value(1024),
        sourceType: const Value('camera'),
        importedAt: Value(DateTime.now()),
        localPath: Value(localPath),
      ));

  /// Writes [bytes] into `.lost+found` under a canonical `Name - hash8.ext`
  /// name and returns the full content hash — the quarantined-orphan shape
  /// the 2026-07-19 device dump found 22 of.
  Future<String> quarantine(
    final String name,
    final List<int> bytes,
  ) async {
    final staging = File(p.join(docs.path, 'staging.bin'))
      ..writeAsBytesSync(bytes);
    final hash = await hasher.computeHash(staging.path);
    final target = File(p.join(
      docs.path,
      'Moves',
      '.lost+found',
      '$name - ${hash.substring(0, 8)}.mp4',
    ));
    target.parent.createSync(recursive: true);
    staging.renameSync(target.path);
    return hash;
  }

  test('restores a quarantined orphan: verify, re-home, re-own', () async {
    final hash = await quarantine('Air Flare', List.filled(64, 7));
    await seedManifest(hash, localPath: 'Moves/Power moves/gone.mp4');

    // Red half: this is the stranded state the sweep re-queues forever.
    expect(await db.movesDao.getAll(), isEmpty);

    final report = await service.restore();

    expect(report.restored, hasLength(1));
    final moves = await db.movesDao.getAll();
    expect(moves, hasLength(1));
    expect(moves.single.name, 'Air Flare');
    expect(moves.single.category, OrphanRestoreService.recoveredCategory);
    expect(moves.single.contentHash, hash);

    final manifest = await db.assetManifestDao.getByHash(hash);
    final restoredPath = manifest!.localPath!;
    expect(restoredPath, startsWith('Moves/Recovered/'));
    expect(moves.single.videoPath, restoredPath);
    expect(File(p.join(docs.path, restoredPath)).existsSync(), isTrue,
        reason: 'bytes must live where the manifest says');
    expect(manifest.localVerifiedAt, isNotNull);
  });

  test('refuses to adopt on full-hash mismatch (name drift)', () async {
    final hash = await quarantine('Real', List.filled(64, 1));
    // A second file wearing the first hash8 in its name but holding other
    // bytes — the drift shape (0808dba4/514a01df) the full-hash gate is for.
    final impostor = File(p.join(
      docs.path,
      'Moves',
      '.lost+found',
      'Impostor - ${hash.substring(0, 8)}.mp4',
    ))..writeAsBytesSync(List.filled(64, 2));
    // Remove the real file so only the impostor matches the token.
    File(p.join(
      docs.path,
      'Moves',
      '.lost+found',
      'Real - ${hash.substring(0, 8)}.mp4',
    )).deleteSync();
    await seedManifest(hash);

    final report = await service.restore();

    expect(report.restored, isEmpty);
    expect(report.hashMismatch, hasLength(1));
    expect(await db.movesDao.getAll(), isEmpty);
    expect(impostor.existsSync(), isTrue, reason: 'never moved, never adopted');
  });

  test('is idempotent: a second run adopts nothing new', () async {
    final hash = await quarantine('Windmill', List.filled(64, 9));
    await seedManifest(hash);

    expect((await service.restore()).restored, hasLength(1));
    final second = await service.restore();

    expect(second.restored, isEmpty);
    expect(await db.movesDao.getAll(), hasLength(1));
  });

  test('skips owned manifests — heal lanes territory', () async {
    final hash = await quarantine('Owned', List.filled(64, 5));
    await seedManifest(hash, localPath: 'Moves/Power moves/stale.mp4');
    await db.movesDao.insertMove(MovesCompanion.insert(
      id: 'm1',
      name: 'Owned',
      contentHash: Value(hash),
    ));

    final report = await service.restore();

    expect(report.restored, isEmpty);
    expect(await db.movesDao.getAll(), hasLength(1));
  });

  test('reports byte-less orphans as tombstone candidates', () async {
    await seedManifest('deadbeefcafe', localPath: 'Moves/gone.mp4');

    final report = await service.restore();

    expect(report.restored, isEmpty);
    expect(report.bytesNotFound, ['deadbeefcafe']);
    expect(await db.movesDao.getAll(), isEmpty);
  });
}
