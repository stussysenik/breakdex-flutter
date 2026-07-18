/// Regression: renames/category moves physically relocate the video file and
/// update the owning move row — `asset_manifest.localPath` must move with it,
/// or the backup engine uploads from an abandoned path (surfaced on device as
/// every Drive op failing with "negative content length").
library;

import 'dart:io';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/storage_orchestrator.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late StorageOrchestrator orchestrator;

  const hash = 'abc12345feedbeef';
  const oldRelative = 'Moves/Power/Old - abc12345.mp4';

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('breakdex_orch_test_');
    VideoPathResolver.docsPathOverride = tempDir.path;
    db = createTestDatabase();
    orchestrator = StorageOrchestrator(db: db, movesDao: db.movesDao);

    final file = File('${tempDir.path}/$oldRelative');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(List.filled(64, 0));

    await db.movesDao.insertMove(const MovesCompanion(
      id: Value('move-1'),
      name: Value('Old'),
      category: Value('Power'),
      contentHash: Value(hash),
      videoPath: Value(oldRelative),
    ));
    await db.assetManifestDao.upsert(AssetManifestCompanion(
      contentHash: const Value(hash),
      fileSizeBytes: const Value(64),
      sourceType: const Value('camera'),
      importedAt: Value(DateTime.now()),
      localPath: const Value(oldRelative),
    ));
  });

  tearDown(() async {
    await db.close();
    try {
      tempDir.deleteSync(recursive: true);
    } on Object catch (_) {}
  });

  test('manifest localPath follows a move rename', () async {
    final move = await db.movesDao.getById('move-1');

    await orchestrator.updateMoveName(move, 'New');

    final renamed = await db.movesDao.getById('move-1');
    final manifest = await db.assetManifestDao.getByHash(hash);
    expect(renamed.videoPath, isNot(oldRelative));
    expect(manifest!.localPath, renamed.videoPath,
        reason: 'the backup engine uploads from the manifest pointer');
    expect(
      File(VideoPathResolver.toAbsolute(manifest.localPath!)).existsSync(),
      isTrue,
    );
  });

  test('manifest localPath follows a category change', () async {
    final move = await db.movesDao.getById('move-1');

    await orchestrator.updateMoveCategory(move, 'Footwork');

    final moved = await db.movesDao.getById('move-1');
    final manifest = await db.assetManifestDao.getByHash(hash);
    expect(manifest!.localPath, moved.videoPath);
    expect(
      File(VideoPathResolver.toAbsolute(manifest.localPath!)).existsSync(),
      isTrue,
    );
  });
}
