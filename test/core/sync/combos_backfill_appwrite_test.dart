/// Wave task 4.4 — `combos` + `combo_moves` backfill → Appwrite shadow,
/// byte-identical proof (mirrors `moves_backfill_appwrite_test.dart`).
///
/// The records `SyncBackfillService` produces for each entity reach the
/// `sync-push` Function wire unchanged (same ids, clocks, deterministic
/// clientOpIds, and payload as the local codec projection), and the local
/// tables are byte-identical afterward. The live smoke-user push rides M.3.
library;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/backends/appwrite_sync_backend.dart';
import 'package:breakdex/core/sync/backends/appwrite_transport.dart';
import 'package:breakdex/core/sync/backfill/sync_backfill_service.dart';
import 'package:breakdex/core/sync/codecs/combo_codec.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingTransport implements AppwriteTransport {
  final List<({String functionId, Map<String, Object?> body})> executions = [];

  @override
  Future<Object?> execute(
    final String functionId, {
    final Map<String, Object?> body = const {},
  }) async {
    executions.add((functionId: functionId, body: body));
    return {'applied': 1, 'skipped': 0, 'failed': 0};
  }

  @override
  Future<List<Map<String, Object?>>> listRows(
    final String table, {
    required final String orderField,
    final int? since,
  }) async => const [];

  @override
  Stream<void>? channelEvents(final List<String> channels) => null;
}

AppDatabase _freshDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<List<Map<String, dynamic>>> _snapshot(
  final AppDatabase db,
  final String table,
) async {
  final rows = await db.customSelect('SELECT * FROM $table ORDER BY id').get();
  return rows.map((final r) => r.data).toList();
}

void main() {
  test(
    'backfill → AppwriteSyncBackend emits byte-identical combos + comboMoves',
    () async {
      final db = _freshDb();
      await db.combosDao.insertCombo(
        CombosCompanion.insert(id: 'c1', name: 'Opener'),
      );
      await db.combosDao.insertCombo(
        CombosCompanion.insert(id: 'c2', name: 'Finisher'),
      );
      await db.combosDao.addMoveToCombo(
        ComboMovesCompanion.insert(
          id: 'cm1',
          comboId: 'c1',
          moveId: 'm1',
          sequenceIndex: 0,
        ),
      );
      await db.combosDao.addMoveToCombo(
        ComboMovesCompanion.insert(
          id: 'cm2',
          comboId: 'c1',
          moveId: 'm2',
          sequenceIndex: 1,
        ),
      );

      final expectedCombos = {
        for (final c in await db.combosDao.getAll()) c.id: comboToSyncRecord(c),
      };
      final expectedSteps = {
        for (final s in await db.combosDao.getAllComboMoves())
          s.id: comboMoveToSyncRecord(s),
      };

      final transport = _CapturingTransport();
      final backend = AppwriteSyncBackend(transport);
      final service = SyncBackfillService(
        backend,
        db.movesDao,
        combosDao: db.combosDao,
      );

      final beforeCombos = await _snapshot(db, 'combos');
      final beforeSteps = await _snapshot(db, 'combo_moves');

      final comboReport = await service.backfillCombos();
      final stepReport = await service.backfillComboMoves();

      expect(comboReport.recordCount, 2);
      expect(stepReport.recordCount, 2);

      // Every capture routed to sync-push with the right table and no deletes.
      for (final e in transport.executions) {
        expect(e.functionId, 'sync-push');
        expect(e.body['table'], anyOf('combos', 'comboMoves'));
        expect((e.body['deletes']! as List), isEmpty);
      }

      Iterable<Map<String, Object?>> upsertsFor(final String table) => transport
          .executions
          .where((final e) => e.body['table'] == table)
          .expand((final e) => e.body['upserts']! as List)
          .cast<Map<String, Object?>>();

      for (final u in upsertsFor('combos')) {
        final rec = expectedCombos[u['localId']]!;
        expect(u['clientOpId'], rec.clientOpId);
        expect(u['updatedAt'], rec.updatedAt.millisecondsSinceEpoch);
        expect(u['json'], rec.json);
      }
      expect(upsertsFor('combos').map((final u) => u['localId']).toSet(), {
        'c1',
        'c2',
      });

      for (final u in upsertsFor('comboMoves')) {
        final rec = expectedSteps[u['localId']]!;
        expect(u['clientOpId'], rec.clientOpId);
        expect(u['updatedAt'], rec.updatedAt.millisecondsSinceEpoch);
        expect(u['json'], rec.json);
      }
      expect(upsertsFor('comboMoves').map((final u) => u['localId']).toSet(), {
        'cm1',
        'cm2',
      });

      // Non-destructive: local tables unchanged.
      expect(await _snapshot(db, 'combos'), beforeCombos);
      expect(await _snapshot(db, 'combo_moves'), beforeSteps);

      await db.close();
    },
  );
}
