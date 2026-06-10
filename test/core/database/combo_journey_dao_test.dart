import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/combo_plans_dao.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedCombo(final String id, final String name) {
    return db.combosDao.insertCombo(
      CombosCompanion.insert(id: id, name: name),
    );
  }

  group('CombosDao.updateStatus', () {
    test('updates tag and appends kind=status ledger row atomically',
        () async {
      await seedCombo('c1', 'Opener');

      await db.combosDao.updateStatus(
        comboId: 'c1',
        newStatus: 'attempting',
        entryId: 'entry-1',
      );

      final combo = await db.combosDao.getById('c1');
      expect(combo.status, 'attempting');

      final entries = await db.comboNoteEntriesDao.getByComboId('c1');
      expect(entries.length, 1);
      expect(entries.single.kind, 'status');
      expect(entries.single.body, 'idea → attempting');
    });

    test('same status is a no-op — no ledger row', () async {
      await seedCombo('c1', 'Opener');

      await db.combosDao.updateStatus(
        comboId: 'c1',
        newStatus: 'idea',
        entryId: 'entry-1',
      );

      final entries = await db.comboNoteEntriesDao.getByComboId('c1');
      expect(entries, isEmpty);
    });

    test('failed ledger insert rolls back the status change (both or neither)',
        () async {
      await seedCombo('c1', 'Opener');
      // Occupy the entry id so the ledger insert inside updateStatus fails.
      await db.comboNoteEntriesDao.addEntry(
        id: 'taken',
        comboId: 'c1',
        body: 'pre-existing',
      );

      await expectLater(
        () => db.combosDao.updateStatus(
          comboId: 'c1',
          newStatus: 'landed',
          entryId: 'taken',
        ),
        throwsA(anything),
      );

      final combo = await db.combosDao.getById('c1');
      expect(combo.status, 'idea', reason: 'status must roll back');
    });
  });

  group('ComboPlansDao', () {
    test('CRUD and queue ordering by date then position', () async {
      await seedCombo('c1', 'Opener');
      await seedCombo('c2', 'Closer');

      final tomorrow = ComboPlansDao.dateOnly(
        DateTime.now().add(const Duration(days: 1)),
      );
      final nextWeek = ComboPlansDao.dateOnly(
        DateTime.now().add(const Duration(days: 7)),
      );

      await db.comboPlansDao.insertPlan(ComboPlansCompanion.insert(
        id: 'p-late',
        comboId: 'c2',
        planDate: nextWeek,
        position: const Value(0),
      ));
      await db.comboPlansDao.insertPlan(ComboPlansCompanion.insert(
        id: 'p-second',
        comboId: 'c2',
        planDate: tomorrow,
        position: const Value(1),
      ));
      await db.comboPlansDao.insertPlan(ComboPlansCompanion.insert(
        id: 'p-first',
        comboId: 'c1',
        planDate: tomorrow,
        position: const Value(0),
      ));

      final queue = await db.comboPlansDao.watchPlansQueue().first;
      expect(
        queue.map((final p) => p.plan.id).toList(),
        ['p-first', 'p-second', 'p-late'],
      );
      expect(queue.first.combo.name, 'Opener');

      // Reorder persists position
      await db.comboPlansDao.updatePosition('p-first', 5);
      final reordered = await db.comboPlansDao.watchPlansQueue().first;
      expect(
        reordered.map((final p) => p.plan.id).toList(),
        ['p-second', 'p-first', 'p-late'],
      );

      // Delete
      await db.comboPlansDao.deletePlan('p-late');
      expect((await db.comboPlansDao.getAll()).length, 2);
    });

    test('watchPlansForDate returns only that day', () async {
      await seedCombo('c1', 'Opener');
      final today = ComboPlansDao.dateOnly(DateTime.now());
      final tomorrow = today.add(const Duration(days: 1));

      await db.comboPlansDao.insertPlan(ComboPlansCompanion.insert(
        id: 'p-today',
        comboId: 'c1',
        planDate: today,
      ));
      await db.comboPlansDao.insertPlan(ComboPlansCompanion.insert(
        id: 'p-tomorrow',
        comboId: 'c1',
        planDate: tomorrow,
      ));

      final todays = await db.comboPlansDao.watchPlansForDate(today).first;
      expect(todays.map((final p) => p.plan.id), ['p-today']);
    });

    test('deleting a combo removes its plans (no orphans)', () async {
      await seedCombo('c1', 'Opener');
      await db.comboPlansDao.insertPlan(ComboPlansCompanion.insert(
        id: 'p1',
        comboId: 'c1',
        planDate: ComboPlansDao.dateOnly(DateTime.now()),
      ));

      await db.combosDao.deleteCombo('c1');

      expect(await db.comboPlansDao.getAll(), isEmpty);
    });

    test('evidence completion stamps completedAt for jot on planDate',
        () async {
      await seedCombo('c1', 'Opener');
      await seedCombo('c2', 'Closer');
      final today = ComboPlansDao.dateOnly(DateTime.now());

      await db.comboPlansDao.insertPlan(ComboPlansCompanion.insert(
        id: 'p-evidenced',
        comboId: 'c1',
        planDate: today,
      ));
      await db.comboPlansDao.insertPlan(ComboPlansCompanion.insert(
        id: 'p-unevidenced',
        comboId: 'c2',
        planDate: today,
      ));

      // Jot for c1 today = evidence; status row must NOT count.
      await db.comboNoteEntriesDao.addEntry(
        id: 'jot-1',
        comboId: 'c1',
        body: 'hit it twice',
      );
      await db.comboNoteEntriesDao.addEntry(
        id: 'status-1',
        comboId: 'c2',
        body: 'idea → attempting',
        kind: 'status',
      );

      final stamped = await db.comboPlansDao.stampCompletionsFromEvidence();
      expect(stamped, 1);

      final evidenced = await db.comboPlansDao.getById('p-evidenced');
      expect(evidenced.completedAt, isNotNull);

      final unevidenced = await db.comboPlansDao.getById('p-unevidenced');
      expect(unevidenced.completedAt, isNull,
          reason: 'status rows are not practice evidence');

      // Completed plans leave the queue.
      final queue = await db.comboPlansDao.watchPlansQueue().first;
      expect(queue.map((final p) => p.plan.id), ['p-unevidenced']);
    });
  });

  group('CombosDao.watchCombosWithMeta', () {
    test('returns counts and latest entry, newest combos first', () async {
      await seedCombo('c1', 'Opener');
      await seedCombo('c2', 'Closer');
      await db.movesDao.insertMove(MovesCompanion.insert(
        id: 'm1',
        name: 'Windmill',
      ));
      await db.combosDao.addMoveToCombo(ComboMovesCompanion.insert(
        id: 'cm1',
        comboId: 'c1',
        moveId: 'm1',
        sequenceIndex: 0,
      ));

      await db.comboNoteEntriesDao.addEntry(
        id: 'j1',
        comboId: 'c1',
        body: 'older jot',
      );
      await db.comboNoteEntriesDao.addEntry(
        id: 'j2',
        comboId: 'c1',
        body: 'latest jot',
      );

      final metas = await db.combosDao.watchCombosWithMeta().first;
      expect(metas.length, 2);

      final c1Meta =
          metas.singleWhere((final m) => m.combo.id == 'c1');
      expect(c1Meta.moveCount, 1);
      expect(c1Meta.jotCount, 2);
      expect(c1Meta.lastEntryBody, 'latest jot');
      expect(c1Meta.lastEntryKind, 'jot');
      expect(c1Meta.lastEntryAt, isNotNull);

      final c2Meta =
          metas.singleWhere((final m) => m.combo.id == 'c2');
      expect(c2Meta.moveCount, 0);
      expect(c2Meta.jotCount, 0);
      expect(c2Meta.lastEntryBody, isNull);
    });
  });

  group('CombosDao.watchActivityRollup', () {
    test('rolls up jots and takes per local day', () async {
      await seedCombo('c1', 'Opener');

      await db.comboNoteEntriesDao.addEntry(
        id: 'j1',
        comboId: 'c1',
        body: 'plain jot',
      );
      await db.comboNoteEntriesDao.addEntry(
        id: 'j2',
        comboId: 'c1',
        body: 'take with video',
        videoPath: 'Moves/windmill/take_03.MOV',
      );
      await db.comboNoteEntriesDao.addEntry(
        id: 's1',
        comboId: 'c1',
        body: 'idea → attempting',
        kind: 'status',
      );

      final rollup = await db.combosDao.watchActivityRollup().first;
      expect(rollup.length, 1);
      expect(rollup.single.jotCount, 2, reason: 'status rows excluded');
      expect(rollup.single.takeCount, 1);

      final today = DateTime.now();
      expect(rollup.single.day.year, today.year);
      expect(rollup.single.day.month, today.month);
      expect(rollup.single.day.day, today.day);
    });
  });

  group('CombosDao.duplicateCombo', () {
    test('clones structure as idea with provenance journal row', () async {
      await seedCombo('c1', 'Opener');
      await db.combosDao.updateStatus(
        comboId: 'c1',
        newStatus: 'clean',
        entryId: 'st1',
      );
      await db.movesDao.insertMove(MovesCompanion.insert(
        id: 'm1',
        name: 'Windmill',
      ));
      await db.movesDao.insertMove(MovesCompanion.insert(
        id: 'm2',
        name: 'Flare',
      ));
      await db.combosDao.addMoveToCombo(ComboMovesCompanion.insert(
        id: 'cm1',
        comboId: 'c1',
        moveId: 'm1',
        sequenceIndex: 0,
      ));
      await db.combosDao.addMoveToCombo(ComboMovesCompanion.insert(
        id: 'cm2',
        comboId: 'c1',
        moveId: 'm2',
        sequenceIndex: 1,
        count: const Value(2),
      ));

      var nextId = 0;
      await db.combosDao.duplicateCombo(
        sourceComboId: 'c1',
        newComboId: 'c1-copy',
        newName: 'Opener (copy)',
        provenanceEntryId: 'prov-1',
        comboMoveIdFactory: () => 'new-cm-${nextId++}',
      );

      final copy = await db.combosDao.getById('c1-copy');
      expect(copy.status, 'idea', reason: 'copies are sketches');
      expect(copy.name, 'Opener (copy)');

      final copiedMoves =
          await db.combosDao.watchComboMoves('c1-copy').first;
      expect(copiedMoves.length, 2);
      expect(copiedMoves[0].move.id, 'm1');
      expect(copiedMoves[1].move.id, 'm2');
      expect(copiedMoves[1].comboMove.count, 2);

      final journal = await db.comboNoteEntriesDao.getByComboId('c1-copy');
      expect(journal.length, 1);
      expect(journal.single.kind, 'duplicate');
      expect(journal.single.body, 'Duplicated from "Opener"');

      // Source untouched
      final source = await db.combosDao.getById('c1');
      expect(source.status, 'clean');
      expect(
        (await db.comboNoteEntriesDao.getByComboId('c1')).length,
        1,
      );
    });
  });
}
