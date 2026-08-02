import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

import '../../../helpers/test_database.dart';

/// Task 8.3 — a combo row draws its children's faces from the same library
/// query that already walks `combo_moves` for the transition chain. These
/// tests pin what that extra column carries: sequence order, unfilmed moves
/// skipped rather than held as holes, tombstoned steps excluded, and a
/// `moveCount` that keeps counting everything so the strip's `+N` is honest.
void main() {
  group('watchLibraryRows preview paths', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> addMove(
      final String id,
      final String name, {
      final String? videoPath,
    }) => db.movesDao.insertMove(
      MovesCompanion.insert(
        id: id,
        name: name,
        videoPath: Value(videoPath),
      ),
    );

    Future<void> addStep(
      final String id,
      final String moveId, {
      required final int sequenceIndex,
      final DateTime? deletedAt,
    }) => db.combosDao.addMoveToCombo(
      ComboMovesCompanion.insert(
        id: id,
        sequenceIndex: sequenceIndex,
        comboId: 'combo-1',
        moveId: moveId,
        deletedAt: Value(deletedAt),
      ),
    );

    setUp(() async {
      await db.combosDao.insertCombo(
        CombosCompanion.insert(id: 'combo-1', name: 'Six step into freeze'),
      );
    });

    test('carries filmed moves in sequence order and skips unfilmed', () async {
      await addMove('m1', 'Toprock', videoPath: 'videos/toprock.mp4');
      await addMove('m2', 'Drop'); // never filmed
      await addMove('m3', 'Six step', videoPath: 'videos/six-step.mp4');
      await addStep('s1', 'm1', sequenceIndex: 0);
      await addStep('s2', 'm2', sequenceIndex: 1);
      await addStep('s3', 'm3', sequenceIndex: 2);

      final rows = await db.combosDao.watchLibraryRows().first;

      expect(rows.single.previewVideoPaths, [
        'videos/toprock.mp4',
        'videos/six-step.mp4',
      ]);
      // The unfilmed move is absent from the strip but present in the count,
      // so the row still says the combo is three long.
      expect(rows.single.moveCount, 3);
    });

    test('excludes tombstoned steps, like the name chain does', () async {
      await addMove('m1', 'Toprock', videoPath: 'videos/toprock.mp4');
      await addMove('m2', 'Windmill', videoPath: 'videos/windmill.mp4');
      await addStep('s1', 'm1', sequenceIndex: 0);
      await addStep(
        's2',
        'm2',
        sequenceIndex: 1,
        deletedAt: DateTime.utc(2026, 8, 1),
      );

      final rows = await db.combosDao.watchLibraryRows().first;

      expect(rows.single.previewVideoPaths, ['videos/toprock.mp4']);
      expect(rows.single.moveCount, 1);
    });

    test('a combo with no filmed moves has an empty strip, not a hole', () async {
      await addMove('m1', 'Drop');
      await addStep('s1', 'm1', sequenceIndex: 0);

      final rows = await db.combosDao.watchLibraryRows().first;

      expect(rows.single.previewVideoPaths, isEmpty);
      expect(rows.single.moveCount, 1);
    });

    test('an empty combo has an empty strip', () async {
      final rows = await db.combosDao.watchLibraryRows().first;

      expect(rows.single.previewVideoPaths, isEmpty);
      expect(rows.single.moveCount, 0);
    });
  });
}
