
import 'package:breakdex/core/database/database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_data.dart';

/// Tests for [LabsDao] — the data-access layer for Labs, LabMoves,
/// LabEntries, and Milestones.
///
/// Each test uses a fresh in-memory SQLite database with foreign key
/// enforcement enabled (PRAGMA foreign_keys=ON), so cascade deletes on
/// LabMoves, LabEntries, and Milestones are exercised. This is isolated
/// and safe for parallel execution.
void main() {
  late AppDatabase db;

  setUp(() {
    // Enable foreign key enforcement so FK ON DELETE CASCADE works.
    db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (final rawDb) {
          rawDb.execute('PRAGMA journal_mode=WAL');
          rawDb.execute('PRAGMA foreign_keys=ON');
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Inserts a lab and returns its ID for subsequent assertions.
  Future<String> insertLab({
    required final String id,
    final String name = 'Test Lab',
    final String labType = 'project',
    final String status = 'idea',
  }) async {
    await db.labsDao.insertLab(LabsCompanion.insert(
      id: id,
      name: name,
      labType: Value(labType),
      status: Value(status),
    ));
    return id;
  }

  // ---------------------------------------------------------------------------
  // Create / Read
  // ---------------------------------------------------------------------------

  group('Create & getAll', () {
    test('created lab appears in getAll', () async {
      await insertLab(id: 'lab-1', name: 'Windmill Project');

      final labs = await db.labsDao.getAll();
      expect(labs, hasLength(1));
      expect(labs.first.id, 'lab-1');
      expect(labs.first.name, 'Windmill Project');
      expect(labs.first.labType, 'project');
      expect(labs.first.status, 'idea');
    });

    test('multiple labs ordered by updatedAt descending', () async {
      // Insert with explicit timestamps to guarantee ordering — SQLite
      // currentDateAndTime resolution is seconds, so a delay alone is fragile.
      await db.labsDao.insertLab(LabsCompanion.insert(
        id: 'lab-old',
        name: 'Old Lab',
        updatedAt: Value(DateTime(2024, 1, 1)),
      ));
      await db.labsDao.insertLab(LabsCompanion.insert(
        id: 'lab-new',
        name: 'New Lab',
        updatedAt: Value(DateTime(2024, 6, 1)),
      ));

      final labs = await db.labsDao.getAll();
      expect(labs, hasLength(2));
      // Most recently updated first.
      expect(labs.first.id, 'lab-new');
      expect(labs.last.id, 'lab-old');
    });

    test('getById returns correct lab', () async {
      await insertLab(id: 'lab-1', name: 'Target Lab');
      await insertLab(id: 'lab-2', name: 'Other Lab');

      final lab = await db.labsDao.getById('lab-1');
      expect(lab, isNotNull);
      expect(lab!.name, 'Target Lab');
    });

    test('getById returns null for non-existent ID', () async {
      final lab = await db.labsDao.getById('does-not-exist');
      expect(lab, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  group('Update lab', () {
    test('updateLab changes status field', () async {
      await insertLab(id: 'lab-1', status: 'idea');

      await db.labsDao.updateLab(const LabsCompanion(
        id: Value('lab-1'),
        status: Value('attempting'),
      ));

      final updated = await db.labsDao.getById('lab-1');
      expect(updated!.status, 'attempting');
    });

    test('updateLab changes name field', () async {
      await insertLab(id: 'lab-1', name: 'Original');

      await db.labsDao.updateLab(const LabsCompanion(
        id: Value('lab-1'),
        name: Value('Renamed'),
      ));

      final updated = await db.labsDao.getById('lab-1');
      expect(updated!.name, 'Renamed');
    });
  });

  // ---------------------------------------------------------------------------
  // Delete + cascade
  // ---------------------------------------------------------------------------

  group('Delete & cascade', () {
    test('deleteLab removes the lab from getAll', () async {
      await insertLab(id: 'lab-1');
      await insertLab(id: 'lab-2');

      await db.labsDao.deleteLab('lab-1');

      final labs = await db.labsDao.getAll();
      expect(labs, hasLength(1));
      expect(labs.first.id, 'lab-2');
    });

    test('deleteLab cascade-deletes milestones', () async {
      await insertLab(id: 'lab-1');
      await db.milestonesDao.insertMilestone(MilestonesCompanion.insert(
        id: 'ms-1',
        labId: 'lab-1',
        title: 'First milestone',
      ));

      // Verify milestone exists before delete.
      final beforeStream = db.milestonesDao.watchByLab('lab-1');
      final before = await beforeStream.first;
      expect(before, hasLength(1));

      await db.labsDao.deleteLab('lab-1');

      final after = await db.milestonesDao.watchByLab('lab-1').first;
      expect(after, isEmpty);
    });

    test('deleteLab cascade-deletes lab entries', () async {
      await insertLab(id: 'lab-1');
      await db.labEntriesDao.insertEntry(LabEntriesCompanion.insert(
        id: 'entry-1',
        labId: const Value('lab-1'),
        content: 'Some log entry',
      ));

      await db.labsDao.deleteLab('lab-1');

      final entries = await db.labEntriesDao.watchByLab('lab-1').first;
      expect(entries, isEmpty);
    });

    test('deleteLab cascade-deletes lab moves', () async {
      await insertLab(id: 'lab-1');
      await seedMove(db, id: 'move-1', name: 'Windmill');
      await db.labsDao.addMoveToLab('lab-1', 'move-1', 0);

      await db.labsDao.deleteLab('lab-1');

      final labMoves = await db.labsDao.watchLabMoves('lab-1').first;
      expect(labMoves, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // LabMoves — add / remove / reorder
  // ---------------------------------------------------------------------------

  group('LabMoves CRUD', () {
    test('addMoveToLab links move to lab', () async {
      await insertLab(id: 'lab-1');
      await seedMove(db, id: 'move-1', name: 'Windmill');
      await db.labsDao.addMoveToLab('lab-1', 'move-1', 0);

      final labMoves = await db.labsDao.watchLabMoves('lab-1').first;
      expect(labMoves, hasLength(1));
      expect(labMoves.first.move.id, 'move-1');
      expect(labMoves.first.labMove.sequenceIndex, 0);
    });

    test('removeMoveFromLab unlinks the move', () async {
      await insertLab(id: 'lab-1');
      await seedMove(db, id: 'move-1', name: 'Windmill');
      await seedMove(db, id: 'move-2', name: 'Headspin');
      await db.labsDao.addMoveToLab('lab-1', 'move-1', 0);
      await db.labsDao.addMoveToLab('lab-1', 'move-2', 1);

      await db.labsDao.removeMoveFromLab('lab-1', 'move-1');

      final labMoves = await db.labsDao.watchLabMoves('lab-1').first;
      expect(labMoves, hasLength(1));
      expect(labMoves.first.move.id, 'move-2');
    });

    test('reorderLabMoves changes sequence indices', () async {
      await insertLab(id: 'lab-1');
      await seedMove(db, id: 'move-a', name: 'Alpha');
      await seedMove(db, id: 'move-b', name: 'Beta');
      await seedMove(db, id: 'move-c', name: 'Charlie');
      await db.labsDao.addMoveToLab('lab-1', 'move-a', 0);
      await db.labsDao.addMoveToLab('lab-1', 'move-b', 1);
      await db.labsDao.addMoveToLab('lab-1', 'move-c', 2);

      // Reverse the order: C, B, A
      await db.labsDao
          .reorderLabMoves('lab-1', ['move-c', 'move-b', 'move-a']);

      final labMoves = await db.labsDao.watchLabMoves('lab-1').first;
      expect(labMoves, hasLength(3));
      expect(labMoves[0].move.id, 'move-c');
      expect(labMoves[0].labMove.sequenceIndex, 0);
      expect(labMoves[1].move.id, 'move-b');
      expect(labMoves[1].labMove.sequenceIndex, 1);
      expect(labMoves[2].move.id, 'move-a');
      expect(labMoves[2].labMove.sequenceIndex, 2);
    });

    test('multiple moves maintain correct sequence index order', () async {
      await insertLab(id: 'lab-1');
      await seedMove(db, id: 'move-1', name: 'First');
      await seedMove(db, id: 'move-2', name: 'Second');
      await seedMove(db, id: 'move-3', name: 'Third');

      await db.labsDao.addMoveToLab('lab-1', 'move-1', 0);
      await db.labsDao.addMoveToLab('lab-1', 'move-2', 1);
      await db.labsDao.addMoveToLab('lab-1', 'move-3', 2);

      final labMoves = await db.labsDao.watchLabMoves('lab-1').first;
      expect(labMoves.map((final lm) => lm.move.id).toList(),
          ['move-1', 'move-2', 'move-3']);
    });
  });

  // ---------------------------------------------------------------------------
  // watchAll stream
  // ---------------------------------------------------------------------------

  group('watchAll stream', () {
    test('emits on insert', () async {
      final stream = db.labsDao.watchAll();

      // First emission: empty list.
      final first = await stream.first;
      expect(first, isEmpty);

      // Insert a lab and capture the next emission.
      await insertLab(id: 'lab-1', name: 'Stream Lab');

      final second = await stream.first;
      expect(second, hasLength(1));
      expect(second.first.name, 'Stream Lab');
    });

    test('emits on delete', () async {
      await insertLab(id: 'lab-1');

      final stream = db.labsDao.watchAll();
      final first = await stream.first;
      expect(first, hasLength(1));

      await db.labsDao.deleteLab('lab-1');

      final second = await stream.first;
      expect(second, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // watchByType
  // ---------------------------------------------------------------------------

  group('watchByType', () {
    test('filters by project type', () async {
      await insertLab(id: 'lab-proj', labType: 'project', name: 'Project');
      await insertLab(id: 'lab-set', labType: 'set', name: 'Set');

      final projects = await db.labsDao.watchByType('project').first;
      expect(projects, hasLength(1));
      expect(projects.first.id, 'lab-proj');
    });

    test('filters by set type', () async {
      await insertLab(id: 'lab-proj', labType: 'project', name: 'Project');
      await insertLab(id: 'lab-set', labType: 'set', name: 'Set');

      final sets = await db.labsDao.watchByType('set').first;
      expect(sets, hasLength(1));
      expect(sets.first.id, 'lab-set');
    });

    test('returns empty for unmatched type', () async {
      await insertLab(id: 'lab-1', labType: 'project');

      final sets = await db.labsDao.watchByType('set').first;
      expect(sets, isEmpty);
    });
  });
}
