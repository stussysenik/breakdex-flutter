/// Wave task 4.7 — `decks` + `deck_moves` backfill → Appwrite shadow,
/// byte-identical proof (mirrors `combos_backfill_appwrite_test.dart`).
///
/// The records `SyncBackfillService` produces reach the `sync-push` wire
/// unchanged (same ids/clocks/deterministic clientOpIds/payload as the local
/// codec), and the local tables are byte-identical afterward. deck_moves is
/// keyed by the composite `'$deckId:$moveId'` on the wire. Live smoke-user push
/// rides M.3.
library;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/backends/appwrite_sync_backend.dart';
import 'package:breakdex/core/sync/backends/appwrite_transport.dart';
import 'package:breakdex/core/sync/backfill/sync_backfill_service.dart';
import 'package:breakdex/core/sync/codecs/deck_codec.dart';
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
  test('backfill → AppwriteSyncBackend emits byte-identical decks + deckMoves',
      () async {
    final db = _freshDb();
    await db.decksDao.insertDeck(DecksCompanion.insert(id: 'd1', name: 'Power'));
    await db.decksDao.insertDeck(DecksCompanion.insert(id: 'd2', name: 'Footwork'));
    await db.decksDao.addMoveToDeck('d1', 'm1');
    await db.decksDao.addMoveToDeck('d1', 'm2');

    final expectedDecks = {
      for (final d in await db.decksDao.getAll()) d.id: deckToSyncRecord(d),
    };
    final expectedJoins = {
      for (final j in await db.decksDao.getAllDeckMoves())
        deckMoveWireId(j.deckId, j.moveId): deckMoveToSyncRecord(j),
    };

    final transport = _CapturingTransport();
    final backend = AppwriteSyncBackend(transport);
    final service = SyncBackfillService(backend, db.movesDao, decksDao: db.decksDao);

    final beforeDecks =
        (await db.customSelect('SELECT * FROM decks ORDER BY id').get())
            .map((final r) => r.data)
            .toList();
    final beforeJoins = (await db
            .customSelect('SELECT * FROM deck_moves ORDER BY deck_id, move_id')
            .get())
        .map((final r) => r.data)
        .toList();

    final deckReport = await service.backfillDecks();
    final joinReport = await service.backfillDeckMoves();

    expect(deckReport.recordCount, 2);
    expect(joinReport.recordCount, 2);

    for (final e in transport.executions) {
      expect(e.functionId, 'sync-push');
      expect(e.body['table'], anyOf('decks', 'deckMoves'));
      expect((e.body['deletes']! as List), isEmpty);
    }

    Iterable<Map<String, Object?>> upsertsFor(final String table) => transport
        .executions
        .where((final e) => e.body['table'] == table)
        .expand((final e) => e.body['upserts']! as List)
        .cast<Map<String, Object?>>();

    for (final u in upsertsFor('decks')) {
      final rec = expectedDecks[u['localId']]!;
      expect(u['clientOpId'], rec.clientOpId);
      expect(u['updatedAt'], rec.updatedAt.millisecondsSinceEpoch);
      expect(u['json'], rec.json);
    }
    expect(upsertsFor('decks').map((final u) => u['localId']).toSet(), {'d1', 'd2'});

    for (final u in upsertsFor('deckMoves')) {
      final rec = expectedJoins[u['localId']]!;
      expect(u['clientOpId'], rec.clientOpId);
      expect(u['updatedAt'], rec.updatedAt.millisecondsSinceEpoch);
      expect(u['json'], rec.json);
    }
    expect(upsertsFor('deckMoves').map((final u) => u['localId']).toSet(),
        {'d1:m1', 'd1:m2'});

    // Non-destructive: local tables unchanged.
    expect(
        (await db.customSelect('SELECT * FROM decks ORDER BY id').get())
            .map((final r) => r.data)
            .toList(),
        beforeDecks);
    expect(
        (await db
                .customSelect('SELECT * FROM deck_moves ORDER BY deck_id, move_id')
                .get())
            .map((final r) => r.data)
            .toList(),
        beforeJoins);

    await db.close();
  });
}
