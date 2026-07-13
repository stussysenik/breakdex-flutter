/// Wave task 4.9 — `moveNoteEntries` + `comboNoteEntries` backfill → Appwrite
/// shadow, byte-identical proof (mirrors `decks_backfill_appwrite_test.dart`).
///
/// The records `SyncBackfillService` produces reach the `sync-push` wire
/// unchanged (same ids/clocks/deterministic clientOpIds/payload as the local
/// codec), the local tables are byte-identical afterward, and a soft-hidden note
/// is excluded (a backfill never resurrects a note deleted elsewhere). Live
/// smoke-user push rides M.3.
library;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/backends/appwrite_sync_backend.dart';
import 'package:breakdex/core/sync/backends/appwrite_transport.dart';
import 'package:breakdex/core/sync/backfill/sync_backfill_service.dart';
import 'package:breakdex/core/sync/codecs/note_entry_codec.dart';
import 'package:drift/drift.dart' show Value;
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

void main() {
  test('backfill → AppwriteSyncBackend emits byte-identical note entries',
      () async {
    final db = _freshDb();
    await db.moveNoteEntriesDao.addEntry(id: 'mn1', moveId: 'm1', body: 'a');
    await db.moveNoteEntriesDao.addEntry(id: 'mn2', moveId: 'm1', body: 'b');
    await db.comboNoteEntriesDao
        .addEntry(id: 'cn1', comboId: 'c1', body: 'take', videoPath: 'v.mp4');
    // A soft-hidden note must NOT be backfilled (would resurrect elsewhere).
    await db.moveNoteEntriesDao.addEntry(id: 'mnHidden', moveId: 'm1', body: 'x');
    await (db.update(db.moveNoteEntries)
          ..where((final t) => t.id.equals('mnHidden')))
        .write(MoveNoteEntriesCompanion(deletedAt: Value(DateTime.now().toUtc())));

    final expectedMoveNotes = {
      for (final n in await db.moveNoteEntriesDao.getAll())
        n.id: moveNoteEntryToSyncRecord(n),
    };
    final expectedComboNotes = {
      for (final n in await db.comboNoteEntriesDao.getAll())
        n.id: comboNoteEntryToSyncRecord(n),
    };

    final transport = _CapturingTransport();
    final backend = AppwriteSyncBackend(transport);
    final service = SyncBackfillService(
      backend,
      db.movesDao,
      moveNoteEntriesDao: db.moveNoteEntriesDao,
      comboNoteEntriesDao: db.comboNoteEntriesDao,
    );

    final beforeMove =
        (await db.customSelect('SELECT * FROM move_note_entries ORDER BY id').get())
            .map((final r) => r.data)
            .toList();

    final moveReport = await service.backfillMoveNoteEntries();
    final comboReport = await service.backfillComboNoteEntries();

    // mnHidden excluded ⇒ only the two live move notes.
    expect(moveReport.recordCount, 2);
    expect(comboReport.recordCount, 1);

    Iterable<Map<String, Object?>> upsertsFor(final String table) => transport
        .executions
        .where((final e) => e.body['table'] == table)
        .expand((final e) => e.body['upserts']! as List)
        .cast<Map<String, Object?>>();

    for (final u in upsertsFor('moveNoteEntries')) {
      final rec = expectedMoveNotes[u['localId']]!;
      expect(u['clientOpId'], rec.clientOpId);
      expect(u['updatedAt'], rec.updatedAt.millisecondsSinceEpoch);
      expect(u['json'], rec.json);
    }
    expect(upsertsFor('moveNoteEntries').map((final u) => u['localId']).toSet(),
        {'mn1', 'mn2'});

    for (final u in upsertsFor('comboNoteEntries')) {
      final rec = expectedComboNotes[u['localId']]!;
      expect(u['json'], rec.json);
    }

    // Non-destructive: local table unchanged (soft-hidden row still present).
    expect(
        (await db.customSelect('SELECT * FROM move_note_entries ORDER BY id').get())
            .map((final r) => r.data)
            .toList(),
        beforeMove);

    await db.close();
  });
}
