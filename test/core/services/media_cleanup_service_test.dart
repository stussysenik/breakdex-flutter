import 'package:drift/drift.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/media_cleanup_service.dart';
import 'package:breakdex/core/services/native_video_album.dart';
import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

class _FakeVideoService extends VideoService {
  final deletedPaths = <String>[];

  @override
  Future<void> deleteVideo(String path) async {
    deletedPaths.add(path);
  }
}

class _FakeVideoAlbum extends NativeVideoAlbum {
  final deletedCalls = <Map<String, String?>>[];

  @override
  Future<void> deleteManagedCopies({
    required String assetTitle,
    String? category,
    String? fileExtension,
    String? assetLocalIdentifier,
  }) async {
    deletedCalls.add({
      'assetTitle': assetTitle,
      'category': category,
      'fileExtension': fileExtension,
      'assetLocalIdentifier': assetLocalIdentifier,
    });
  }
}

void main() {
  group('MediaCleanupService', () {
    late AppDatabase db;
    late _FakeVideoService videoService;
    late _FakeVideoAlbum videoAlbum;
    late MediaCleanupService service;

    setUp(() async {
      db = createTestDatabase();
      videoService = _FakeVideoService();
      videoAlbum = _FakeVideoAlbum();
      VideoPathResolver.docsPathOverride = '/tmp/breakdex-tests';
      service = MediaCleanupService(
        db: db,
        videoService: videoService,
        videoAlbum: videoAlbum,
      );
    });

    tearDown(() async {
      await db.close();
      VideoPathResolver.docsPathOverride = '';
    });

    test(
      'cleanupMoveMedia deletes unreferenced local file and exact album copy',
      () async {
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'move-1',
            name: 'Airflare',
            category: const Value('toprock'),
            videoPath: const Value('Moves/airflare.mp4'),
            managedAlbumAssetId: const Value('asset-123'),
          ),
        );

        final move = await db.movesDao.getById('move-1');

        await service.cleanupMoveMedia(move);

        expect(videoService.deletedPaths, [
          '/tmp/breakdex-tests/Moves/airflare.mp4',
        ]);
        expect(videoAlbum.deletedCalls, [
          {
            'assetTitle': 'Airflare',
            'category': 'toprock',
            'fileExtension': '.mp4',
            'assetLocalIdentifier': 'asset-123',
          },
        ]);
      },
    );

    test(
      'cleanupMoveMedia keeps shared media when another move still references it',
      () async {
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'move-1',
            name: 'Airflare',
            category: const Value('toprock'),
            videoPath: const Value('Moves/shared.mp4'),
            managedAlbumAssetId: const Value('asset-123'),
          ),
        );
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'move-2',
            name: 'Swipe',
            category: const Value('toprock'),
            videoPath: const Value('Moves/shared.mp4'),
          ),
        );

        final move = await db.movesDao.getById('move-1');

        await service.cleanupMoveMedia(move);

        expect(videoService.deletedPaths, isEmpty);
        expect(videoAlbum.deletedCalls, isEmpty);
      },
    );
  });
}
