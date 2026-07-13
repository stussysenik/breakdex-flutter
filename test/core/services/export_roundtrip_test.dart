import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/app_metadata.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/combo_plans_dao.dart';
import 'package:breakdex/core/services/stats_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedJourneyData() async {
    await db.combosDao.insertCombo(CombosCompanion.insert(
      id: 'c1',
      name: 'Opener Set',
      status: const Value('attempting'),
    ));
    await db.comboNoteEntriesDao.addEntry(
      id: 'e1',
      comboId: 'c1',
      body: 'felt smooth today',
    );
    await db.comboNoteEntriesDao.addEntry(
      id: 'e2',
      comboId: 'c1',
      body: 'take from session',
      videoPath: 'Moves/windmill/take_03.MOV',
      videoHash: 'abc123',
    );
    await db.comboPlansDao.insertPlan(ComboPlansCompanion.insert(
      id: 'p1',
      comboId: 'c1',
      planDate: ComboPlansDao.dateOnly(
        DateTime.now().add(const Duration(days: 2)),
      ),
      position: const Value(3),
    ));
  }

  group('Export schema v10', () {
    test('export carries status, createdAt, journal, and plans', () async {
      await seedJourneyData();

      final result = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(result.json) as Map<String, dynamic>;

      expect(data['schemaVersion'], 10);
      expect(AppMetadata.exportSchemaVersion, 10);

      final combo = (data['combos'] as List).single as Map<String, dynamic>;
      expect(combo['status'], 'attempting');
      expect(combo['createdAt'], isNotNull);

      final entries = data['comboNoteEntries'] as List;
      expect(entries.length, 2, reason: 'both seeded jots exported');
    });

    test('v9 export round-trips into an empty database losslessly', () async {
      await seedJourneyData();
      final exported =
          (await StatsExportService.generateJsonExport(db, prefs)).json;

      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues({});
      final prefs2 = await SharedPreferences.getInstance();

      await StatsExportService.importFromJson(
        db2,
        prefs2,
        exported,
        ImportMode.replaceAll,
      );

      final combo = await db2.combosDao.getById('c1');
      expect(combo.status, 'attempting');

      final entries = await db2.comboNoteEntriesDao.getByComboId('c1');
      expect(entries.length, 2);
      final take = entries.singleWhere((final e) => e.id == 'e2');
      expect(take.videoPath, 'Moves/windmill/take_03.MOV');
      expect(take.videoHash, 'abc123');
      expect(take.kind, 'jot');

      final plans = await db2.comboPlansDao.getAll();
      expect(plans.length, 1);
      expect(plans.single.position, 3);
      expect(plans.single.completedAt, isNull);

      await db2.close();
    });

    test('v10 tombstones + move journal survive the round-trip', () async {
      // A live move and a soft-deleted (tombstoned) move.
      await db.into(db.moves).insert(
            MovesCompanion.insert(id: 'm-live', name: 'Windmill'),
          );
      await db.into(db.moves).insert(
            MovesCompanion.insert(
              id: 'm-dead',
              name: 'Retired',
              deletedAt: Value(DateTime.utc(2026, 7, 10)),
            ),
          );
      // Move journal entry (v10-only export table).
      await db.into(db.moveNoteEntries).insert(
            MoveNoteEntriesCompanion.insert(
              id: 'mn1',
              moveId: 'm-live',
              body: 'grabbed the hop',
            ),
          );

      final exported =
          (await StatsExportService.generateJsonExport(db, prefs)).json;

      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues({});
      final prefs2 = await SharedPreferences.getInstance();
      await StatsExportService.importFromJson(
        db2,
        prefs2,
        exported,
        ImportMode.replaceAll,
      );

      // The tombstone was captured and restored — the deleted move is NOT
      // resurrected as a live row.
      final allMoves = await db2.select(db2.moves).get();
      expect(allMoves.map((final m) => m.id).toSet(), {'m-live', 'm-dead'});
      final dead = allMoves.singleWhere((final m) => m.id == 'm-dead');
      expect(dead.deletedAt, isNotNull);
      expect(dead.deletedAt!.isAtSameMomentAs(DateTime.utc(2026, 7, 10)), isTrue);
      final live = allMoves.singleWhere((final m) => m.id == 'm-live');
      expect(live.deletedAt, isNull);

      // Move journal round-tripped.
      final notes = await db2.select(db2.moveNoteEntries).get();
      expect(notes.single.id, 'mn1');
      expect(notes.single.moveId, 'm-live');
      expect(notes.single.body, 'grabbed the hop');

      await db2.close();
    });

    test('pre-v9 import gets defaults: status=idea, kind=jot, zero plans',
        () async {
      final v8Json = jsonEncode({
        'schemaVersion': 8,
        'combos': [
          {'id': 'c-old', 'name': 'Legacy Combo', 'notes': 'kept'},
        ],
        'comboMoves': <Object>[],
      });

      await StatsExportService.importFromJson(
        db,
        prefs,
        v8Json,
        ImportMode.replaceAll,
      );

      final combo = await db.combosDao.getById('c-old');
      expect(combo.status, 'idea');
      expect(combo.notes, 'kept');
      expect(combo.createdAt.millisecondsSinceEpoch, greaterThan(0));

      expect(await db.comboPlansDao.getAll(), isEmpty);
      expect(await db.comboNoteEntriesDao.getByComboId('c-old'), isEmpty);
    });

    test('validation accepts older versions and rejects newer ones', () {
      final older = jsonEncode({'schemaVersion': 6});
      expect(StatsExportService.validateImportJson(older).valid, isTrue);

      final newer = jsonEncode({
        'schemaVersion': AppMetadata.exportSchemaVersion + 1,
      });
      expect(StatsExportService.validateImportJson(newer).valid, isFalse);
    });
  });
}
