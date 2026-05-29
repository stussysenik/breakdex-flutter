import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/state_machines/move_detail/provider.dart';
import 'package:breakdex/core/state_machines/move_detail/event.dart';
import 'package:breakdex/core/state_machines/move_detail/state.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/native_video_album.dart';
import 'package:breakdex/core/sync/video_import_sync_hook.dart';

import '../../../helpers/test_database.dart';

class FakeVideoAlbum implements NativeVideoAlbum {
  ManagedAlbumCopy? savedCopy;
  String? lastVideoPath;

  @override
  Future<ManagedAlbumCopy?> saveToAlbum({
    required String videoPath,
    required String albumName,
    String? assetTitle,
    String? category,
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVideoImportSyncHook implements VideoImportSyncHook {
  @override
  Future<void> onVideoImported({
    required String localPath,
    required String moveId,
    String? precomputedHash,
  }) async {
    // No-op
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
        videoImportSyncHookProvider.overrideWithValue(FakeVideoImportSyncHook()),
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

  test('Save video updates DB with album fields and calls saveToAlbum', () async {
    final move = Move(
      id: 'm1',
      name: 'Windmill',
      category: 'Power',
      count: 0,
      learningState: 'new',
      createdAt: DateTime.now(),
    );
    await db.into(db.moves).insert(MovesCompanion.insert(
      id: move.id,
      name: move.name,
      category: Value(move.category),
      count: Value(move.count),
      learningState: Value(move.learningState),
    ));

    // Create a dummy video file in temp directory to be edited/saved
    final sourceVideoDir = Directory(p.join(tempDir, 'Edits'))..createSync(recursive: true);
    final sourceVideoFile = File(p.join(sourceVideoDir.path, 'source.mp4'))..writeAsStringSync('dummy-video-content');

    final notifier = container.read(moveDetailProvider.notifier);
    notifier.init(move);

    // Trigger video save/edit action
    notifier.send(VideoEdited(sourceVideoFile.path));

    // Wait for the async side effects to execute
    await Future.delayed(const Duration(milliseconds: 200));

    // Verify: saveToAlbum was called with correct parameters
    expect(fakeVideoAlbum.lastVideoPath, isNotNull);
    expect(fakeVideoAlbum.savedCopy, isNotNull);

    // Verify: DB contains updated album metadata
    final dbMove = await (db.select(db.moves)..where((t) => t.id.equals('m1'))).getSingle();
    expect(dbMove.managedAlbumAssetId, 'fake-asset-id-123');
    expect(dbMove.managedAlbumFilename, 'fake-filename.mp4');
    expect(dbMove.managedAlbumName, isNotNull);
  });
}
