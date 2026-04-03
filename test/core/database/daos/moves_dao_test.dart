import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

import '../../../helpers/test_database.dart';

void main() {
  group('MovesDao archive filters', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'active queries exclude archived moves while by-id still resolves',
      () async {
        await db.movesDao.insertMove(
          MovesCompanion.insert(id: 'active-1', name: 'Airflare'),
        );
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'archived-1',
            name: 'Swipe',
            archivedAt: Value(DateTime.utc(2026, 4, 3)),
            archiveReason: const Value('external_album_delete'),
          ),
        );

        final activeMoves = await db.movesDao.getAll();
        final archivedMoves = await db.movesDao.getArchived();
        final archivedMove = await db.movesDao.getById('archived-1');

        expect(activeMoves.map((move) => move.id), ['active-1']);
        expect(archivedMoves.map((move) => move.id), ['archived-1']);
        expect(archivedMove.archiveReason, 'external_album_delete');
      },
    );

    test(
      'tracked managed album query returns only active tracked moves',
      () async {
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'tracked-1',
            name: 'Halo',
            videoPath: const Value('Moves/halo.mp4'),
            managedAlbumAssetId: const Value('asset-1'),
          ),
        );
        await db.movesDao.insertMove(
          MovesCompanion.insert(
            id: 'archived-tracked',
            name: 'Cricket',
            videoPath: const Value('Moves/cricket.mp4'),
            managedAlbumAssetId: const Value('asset-2'),
            archivedAt: Value(DateTime.utc(2026, 4, 1)),
          ),
        );

        final trackedMoves = await db.movesDao.getTrackedManagedAlbumMoves();

        expect(trackedMoves.map((move) => move.id), ['tracked-1']);
      },
    );
  });
}
