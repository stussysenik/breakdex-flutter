import 'dart:io';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:breakdex/core/data/drift_repositories.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/move_creation.dart';
import 'package:breakdex/core/services/move_creation_service.dart';
import 'package:breakdex/core/services/native_video_album.dart';
import 'package:breakdex/core/services/reviewable_naming_service.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/sync/asset_hash_service.dart';

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

class _FakeHashService extends AssetHashService {
  @override
  Future<String> computeHash(String filePath) async => 'hash-123';
}

void main() {
  group('MoveCreationService', () {
    late AppDatabase db;
    late _FakeVideoAlbum videoAlbum;
    late List<({String localPath, String moveId, String? precomputedHash})> syncCalls;
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
        hashService: _FakeHashService(),
        fsrsCardsDao: db.fsrsCardsDao,
        onVideoImported: ({required localPath, required moveId, precomputedHash}) async {
          syncCalls.add((localPath: localPath, moveId: moveId, precomputedHash: precomputedHash));
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

        final fsrsCard = await db.fsrsCardsDao.getByEntityId('move-1');
        expect(fsrsCard, isNot(isNull));
        expect(fsrsCard!.fsrsState, 0);
        expect(fsrsCard.entityType, 'move');
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

        final localPath = p.join(VideoPathResolver.toAbsolute(''), 'swipe.mov');
        await File(localPath).parent.create(recursive: true);
        await File(localPath).writeAsString('dummy video');

        final result = await service.createMove(
          CreateMoveRequest(
            name: 'Swipe',
            category: 'Footwork',
            localVideoPath: localPath,
            originalVideoName: 'IMG_0001.MOV',
          ),
        );

        final move = await db.movesDao.getById('hash-123');

        expect(result.hasVideo, isTrue);
        expect(result.videoPath, 'Moves/Footwork/Swipe/video.mov');
        expect(move.videoPath, 'Moves/Footwork/Swipe/video.mov');
        expect(move.originalVideoName, 'IMG_0001.MOV');
        expect(move.notes, isNull);
        expect(move.managedAlbumAssetId, isNull);
        expect(move.managedAlbumFilename, isNull);
        expect(move.managedAlbumName, isNull);
        expect(
          syncCalls.single.localPath,
          VideoPathResolver.toAbsolute('Moves/Footwork/Swipe/video.mov'),
        );
        expect(syncCalls.single.moveId, 'hash-123');

        final fsrsCard = await db.fsrsCardsDao.getByEntityId('hash-123');
        expect(fsrsCard, isNot(isNull));
        expect(fsrsCard!.fsrsState, 0);
        expect(fsrsCard.entityType, 'move');
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

  });
}
