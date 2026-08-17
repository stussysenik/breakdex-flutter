/// Wave task 4.7 — `decks` + `deck_moves` dual-write + dual-read (Appwrite-only).
///
/// Decks have no Firestore leg, so the pair rides the shared LWW engines
/// (`_dualWriteEntity` / `_pullEntity`) exactly like the combos pair: pref-gated
/// upserts + tombstone-for-delete, non-throwing (A1), LWW-merge both directions,
/// two independent cursors under one pair kill-switch. Also proves the DAO's
/// sync-log hook (decks bypass the SyncAware layer).
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/codecs/deck_codec.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import '../../helpers/test_database.dart';

class _FakeBackend implements SyncBackend {
  final List<({SyncEntityType type, List<SyncRecord> upserts, List<SyncTombstone> deletes})>
      pushes = [];
  bool throwOnPush = false;
  final Map<SyncEntityType, SyncDelta> pullResults = {};
  final Map<SyncEntityType, DateTime?> lastSince = {};

  @override
  String get providerType => 'fake';

  @override
  Future<void> push(
    final SyncEntityType type, {
    final List<SyncRecord> upserts = const [],
    final List<SyncTombstone> deletes = const [],
  }) async {
    if (throwOnPush) throw StateError('backend down');
    pushes.add((type: type, upserts: upserts, deletes: deletes));
  }

  @override
  Future<SyncDelta> pull(final SyncEntityType type, {final DateTime? since}) async {
    lastSince[type] = since;
    return pullResults[type] ?? const SyncDelta(upserts: [], deletes: []);
  }

  @override
  Stream<SyncDelta> subscribe(final SyncEntityType type) => const Stream.empty();
}

SyncService _service(
  final AppDatabase db,
  final SharedPreferences prefs, {
  final SyncBackend? backend,
}) => SyncService(

  syncDao: db.syncDao,
  db: db,
  prefs: prefs,
  syncBackend: backend,
);

SyncLogData _entry(final String id, final String table, final String action) =>
    SyncLogData(
      entityTable: table,
      entityId: id,
      action: action,
      changedAt: DateTime.utc(2026),
      synced: false,
      videoSynced: false,
    );

SyncRecord _deckRec(final String id, final DateTime ts, {final String name = 'Remote'}) =>
    SyncRecord(
      id: id,
      type: SyncEntityType.deck,
      json: {
        'name': name,
        'deckType': 'smart',
        'filterCriteria': null,
        'sessionSize': null,
        'createdAt': ts.millisecondsSinceEpoch,
      },
      updatedAt: ts,
      clientOpId: 'op:$id',
    );

SyncRecord _joinRec(final String deckId, final String moveId, final DateTime ts) =>
    SyncRecord(
      id: deckMoveWireId(deckId, moveId),
      type: SyncEntityType.deckMove,
      json: {'deckId': deckId, 'moveId': moveId},
      updatedAt: ts,
      clientOpId: 'op:$deckId:$moveId',
    );

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late _FakeBackend backend;

  setUp(() async {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    backend = _FakeBackend();
  });

  tearDown(() => db.close());

  group('DAO sync-log hook (decks bypass SyncAware)', () {
    test('deck + deck_move mutations enqueue sync_log entries', () async {
      await db.decksDao.insertDeck(DecksCompanion.insert(id: 'd1', name: 'A'));
      await db.decksDao.addMoveToDeck('d1', 'm1');
      await db.decksDao.updateDeck(
          const DecksCompanion(id: Value('d1'), name: Value('A2')));
      await db.decksDao.removeMoveFromDeck('d1', 'm1');
      await db.decksDao.deleteDeck('d1');

      final pending = await db.syncDao.getPendingChanges();
      final decks = pending.where((final e) => e.entityTable == 'decks').toList();
      final joins =
          pending.where((final e) => e.entityTable == 'deck_moves').toList();
      // create+update collapse per (id,action); delete is its own row.
      expect(decks.map((final e) => e.action).toSet(),
          {'create', 'update', 'delete'});
      expect(joins.map((final e) => e.entityId).toSet(), {'d1:m1'});
      expect(joins.map((final e) => e.action).toSet(), {'create', 'delete'});
    });
  });

  group('dual-write', () {
    test('pref OFF ⇒ no push', () async {
      await db.decksDao.insertDeck(DecksCompanion.insert(id: 'd1', name: 'A'));
      await _service(db, prefs, backend: backend)
          .dualWriteDecks([_entry('d1', 'decks', 'create')]);
      expect(backend.pushes, isEmpty);
    });

    test('pref ON ⇒ byte-identical deck upsert', () async {
      await db.decksDao.insertDeck(DecksCompanion.insert(id: 'd1', name: 'A'));
      await prefs.setBool(SyncService.decksDualWritePrefKey, true);
      final expected = deckToSyncRecord((await db.decksDao.getById('d1'))!);

      await _service(db, prefs, backend: backend)
          .dualWriteDecks([_entry('d1', 'decks', 'update')]);

      final push = backend.pushes.single;
      expect(push.type, SyncEntityType.deck);
      final up = push.upserts.single;
      expect(up.id, 'd1');
      expect(up.clientOpId, expected.clientOpId);
      expect(up.updatedAt, expected.updatedAt);
      expect(up.json, expected.json);
    });

    test('delete crosses as a tombstone (never a hard-delete)', () async {
      await prefs.setBool(SyncService.decksDualWritePrefKey, true);
      await _service(db, prefs, backend: backend)
          .dualWriteDecks([_entry('gone', 'decks', 'delete')]);
      final push = backend.pushes.single;
      expect(push.upserts, isEmpty);
      expect(push.deletes.single.id, 'gone');
      expect(push.deletes.single.type, SyncEntityType.deck);
    });

    test('deck_move dual-write splits the composite id to fetch the row', () async {
      await db.decksDao.insertDeck(DecksCompanion.insert(id: 'd1', name: 'A'));
      await db.decksDao.addMoveToDeck('d1', 'm1');
      await prefs.setBool(SyncService.decksDualWritePrefKey, true);

      await _service(db, prefs, backend: backend)
          .dualWriteDeckMoves([_entry('d1:m1', 'deck_moves', 'create')]);

      final up = backend.pushes.single.upserts.single;
      expect(up.id, 'd1:m1');
      expect(up.json, {'deckId': 'd1', 'moveId': 'm1'});
    });

    test('push failure is swallowed (non-throwing, A1)', () async {
      await db.decksDao.insertDeck(DecksCompanion.insert(id: 'd1', name: 'A'));
      await prefs.setBool(SyncService.decksDualWritePrefKey, true);
      backend.throwOnPush = true;
      await _service(db, prefs, backend: backend)
          .dualWriteDecks([_entry('d1', 'decks', 'update')]);
    });
  });

  group('dual-read', () {
    test('disabled ⇒ null (Appwrite-only, nothing pulled)', () async {
      expect(await _service(db, prefs, backend: backend).pullDecksFromBackend(), isNull);
      await prefs.setBool(SyncService.decksDualReadPrefKey, true);
      expect(await _service(db, prefs).pullDecksFromBackend(), isNull); // null backend
    });

    test('deck LWW: newer remote applied, older remote skipped', () async {
      await prefs.setBool(SyncService.decksDualReadPrefKey, true);
      // Local deck at a known clock.
      await db.into(db.decks).insertOnConflictUpdate(DecksCompanion.insert(
            id: 'd1', name: 'Local',
            updatedAt: Value(DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true)),
          ));
      final older = DateTime.fromMillisecondsSinceEpoch(1600000000000, isUtc: true);
      final newer = DateTime.fromMillisecondsSinceEpoch(1800000000000, isUtc: true);
      backend.pullResults[SyncEntityType.deck] = SyncDelta(
        upserts: [_deckRec('d1', older, name: 'StaleRemote')],
        deletes: const [],
        cursor: newer,
      );
      var result = await _service(db, prefs, backend: backend).pullDecksFromBackend();
      expect(result!.applied, 0);
      expect((await db.decksDao.getById('d1'))!.name, 'Local');

      backend.pullResults[SyncEntityType.deck] = SyncDelta(
        upserts: [_deckRec('d1', newer, name: 'FreshRemote')],
        deletes: const [],
        cursor: newer,
      );
      result = await _service(db, prefs, backend: backend).pullDecksFromBackend();
      expect(result!.applied, 1);
      expect((await db.decksDao.getById('d1'))!.name, 'FreshRemote');
    });

    test('deck_move LWW insert-when-absent + own cursor advance', () async {
      await prefs.setBool(SyncService.decksDualReadPrefKey, true);
      final ts = DateTime.fromMillisecondsSinceEpoch(1700000500000, isUtc: true);
      backend.pullResults[SyncEntityType.deckMove] = SyncDelta(
        upserts: [_joinRec('d1', 'm1', ts)],
        deletes: const [],
        cursor: ts,
      );
      final result = await _service(db, prefs, backend: backend).pullDeckMovesFromBackend();
      expect(result!.applied, 1);
      final row = await (db.select(db.deckMoves)
            ..where((final t) => t.deckId.equals('d1') & t.moveId.equals('m1')))
          .getSingle();
      // Same instant (Drift reads DateTime back local-zoned).
      expect(row.updatedAt!.millisecondsSinceEpoch, ts.millisecondsSinceEpoch);
      expect(prefs.getInt(SyncService.deckMovesBackendCursorPrefKey),
          ts.millisecondsSinceEpoch);
    });

    test('independent cursors: deck vs deckMove drive their own `since`', () async {
      await prefs.setBool(SyncService.decksDualReadPrefKey, true);
      await prefs.setInt(SyncService.decksBackendCursorPrefKey, 111000);
      await prefs.setInt(SyncService.deckMovesBackendCursorPrefKey, 222000);
      final svc = _service(db, prefs, backend: backend);
      await svc.pullDecksFromBackend();
      await svc.pullDeckMovesFromBackend();
      expect(backend.lastSince[SyncEntityType.deck]!.millisecondsSinceEpoch, 111000);
      expect(backend.lastSince[SyncEntityType.deckMove]!.millisecondsSinceEpoch, 222000);
    });

    test('malformed record is isolated (counted, never aborts the batch)', () async {
      await prefs.setBool(SyncService.decksDualReadPrefKey, true);
      final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      final bad = SyncRecord(
        id: 'bad',
        type: SyncEntityType.deck,
        json: const {'deckType': 'smart'}, // missing name ⇒ decode throws
        updatedAt: ts,
        clientOpId: 'op:bad',
      );
      backend.pullResults[SyncEntityType.deck] = SyncDelta(
        upserts: [bad, _deckRec('good', ts)],
        deletes: const [],
      );
      final result = await _service(db, prefs, backend: backend).pullDecksFromBackend();
      expect(result!.failed, 1);
      expect(result.applied, 1);
      expect(await db.decksDao.getById('good'), isNotNull);
      expect(await db.decksDao.getById('bad'), isNull);
    });
  });
}
