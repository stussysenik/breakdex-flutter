/// Wave task 4.9 — `moveNoteEntries` + `comboNoteEntries` dual-write + dual-read
/// (Appwrite-only, D11).
///
/// Note entries have no Firestore leg, so the pair rides the shared LWW engines
/// (`_dualWriteEntity` / `_pullEntity`) exactly like the decks pair: pref-gated
/// upserts + tombstone-for-delete, non-throwing (A1), LWW-merge both directions,
/// inbound tombstone as a reversible soft-hide (idempotent replay), two
/// independent cursors under one pair kill-switch. Also proves the DAO's
/// sync-log hook (note entries bypass the SyncAware layer).
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/auth_service.dart';
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/codecs/note_entry_codec.dart';
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
  authService: AuthService(prefs),
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

SyncRecord _moveNoteRec(final String id, final DateTime ts, {final String body = 'Remote'}) =>
    SyncRecord(
      id: id,
      type: SyncEntityType.moveNoteEntry,
      json: {'moveId': 'm1', 'body': body, 'createdAt': ts.millisecondsSinceEpoch},
      updatedAt: ts,
      clientOpId: 'op:$id',
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

  group('DAO sync-log hook (note entries bypass SyncAware)', () {
    test('move + combo note mutations enqueue sync_log entries', () async {
      await db.moveNoteEntriesDao.addEntry(id: 'mn1', moveId: 'm1', body: 'a');
      await db.moveNoteEntriesDao.updateEntry('mn1', 'a2');
      await db.moveNoteEntriesDao.deleteEntry('mn1');
      await db.comboNoteEntriesDao
          .addEntry(id: 'cn1', comboId: 'c1', body: 'b');
      await db.comboNoteEntriesDao.deleteEntry('cn1');

      final pending = await db.syncDao.getPendingChanges();
      final moveNotes = pending
          .where((final e) => e.entityTable == 'move_note_entries')
          .toList();
      final comboNotes = pending
          .where((final e) => e.entityTable == 'combo_note_entries')
          .toList();
      expect(moveNotes.map((final e) => e.action).toSet(),
          {'create', 'update', 'delete'});
      expect(comboNotes.map((final e) => e.action).toSet(),
          {'create', 'delete'});
    });
  });

  group('dual-write', () {
    test('pref OFF ⇒ no push', () async {
      await db.moveNoteEntriesDao.addEntry(id: 'mn1', moveId: 'm1', body: 'a');
      await _service(db, prefs, backend: backend)
          .dualWriteMoveNoteEntries([_entry('mn1', 'move_note_entries', 'create')]);
      expect(backend.pushes, isEmpty);
    });

    test('pref ON ⇒ byte-identical move note upsert', () async {
      await db.moveNoteEntriesDao.addEntry(id: 'mn1', moveId: 'm1', body: 'a');
      await prefs.setBool(SyncService.noteEntriesDualWritePrefKey, true);
      final expected =
          moveNoteEntryToSyncRecord((await db.moveNoteEntriesDao.getById('mn1'))!);

      await _service(db, prefs, backend: backend)
          .dualWriteMoveNoteEntries([_entry('mn1', 'move_note_entries', 'update')]);

      final push = backend.pushes.single;
      expect(push.type, SyncEntityType.moveNoteEntry);
      final up = push.upserts.single;
      expect(up.id, 'mn1');
      expect(up.clientOpId, expected.clientOpId);
      expect(up.updatedAt, expected.updatedAt);
      expect(up.json, expected.json);
    });

    test('combo note dual-write carries kind + video refs', () async {
      await db.comboNoteEntriesDao.addEntry(
        id: 'cn1',
        comboId: 'c1',
        body: 'take',
        kind: 'status',
        videoPath: 'Moves/x.mp4',
        videoHash: 'sha:abc',
      );
      await prefs.setBool(SyncService.noteEntriesDualWritePrefKey, true);

      await _service(db, prefs, backend: backend).dualWriteComboNoteEntries(
          [_entry('cn1', 'combo_note_entries', 'create')]);

      final up = backend.pushes.single.upserts.single;
      expect(up.id, 'cn1');
      expect(up.json['kind'], 'status');
      expect(up.json['videoPath'], 'Moves/x.mp4');
      expect(up.json['videoHash'], 'sha:abc');
    });

    test('delete crosses as a tombstone (never a hard-delete)', () async {
      await prefs.setBool(SyncService.noteEntriesDualWritePrefKey, true);
      await _service(db, prefs, backend: backend).dualWriteMoveNoteEntries(
          [_entry('gone', 'move_note_entries', 'delete')]);
      final push = backend.pushes.single;
      expect(push.upserts, isEmpty);
      expect(push.deletes.single.id, 'gone');
      expect(push.deletes.single.type, SyncEntityType.moveNoteEntry);
    });

    test('push failure is swallowed (non-throwing, A1)', () async {
      await db.moveNoteEntriesDao.addEntry(id: 'mn1', moveId: 'm1', body: 'a');
      await prefs.setBool(SyncService.noteEntriesDualWritePrefKey, true);
      backend.throwOnPush = true;
      await _service(db, prefs, backend: backend)
          .dualWriteMoveNoteEntries([_entry('mn1', 'move_note_entries', 'update')]);
    });
  });

  group('dual-read', () {
    test('disabled ⇒ null (both pref-off and null-backend)', () async {
      expect(
          await _service(db, prefs, backend: backend)
              .pullMoveNoteEntriesFromBackend(),
          isNull);
      await prefs.setBool(SyncService.noteEntriesDualReadPrefKey, true);
      expect(await _service(db, prefs).pullMoveNoteEntriesFromBackend(), isNull);
    });

    test('move note LWW: newer remote applied, older remote skipped', () async {
      await prefs.setBool(SyncService.noteEntriesDualReadPrefKey, true);
      await db.into(db.moveNoteEntries).insertOnConflictUpdate(
            MoveNoteEntriesCompanion.insert(
              id: 'mn1',
              moveId: 'm1',
              body: 'Local',
              updatedAt: Value(
                  DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true)),
            ),
          );
      final older =
          DateTime.fromMillisecondsSinceEpoch(1600000000000, isUtc: true);
      final newer =
          DateTime.fromMillisecondsSinceEpoch(1800000000000, isUtc: true);

      backend.pullResults[SyncEntityType.moveNoteEntry] = SyncDelta(
        upserts: [_moveNoteRec('mn1', older, body: 'Stale')],
        deletes: const [],
        cursor: newer,
      );
      var result = await _service(db, prefs, backend: backend)
          .pullMoveNoteEntriesFromBackend();
      expect(result!.applied, 0);
      expect((await db.moveNoteEntriesDao.getById('mn1'))!.body, 'Local');

      backend.pullResults[SyncEntityType.moveNoteEntry] = SyncDelta(
        upserts: [_moveNoteRec('mn1', newer, body: 'Fresh')],
        deletes: const [],
        cursor: newer,
      );
      result = await _service(db, prefs, backend: backend)
          .pullMoveNoteEntriesFromBackend();
      expect(result!.applied, 1);
      expect((await db.moveNoteEntriesDao.getById('mn1'))!.body, 'Fresh');
    });

    test('inbound tombstone soft-hides (never hard-delete) + idempotent replay',
        () async {
      await prefs.setBool(SyncService.noteEntriesDualReadPrefKey, true);
      final local =
          DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      final del = DateTime.fromMillisecondsSinceEpoch(1800000000000, isUtc: true);
      await db.into(db.moveNoteEntries).insertOnConflictUpdate(
            MoveNoteEntriesCompanion.insert(
              id: 'mn1',
              moveId: 'm1',
              body: 'Local',
              updatedAt: Value(local),
            ),
          );

      final tomb = SyncDelta(upserts: const [], deletes: [
        SyncTombstone(
            id: 'mn1',
            type: SyncEntityType.moveNoteEntry,
            deletedAt: del,
            clientOpId: 'op:del'),
      ], cursor: del);

      backend.pullResults[SyncEntityType.moveNoteEntry] = tomb;
      var result = await _service(db, prefs, backend: backend)
          .pullMoveNoteEntriesFromBackend();
      expect(result!.applied, 1);
      // Row survives (not hard-deleted), but is hidden from feeds.
      final row = await db.moveNoteEntriesDao.getById('mn1');
      expect(row, isNotNull);
      expect(row!.deletedAt, isNotNull);
      expect(await db.moveNoteEntriesDao.getByMoveId('m1'), isEmpty);

      // Replay the same tombstone ⇒ no-op (already hidden).
      backend.pullResults[SyncEntityType.moveNoteEntry] = tomb;
      result = await _service(db, prefs, backend: backend)
          .pullMoveNoteEntriesFromBackend();
      expect(result!.applied, 0);
    });

    test('tombstone LWW guard: a strictly-newer local edit survives the delete',
        () async {
      await prefs.setBool(SyncService.noteEntriesDualReadPrefKey, true);
      final del = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      final localNewer =
          DateTime.fromMillisecondsSinceEpoch(1800000000000, isUtc: true);
      await db.into(db.moveNoteEntries).insertOnConflictUpdate(
            MoveNoteEntriesCompanion.insert(
              id: 'mn1',
              moveId: 'm1',
              body: 'Local',
              updatedAt: Value(localNewer),
            ),
          );
      backend.pullResults[SyncEntityType.moveNoteEntry] = SyncDelta(
        upserts: const [],
        deletes: [
          SyncTombstone(
              id: 'mn1',
              type: SyncEntityType.moveNoteEntry,
              deletedAt: del,
              clientOpId: 'op:del'),
        ],
      );
      final result = await _service(db, prefs, backend: backend)
          .pullMoveNoteEntriesFromBackend();
      expect(result!.applied, 0);
      expect((await db.moveNoteEntriesDao.getById('mn1'))!.deletedAt, isNull);
    });

    test('independent cursors: move vs combo note drive their own `since`',
        () async {
      await prefs.setBool(SyncService.noteEntriesDualReadPrefKey, true);
      await prefs.setInt(
          SyncService.moveNoteEntriesBackendCursorPrefKey, 111000);
      await prefs.setInt(
          SyncService.comboNoteEntriesBackendCursorPrefKey, 222000);
      final svc = _service(db, prefs, backend: backend);
      await svc.pullMoveNoteEntriesFromBackend();
      await svc.pullComboNoteEntriesFromBackend();
      expect(
          backend.lastSince[SyncEntityType.moveNoteEntry]!.millisecondsSinceEpoch,
          111000);
      expect(
          backend.lastSince[SyncEntityType.comboNoteEntry]!.millisecondsSinceEpoch,
          222000);
    });

    test('malformed record is isolated (counted, never aborts the batch)',
        () async {
      await prefs.setBool(SyncService.noteEntriesDualReadPrefKey, true);
      final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      final bad = SyncRecord(
        id: 'bad',
        type: SyncEntityType.moveNoteEntry,
        json: const {'moveId': 'm1'}, // missing body ⇒ decode throws
        updatedAt: ts,
        clientOpId: 'op:bad',
      );
      backend.pullResults[SyncEntityType.moveNoteEntry] = SyncDelta(
        upserts: [bad, _moveNoteRec('good', ts)],
        deletes: const [],
      );
      final result = await _service(db, prefs, backend: backend)
          .pullMoveNoteEntriesFromBackend();
      expect(result!.failed, 1);
      expect(result.applied, 1);
      expect(await db.moveNoteEntriesDao.getById('good'), isNotNull);
      expect(await db.moveNoteEntriesDao.getById('bad'), isNull);
    });
  });
}
