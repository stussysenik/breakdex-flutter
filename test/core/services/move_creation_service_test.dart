import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/data/drift_repositories.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/move_creation.dart';
import 'package:breakdex/core/services/move_creation_service.dart';
import 'package:breakdex/core/services/native_video_album.dart';
import 'package:breakdex/core/services/reviewable_naming_service.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';

import '../../helpers/test_database.dart';

class _FakeVideoAlbum extends NativeVideoAlbum {
  ManagedAlbumCopy? saveResult;
  final saveCalls = <Map<String, String?>>[];

  @override
  Future<ManagedAlbumCopy?> saveToAlbum({
    required String videoPath,
    required String albumName,
    String? assetTitle,
    String? category,
  }) async {
    saveCalls.add({
      'videoPath': videoPath,
      'albumName': albumName,
      'assetTitle': assetTitle,
      'category': category,
    });
    return saveResult;
  }
}

void main() {
  group('MoveCreationService', () {
    late AppDatabase db;
    late _FakeVideoAlbum videoAlbum;
    late List<({String localPath, String moveId})> syncCalls;
    late MoveCreationService service;

    setUp(() {
      db = createTestDatabase();
      videoAlbum = _FakeVideoAlbum();
      syncCalls = [];
      VideoPathResolver.docsPathOverride = '/tmp/breakdex-tests';

      service = MoveCreationService(
        moveRepository: DriftMoveRepository(db.movesDao),
        namingService: ReviewableNamingService(
          movesDao: db.movesDao,
          combosDao: db.combosDao,
        ),
        videoAlbum: videoAlbum,
        onVideoImported: ({required localPath, required moveId}) async {
          syncCalls.add((localPath: localPath, moveId: moveId));
        },
        idGenerator: () => 'move-1',
      );
    });

    tearDown(() async {
      await db.close();
      VideoPathResolver.docsPathOverride = '';
    });

    test(
      'creates a move with category and name only, leaving notes unset',
      () async {
        final result = await service.createMove(
          const CreateMoveRequest(
            name: '  Air   flare  ',
            category: 'Power Moves',
          ),
        );

        final move = await db.movesDao.getById('move-1');

        expect(result.moveId, 'move-1');
        expect(result.name, 'Air flare');
        expect(result.category, 'Power Moves');
        expect(result.hasVideo, isFalse);
        expect(move.name, 'Air flare');
        expect(move.category, 'Power Moves');
        expect(move.videoPath, isNull);
        expect(move.originalVideoName, isNull);
        expect(move.notes, isNull);
        expect(videoAlbum.saveCalls, isEmpty);
        expect(syncCalls, isEmpty);
      },
    );

    test(
      'stores optional video metadata and triggers managed copy + sync',
      () async {
        videoAlbum.saveResult = const ManagedAlbumCopy(
          assetLocalIdentifier: 'asset-1',
          filename: 'Swipe-footwork.mov',
          albumName: 'Breakdex 04-30-2026',
        );

        final result = await service.createMove(
          const CreateMoveRequest(
            name: 'Swipe',
            category: 'Footwork',
            localVideoPath: '/tmp/breakdex-tests/Moves/swipe.mov',
            originalVideoName: 'IMG_0001.MOV',
          ),
        );

        final move = await db.movesDao.getById('move-1');

        expect(result.hasVideo, isTrue);
        expect(result.videoPath, 'Moves/swipe.mov');
        expect(move.videoPath, 'Moves/swipe.mov');
        expect(move.originalVideoName, 'IMG_0001.MOV');
        expect(move.notes, isNull);
        expect(move.managedAlbumAssetId, 'asset-1');
        expect(move.managedAlbumFilename, 'Swipe-footwork.mov');
        expect(move.managedAlbumName, 'Breakdex 04-30-2026');
        expect(videoAlbum.saveCalls.single['assetTitle'], 'Swipe');
        expect(videoAlbum.saveCalls.single['category'], 'Footwork');
        expect(
          syncCalls.single.localPath,
          '/tmp/breakdex-tests/Moves/swipe.mov',
        );
        expect(syncCalls.single.moveId, 'move-1');
      },
    );

    test('rejects duplicate reviewable names', () async {
      await db.movesDao.insertMove(
        MovesCompanion.insert(
          id: 'existing-move',
          name: 'Windmill',
          category: const Value('Power Moves'),
        ),
      );

      expect(
        () => service.createMove(
          const CreateMoveRequest(name: 'Windmill', category: 'Power Moves'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'creates a recovered move without writing a duplicate managed album copy',
      () async {
        final result = await service.createRecoveredMove(
          const CreateRecoveredMoveRequest(
            preferredName: 'Windmill',
            category: 'Power',
            localVideoPath: '/tmp/breakdex-tests/Moves/windmill.mov',
            originalVideoName: 'Windmill - Power.mov',
            managedAlbumAssetId: 'asset-recovered-1',
            managedAlbumFilename: 'Windmill - Power.mov',
            managedAlbumName: 'Breakdex 04-30-2026',
          ),
        );

        final move = await db.movesDao.getById('move-1');

        expect(result.name, 'Windmill');
        expect(result.category, 'Power');
        expect(move.videoPath, 'Moves/windmill.mov');
        expect(move.originalVideoName, 'Windmill - Power.mov');
        expect(move.managedAlbumAssetId, 'asset-recovered-1');
        expect(move.managedAlbumFilename, 'Windmill - Power.mov');
        expect(move.managedAlbumName, 'Breakdex 04-30-2026');
        expect(videoAlbum.saveCalls, isEmpty);
        expect(
          syncCalls.single.localPath,
          '/tmp/breakdex-tests/Moves/windmill.mov',
        );
      },
    );

    test(
      'recovered moves get a unique name when the base name already exists',
      () async {
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'existing-move',
            name: 'Windmill',
            category: const Value('Power Moves'),
          ),
        );

        final result = await service.createRecoveredMove(
          const CreateRecoveredMoveRequest(
            preferredName: 'Windmill',
            category: 'Power',
            localVideoPath: '/tmp/breakdex-tests/Moves/windmill.mov',
            originalVideoName: 'Windmill - Power.mov',
            managedAlbumAssetId: 'asset-recovered-2',
            managedAlbumFilename: 'Windmill - Power.mov',
            managedAlbumName: 'Breakdex 04-30-2026',
          ),
        );

        expect(result.name, 'Windmill (Recovered)');
      },
    );
  });
}
