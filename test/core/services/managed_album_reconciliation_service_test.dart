import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/data/drift_repositories.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/move_archive_reason.dart';
import 'package:breakdex/core/services/managed_album_reconciliation_service.dart';
import 'package:breakdex/core/services/media_cleanup_service.dart';
import 'package:breakdex/core/services/native_video_album.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/video_service.dart';

import '../../helpers/test_database.dart';

class _FakeVideoAlbum extends NativeVideoAlbum {
  PhotoLibraryAccessStatus accessStatus = PhotoLibraryAccessStatus.authorized;
  ManagedAssetReconcileResult reconcileResult =
      ManagedAssetReconcileResult.empty(
        accessStatus: PhotoLibraryAccessStatus.authorized,
      );
  ManagedAssetRestoreResult? restoreResult;
  Future<ManagedAssetRestoreResult?> Function(String assetLocalIdentifier)?
  restoreHandler;
  ManagedAlbumCopy? saveResult;
  final saveCalls = <Map<String, String?>>[];

  @override
  Future<PhotoLibraryAccessStatus> requestReadAccess() async => accessStatus;

  @override
  Future<ManagedAssetReconcileResult> reconcileManagedAssets(
    List<ManagedAssetReference> trackedAssets, {
    String source = 'manual',
  }) async {
    return reconcileResult;
  }

  @override
  Future<ManagedAssetRestoreResult?> restoreManagedAsset(
    String assetLocalIdentifier,
  ) async {
    final handler = restoreHandler;
    if (handler != null) {
      return handler(assetLocalIdentifier);
    }
    return restoreResult;
  }

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

class _FakeVideoService extends VideoService {
  final statusByPath = <String, VideoFileStatus>{};

  @override
  Future<VideoFileStatus> checkVideoFileWithRetry(
    String path, {
    int maxRetries = 2,
  }) async {
    return statusByPath[path] ?? VideoFileStatus.missing;
  }
}

void main() {
  group('ManagedAlbumReconciliationService', () {
    late AppDatabase db;
    late _FakeVideoAlbum videoAlbum;
    late _FakeVideoService videoService;
    late ManagedAlbumReconciliationService service;

    setUp(() async {
      db = createTestDatabase();
      videoAlbum = _FakeVideoAlbum();
      videoService = _FakeVideoService();
      VideoPathResolver.docsPathOverride = '/tmp/breakdex-tests';
      service = ManagedAlbumReconciliationService(
        movesDao: db.movesDao,
        moveRepository: DriftMoveRepository(db.movesDao),
        mediaCleanupService: MediaCleanupService(
          db: db,
          videoService: videoService,
          videoAlbum: videoAlbum,
        ),
        videoAlbum: videoAlbum,
        videoService: videoService,
        now: () => DateTime.utc(2026, 4, 3, 12),
      );
    });

    tearDown(() async {
      await db.close();
      VideoPathResolver.docsPathOverride = '';
    });

    test('archives a move when its managed asset disappears', () async {
      await db.movesDao.insertMove(
        MovesCompanion.insert(
          id: 'move-1',
          name: 'Airflare',
          category: const Value('toprock'),
          videoPath: const Value('Moves/airflare.mp4'),
          managedAlbumAssetId: const Value('asset-123'),
          managedAlbumFilename: const Value('Airflare.mov'),
          managedAlbumName: const Value('Breakdex 04-03-2026'),
        ),
      );
      videoAlbum.reconcileResult = const ManagedAssetReconcileResult(
        accessStatus: PhotoLibraryAccessStatus.authorized,
        events: [
          ManagedAssetReconcileEvent(
            type: ManagedAssetReconcileEventType.assetDeletedFromLibrary,
            assetLocalIdentifier: 'asset-123',
            moveId: 'move-1',
            albumName: 'Breakdex 04-03-2026',
          ),
        ],
      );

      final report = await service.reconcileExternalDeletes();
      final move = await db.movesDao.getById('move-1');

      expect(report.archivedMoves, 1);
      expect(move.archivedAt?.toUtc(), DateTime.utc(2026, 4, 3, 12));
      expect(move.archiveReason, MoveArchiveReason.externalAlbumDelete.dbValue);
      expect(move.managedAlbumAssetId, isNull);
      expect(move.managedAlbumName, isNull);
    });

    test('restores a missing local video from Photos/iCloud', () async {
      await db.movesDao.insertMove(
        MovesCompanion.insert(
          id: 'move-2',
          name: 'Swipe',
          category: const Value('toprock'),
          videoPath: const Value('Moves/missing.mp4'),
          managedAlbumAssetId: const Value('asset-456'),
          managedAlbumName: const Value('Breakdex 04-03-2026'),
        ),
      );
      videoAlbum.restoreResult = const ManagedAssetRestoreResult(
        localPath: '/tmp/breakdex-tests/Moves/restored.mov',
        originalFileName: 'Restored.mov',
      );

      final report = await service.reconcileExternalDeletes();
      final move = await db.movesDao.getById('move-2');

      expect(report.recoveredMoves, 1);
      expect(move.archivedAt, isNull);
      expect(move.videoPath, 'Moves/restored.mov');
      expect(move.originalVideoName, 'Restored.mov');
    });

    test('no startup signal when access is authorized and nothing to report', () async {
      final report = await service.reconcileExternalDeletes();

      expect(report.hasStartupSignal, isFalse);
    });

    test('reports denied Photos access', () async {
      videoAlbum.accessStatus = PhotoLibraryAccessStatus.denied;

      final report = await service.reconcileExternalDeletes();

      expect(report.accessStatus, PhotoLibraryAccessStatus.denied);
      expect(report.hasStartupSignal, isTrue);
    });

    test(
      'restoreArchivedMove recovers a missing local video without duplicating album copies',
      () async {
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'move-3',
            name: 'Halo',
            category: const Value('power'),
            videoPath: const Value('Moves/lost.mp4'),
            managedAlbumAssetId: const Value('asset-789'),
            managedAlbumName: const Value('Breakdex 04-03-2026'),
            archivedAt: Value(DateTime.utc(2026, 4, 3, 9)),
            archiveReason: Value(MoveArchiveReason.missingLocalVideo.dbValue),
          ),
        );
        videoAlbum.restoreResult = const ManagedAssetRestoreResult(
          localPath: '/tmp/breakdex-tests/Moves/halo.mov',
          originalFileName: 'Halo.mov',
        );

        final archivedMove = await db.movesDao.getById('move-3');
        await service.restoreArchivedMove(archivedMove);

        final restoredMove = await db.movesDao.getById('move-3');
        expect(restoredMove.archivedAt, isNull);
        expect(restoredMove.archiveReason, isNull);
        expect(restoredMove.videoPath, 'Moves/halo.mov');
        expect(restoredMove.managedAlbumAssetId, 'asset-789');
        expect(videoAlbum.saveCalls, isEmpty);
      },
    );
  });
}
