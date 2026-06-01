import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/state_machines/move_detail/provider.dart';
import 'package:breakdex/core/state_machines/move_detail/event.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/native_video_album.dart';
import 'package:breakdex/core/sync/video_import_sync_hook.dart';
import 'package:breakdex/core/sync/asset_hash_service.dart';

import '../../../helpers/test_database.dart';

class FakeVideoAlbum implements NativeVideoAlbum {
  ManagedAlbumCopy? savedCopy;
  String? lastVideoPath;

  @override
  Future<ManagedAlbumCopy?> saveToAlbum({
    required final String videoPath,
    required final String albumName,
    final String? assetTitle,
    final String? category,
  }) async {
    lastVideoPath = videoPath;
    savedCopy = ManagedAlbumCopy(
      assetLocalIdentifier: 'fake-asset-id-123',
      filename: 'fake-filename.mp4',
      albumName: albumName,
    );
    return savedCopy;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVideoImportSyncHook implements VideoImportSyncHook {
  @override
  Future<void> onVideoImported({
    required final String localPath,
    required final String moveId,
    final String? precomputedHash,
  }) async {
    // No-op
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late AppDatabase db;
  late String tempDir;
  late FakeVideoAlbum fakeVideoAlbum;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('breakdex_video_test').path;
    VideoPathResolver.docsPathOverride = tempDir;
    db = createTestDatabase();
    fakeVideoAlbum = FakeVideoAlbum();

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        nativeVideoAlbumProvider.overrideWithValue(fakeVideoAlbum),
        videoImportSyncHookProvider.overrideWithValue(
          FakeVideoImportSyncHook(),
        ),
      ],
    );
  });

  tearDown(() {
    try {
      Directory(tempDir).deleteSync(recursive: true);
    } catch (_) {}
    db.close();
    container.dispose();
  });

  test(
    'Save video updates DB with album fields and calls saveToAlbum',
    () async {
      final move = Move(
        id: 'm1',
        name: 'Windmill',
        category: 'Power',
        count: 0,
        learningState: 'new',
        createdAt: DateTime.now(),
      );
      await db
          .into(db.moves)
          .insert(
            MovesCompanion.insert(
              id: move.id,
              name: move.name,
              category: Value(move.category),
              count: Value(move.count),
              learningState: Value(move.learningState),
            ),
          );

      // Create a dummy video file in temp directory to be edited/saved
      final sourceVideoDir = Directory(p.join(tempDir, 'Edits'))
        ..createSync(recursive: true);
      final sourceVideoFile = File(p.join(sourceVideoDir.path, 'source.mp4'))
        ..writeAsStringSync('dummy-video-content');

      final notifier = container.read(moveDetailProvider.notifier);
      notifier.init(move);

      // Trigger video save/edit action
      notifier.send(VideoEdited(sourceVideoFile.path));

      // Wait for the async side effects to execute
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify: DB contains updated video path and content hash
      final dbMove = await (db.select(
        db.moves,
      )..where((final t) => t.id.equals('m1'))).getSingle();
      expect(dbMove.videoPath, isNotNull);
      expect(dbMove.videoPath, contains('Moves/Power/Windmill/'));
      expect(dbMove.contentHash, isNotNull);
      expect(dbMove.originalVideoName, 'source.mp4');
      expect(dbMove.managedAlbumAssetId, isNull);
      expect(dbMove.managedAlbumFilename, isNull);
      expect(dbMove.managedAlbumName, isNull);
    },
  );

  test(
    'Picked OPTW videos replace move video with hash-addressed exports',
    () async {
      const sourcePaths = [
        '/Users/s3nik/Downloads/OPTW 05-12-2026 VERTICAL.mp4',
        '/Users/s3nik/Downloads/OPTW 05-19-2026 VERTICAL.mp4',
      ];
      final missing = sourcePaths
          .where((final path) => !File(path).existsSync())
          .toList();
      if (missing.isNotEmpty) {
        markTestSkipped(
          'Missing local OPTW fixture videos: ${missing.join(', ')}',
        );
        return;
      }

      final move = Move(
        id: 'm-optw',
        name: 'Airflare',
        category: 'Power',
        count: 0,
        learningState: 'NEW',
        createdAt: DateTime.now(),
      );
      await db
          .into(db.moves)
          .insert(
            MovesCompanion.insert(
              id: move.id,
              name: move.name,
              category: Value(move.category),
              count: Value(move.count),
              learningState: Value(move.learningState),
            ),
          );

      final notifier = container.read(moveDetailProvider.notifier)..init(move);
      final hashService = AssetHashService();
      String? previousPath;
      final importsDir = Directory(p.join(tempDir, 'Imports'))
        ..createSync(recursive: true);

      Future<Move> waitForHash(final String expectedHash) async {
        final deadline = DateTime.now().add(const Duration(seconds: 15));
        while (DateTime.now().isBefore(deadline)) {
          final dbMove = await (db.select(
            db.moves,
          )..where((final t) => t.id.equals('m-optw'))).getSingle();
          if (dbMove.contentHash == expectedHash) return dbMove;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        return (db.select(
          db.moves,
        )..where((final t) => t.id.equals('m-optw'))).getSingle();
      }

      for (final sourcePath in sourcePaths) {
        final sourceFile = File(sourcePath);
        final copiedSource = await sourceFile.copy(
          p.join(importsDir.path, p.basename(sourcePath)),
        );
        final expectedHash = await hashService.computeHash(copiedSource.path);

        notifier.send(VideoPicked(copiedSource.path, p.basename(sourcePath)));

        final dbMove = await waitForHash(expectedHash);
        final storedPath = dbMove.videoPath;

        expect(storedPath, isNotNull);
        expect(storedPath, 'Moves/Power/Airflare/$expectedHash.mp4');
        expect(dbMove.contentHash, expectedHash);
        expect(dbMove.originalVideoName, p.basename(sourcePath));
        expect(
          await File(VideoPathResolver.toAbsolute(storedPath!)).exists(),
          isTrue,
        );
        expect(await sourceFile.exists(), isTrue);
        if (previousPath != null) {
          expect(storedPath, isNot(previousPath));
        }
        previousPath = storedPath;
      }
    },
  );
}
