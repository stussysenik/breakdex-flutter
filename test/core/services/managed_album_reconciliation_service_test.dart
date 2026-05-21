import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/data/drift_repositories.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/move_archive_reason.dart';
import 'package:breakdex/core/services/managed_album_reconciliation_service.dart';
import 'package:breakdex/core/services/media_cleanup_service.dart';
import 'package:breakdex/core/services/move_creation_service.dart';
import 'package:breakdex/core/services/native_video_album.dart';
import 'package:breakdex/core/services/reviewable_naming_service.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/video_service.dart';

import '../../helpers/test_database.dart';

class _FakeVideoAlbum extends NativeVideoAlbum {
  PhotoLibraryAccessStatus accessStatus = PhotoLibraryAccessStatus.authorized;
  ManagedAssetReconcileResult reconcileResult =
      ManagedAssetReconcileResult.empty(
        accessStatus: PhotoLibraryAccessStatus.authorized,
      );
  RecoverableManagedAssetDiscoveryResult discoveryResult =
      RecoverableManagedAssetDiscoveryResult.empty(
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
  Future<RecoverableManagedAssetDiscoveryResult>
  discoverRecoverableManagedAssets({
    List<String> albumPatterns = NativeVideoAlbum.historicalAlbumPatterns,
  }) async {
    return discoveryResult;
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
      final moveCreationService = MoveCreationService(
        moveRepository: DriftMoveRepository(db.movesDao),
        namingService: ReviewableNamingService(
          movesDao: db.movesDao,
          combosDao: db.combosDao,
        ),
        videoAlbum: videoAlbum,
        onVideoImported: ({required localPath, required moveId}) async {},
      );
      service = ManagedAlbumReconciliationService(
        movesDao: db.movesDao,
        moveRepository: DriftMoveRepository(db.movesDao),
        moveCreationService: moveCreationService,
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

    test('re-recovers a missing local video from Photos/iCloud', () async {
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
        localPath: '/tmp/breakdex-tests/Moves/recovered.mov',
        originalFileName: 'Recovered.mov',
      );

      final report = await service.reconcileExternalDeletes();
      final move = await db.movesDao.getById('move-2');

      expect(report.recoveredMoves, 1);
      expect(move.archivedAt, isNull);
      expect(move.videoPath, 'Moves/recovered.mov');
      expect(move.originalVideoName, 'Recovered.mov');
    });

    test(
      'relinks a historical album copy by semantic filename when the DB lost managed metadata',
      () async {
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'move-legacy-1',
            name: 'Airflare',
            category: const Value('toprock'),
            videoPath: const Value('Moves/airflare.mp4'),
          ),
        );
        videoService.statusByPath['/tmp/breakdex-tests/Moves/airflare.mp4'] =
            VideoFileStatus.ready;
        videoAlbum.discoveryResult =
            const RecoverableManagedAssetDiscoveryResult(
              accessStatus: PhotoLibraryAccessStatus.authorized,
              assets: [
                RecoverableManagedAsset(
                  assetLocalIdentifier: 'legacy-asset-1',
                  filename: 'Airflare - toprock.mov',
                  albumName: 'Bboying Practice',
                ),
              ],
            );

        final report = await service.reconcileExternalDeletes();
        final move = await db.movesDao.getById('move-legacy-1');

        expect(report.trackedMoves, 0);
        expect(report.recoveredMoves, 1);
        expect(report.historicalAssetsDiscovered, 1);
        expect(report.historicalAssetsUntracked, 1);
        expect(report.historicalAssetsRecovered, 1);
        expect(report.historicalAssetsStillPending, 0);
        expect(move.managedAlbumAssetId, 'legacy-asset-1');
        expect(move.managedAlbumFilename, 'Airflare - toprock.mov');
        expect(move.managedAlbumName, 'Bboying Practice');
      },
    );

    test(
      'restores a historical album copy when only semantic/original filename matching remains',
      () async {
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'move-legacy-2',
            name: 'Halo',
            category: const Value('power'),
            originalVideoName: const Value('legacy-halo.mov'),
          ),
        );
        videoAlbum.discoveryResult =
            const RecoverableManagedAssetDiscoveryResult(
              accessStatus: PhotoLibraryAccessStatus.authorized,
              assets: [
                RecoverableManagedAsset(
                  assetLocalIdentifier: 'legacy-asset-2',
                  filename: 'legacy-halo.mov',
                  albumName: 'Breaking Archive',
                ),
              ],
            );
        videoAlbum.restoreResult = const ManagedAssetRestoreResult(
          localPath: '/tmp/breakdex-tests/Moves/legacy-halo.mov',
          originalFileName: 'legacy-halo.mov',
        );

        final report = await service.reconcileExternalDeletes();
        final move = await db.movesDao.getById('move-legacy-2');

        expect(report.trackedMoves, 0);
        expect(report.recoveredMoves, 1);
        expect(report.historicalAssetsDiscovered, 1);
        expect(report.historicalAssetsRecovered, 1);
        expect(move.videoPath, 'Moves/legacy-halo.mov');
        expect(move.managedAlbumAssetId, 'legacy-asset-2');
        expect(move.managedAlbumName, 'Breaking Archive');
      },
    );

    test(
      'prefers the strongest filename match when broad album discovery returns multiple videos',
      () async {
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'move-legacy-3',
            name: 'Halo',
            category: const Value('power'),
            originalVideoName: const Value('legacy-halo.mov'),
          ),
        );
        videoAlbum.discoveryResult =
            const RecoverableManagedAssetDiscoveryResult(
              accessStatus: PhotoLibraryAccessStatus.authorized,
              assets: [
                RecoverableManagedAsset(
                  assetLocalIdentifier: 'legacy-asset-noise',
                  filename: 'Footwork - drill.mov',
                  albumName: 'Break Dex Sessions',
                ),
                RecoverableManagedAsset(
                  assetLocalIdentifier: 'legacy-asset-best',
                  filename: 'legacy-halo.mov',
                  albumName: 'Break Dex Sessions',
                ),
              ],
            );
        videoAlbum.restoreResult = const ManagedAssetRestoreResult(
          localPath: '/tmp/breakdex-tests/Moves/legacy-halo.mov',
          originalFileName: 'legacy-halo.mov',
        );

        final report = await service.reconcileExternalDeletes();
        final move = await db.movesDao.getById('move-legacy-3');
        final moves = await db.movesDao.getAll();

        expect(report.recoveredMoves, 2);
        expect(report.historicalAssetsDiscovered, 2);
        expect(report.historicalAssetsUntracked, 2);
        expect(report.historicalAssetsRecovered, 2);
        expect(move.managedAlbumAssetId, 'legacy-asset-best');
        expect(moves, hasLength(2));
      },
    );

    test('imports an unmatched historical asset as a new move row', () async {
      videoAlbum.discoveryResult = const RecoverableManagedAssetDiscoveryResult(
        accessStatus: PhotoLibraryAccessStatus.authorized,
        assets: [
          RecoverableManagedAsset(
            assetLocalIdentifier: 'legacy-asset-import',
            filename: 'Windmill - Power.mov',
            albumName: 'Breakdex 04-03-2026',
          ),
        ],
      );
      videoAlbum.restoreResult = const ManagedAssetRestoreResult(
        localPath: '/tmp/breakdex-tests/Moves/windmill.mov',
        originalFileName: 'Windmill - Power.mov',
      );

      final report = await service.reconcileExternalDeletes();
      final moves = await db.movesDao.getAll();

      expect(report.trackedMoves, 0);
      expect(report.recoveredMoves, 1);
      expect(report.historicalAssetsDiscovered, 1);
      expect(report.historicalAssetsUntracked, 1);
      expect(report.historicalAssetsRecovered, 1);
      expect(
        report.snackBarMessage,
        'Recovered 1 historical album video from Photos.',
      );
      expect(moves, hasLength(1));
      expect(moves.single.name, 'Windmill');
      expect(moves.single.category, 'Power');
      expect(moves.single.videoPath, 'Moves/windmill.mov');
      expect(moves.single.originalVideoName, 'Windmill - Power.mov');
      expect(moves.single.managedAlbumAssetId, 'legacy-asset-import');
    });

    test(
      'reports partial historical recovery when some restores fail',
      () async {
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'move-legacy-4',
            name: 'Halo',
            category: const Value('power'),
            originalVideoName: const Value('legacy-halo.mov'),
          ),
        );
        videoAlbum.discoveryResult =
            const RecoverableManagedAssetDiscoveryResult(
              accessStatus: PhotoLibraryAccessStatus.authorized,
              assets: [
                RecoverableManagedAsset(
                  assetLocalIdentifier: 'legacy-asset-match',
                  filename: 'legacy-halo.mov',
                  albumName: 'Breakdex 04-03-2026',
                ),
                RecoverableManagedAsset(
                  assetLocalIdentifier: 'legacy-asset-fail',
                  filename: 'Windmill - Power.mov',
                  albumName: 'Breakdex 04-03-2026',
                ),
              ],
            );
        videoAlbum.restoreHandler = (assetLocalIdentifier) async {
          if (assetLocalIdentifier == 'legacy-asset-fail') {
            throw StateError('iCloud download failed');
          }
          return const ManagedAssetRestoreResult(
            localPath: '/tmp/breakdex-tests/Moves/legacy-halo.mov',
            originalFileName: 'legacy-halo.mov',
          );
        };

        final report = await service.reconcileExternalDeletes();
        final moves = await db.movesDao.getAll();

        expect(report.recoveredMoves, 1);
        expect(report.historicalAssetsDiscovered, 2);
        expect(report.historicalAssetsUntracked, 2);
        expect(report.historicalAssetsRecovered, 1);
        expect(report.historicalRestoreFailures, 1);
        expect(report.historicalAssetsStillPending, 1);
        expect(
          report.snackBarMessage,
          'Recovered 1 historical album video. 1 still need attention.',
        );
        expect(moves, hasLength(1));
      },
    );

    test('reports limited Photos access for historical recovery', () async {
      videoAlbum.accessStatus = PhotoLibraryAccessStatus.limited;
      videoAlbum.discoveryResult = const RecoverableManagedAssetDiscoveryResult(
        accessStatus: PhotoLibraryAccessStatus.limited,
        assets: [],
      );

      final report = await service.reconcileExternalDeletes();

      expect(report.accessStatus, PhotoLibraryAccessStatus.limited);
      expect(report.hasStartupSignal, isTrue);
      expect(
        report.snackBarMessage,
        'Photos access is limited, so some historical Breakdex albums may stay hidden.',
      );
    });

    test('no startup signal when nothing discovered and access is authorized', () async {
      final report = await service.reconcileExternalDeletes();

      expect(report.hasStartupSignal, isFalse);
    });

    test('reports matching albums that expose no readable filenames', () async {
      videoAlbum.discoveryResult = const RecoverableManagedAssetDiscoveryResult(
        accessStatus: PhotoLibraryAccessStatus.authorized,
        assets: [],
        matchingAlbumCount: 2,
        videoAssetCount: 3,
        skippedMissingFilenameCount: 3,
      );

      final report = await service.reconcileExternalDeletes();

      expect(report.historicalMatchingAlbums, 2);
      expect(report.historicalVideoAssetsSeen, 3);
      expect(report.historicalAssetsSkippedMissingFilename, 3);
      expect(
        report.snackBarMessage,
        'Found 2 Breakdex albums, but iPhone did not expose readable video filenames yet.',
      );
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
