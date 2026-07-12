/// Wave task 4.4 — `combos` + `combo_moves` dual-write + dual-read.
///
/// The pair reuses the moves strangler engines (`_dualWriteEntity`/`_pullEntity`),
/// so these tests prove what differs: the codec projections, the shared
/// pair kill-switches, the two independent cursors, and LWW on both tables.
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/auth_service.dart';
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/codecs/combo_codec.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import '../../helpers/test_database.dart';

class _FakeBackend implements SyncBackend {
  final List<
    ({
      SyncEntityType type,
      List<SyncRecord> upserts,
      List<SyncTombstone> deletes,
    })
  >
  pushes = [];
  bool throwOnPush = false;

  final Map<SyncEntityType, SyncDelta> pullResults = {};
  final Map<SyncEntityType, DateTime?> lastSince = {};
  Object? throwOnPull;

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
  Future<SyncDelta> pull(
    final SyncEntityType type, {
    final DateTime? since,
  }) async {
    lastSince[type] = since;
    final err = throwOnPull;
    // ignore: only_throw_errors
    if (err != null) throw err;
    return pullResults[type] ?? const SyncDelta(upserts: [], deletes: []);
  }

  @override
  Stream<SyncDelta> subscribe(final SyncEntityType type) =>
      const Stream.empty();
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

SyncLogData _entry(final String table, final String id, final String action) =>
    SyncLogData(
      entityTable: table,
      entityId: id,
      action: action,
      changedAt: DateTime.utc(2026),
      synced: false,
      videoSynced: false,
    );

/// Insert a combo directly (bypassing the DAO stamp) so a test controls the
/// clock exactly for LWW assertions.
Future<void> _insertCombo(
  final AppDatabase db,
  final String id,
  final DateTime ts,
) => db
    .into(db.combos)
    .insert(
      CombosCompanion.insert(
        id: id,
        name: 'Combo $id',
        createdAt: Value(ts),
        updatedAt: Value(ts),
      ),
    );

Future<void> _insertStep(
  final AppDatabase db,
  final String id,
  final DateTime ts,
) => db
    .into(db.comboMoves)
    .insert(
      ComboMovesCompanion.insert(
        id: id,
        comboId: 'c1',
        moveId: 'm1',
        sequenceIndex: 0,
        updatedAt: Value(ts),
      ),
    );

SyncRecord _comboUpsert(
  final String id,
  final String name,
  final DateTime ts,
) => SyncRecord(
  id: id,
  type: SyncEntityType.combo,
  json: {
    'name': name,
    'notes': null,
    'activeVideoPath': null,
    'contentHash': null,
    'status': 'idea',
    'createdAt': ts.millisecondsSinceEpoch,
  },
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

  group('dual-write', () {
    test('pref OFF ⇒ no push for either entity', () async {
      await db.combosDao.insertCombo(
        CombosCompanion.insert(id: 'c1', name: 'A'),
      );
      final svc = _service(db, prefs, backend: backend);
      await svc.dualWriteCombos([_entry('combos', 'c1', 'insert')]);
      await svc.dualWriteComboMoves([_entry('combo_moves', 'cm1', 'insert')]);
      expect(backend.pushes, isEmpty);
    });

    test('no backend wired ⇒ no-op (must not throw)', () async {
      await prefs.setBool(SyncService.combosDualWritePrefKey, true);
      await _service(
        db,
        prefs,
      ).dualWriteCombos([_entry('combos', 'c1', 'insert')]);
    });

    test('pref ON ⇒ byte-identical combo upsert', () async {
      await db.combosDao.insertCombo(
        CombosCompanion.insert(id: 'c1', name: 'A'),
      );
      await prefs.setBool(SyncService.combosDualWritePrefKey, true);
      final expected = comboToSyncRecord(await db.combosDao.getById('c1'));

      await _service(
        db,
        prefs,
        backend: backend,
      ).dualWriteCombos([_entry('combos', 'c1', 'insert')]);

      final push = backend.pushes.single;
      expect(push.type, SyncEntityType.combo);
      final up = push.upserts.single;
      expect(up.id, 'c1');
      expect(up.clientOpId, expected.clientOpId);
      expect(up.updatedAt, expected.updatedAt);
      expect(up.json, expected.json);
    });

    test('pref ON ⇒ byte-identical comboMove upsert', () async {
      await db.combosDao.insertCombo(
        CombosCompanion.insert(id: 'c1', name: 'A'),
      );
      await db.combosDao.addMoveToCombo(
        ComboMovesCompanion.insert(
          id: 'cm1',
          comboId: 'c1',
          moveId: 'm1',
          sequenceIndex: 0,
        ),
      );
      await prefs.setBool(SyncService.combosDualWritePrefKey, true);
      final step = await (db.select(
        db.comboMoves,
      )..where((final t) => t.id.equals('cm1'))).getSingle();
      final expected = comboMoveToSyncRecord(step);

      await _service(
        db,
        prefs,
        backend: backend,
      ).dualWriteComboMoves([_entry('combo_moves', 'cm1', 'insert')]);

      final push = backend.pushes.single;
      expect(push.type, SyncEntityType.comboMove);
      final up = push.upserts.single;
      expect(up.clientOpId, expected.clientOpId);
      expect(up.updatedAt, expected.updatedAt);
      expect(up.json, expected.json);
    });

    test('delete entry ⇒ tombstone, never a hard-delete', () async {
      await prefs.setBool(SyncService.combosDualWritePrefKey, true);
      await _service(
        db,
        prefs,
        backend: backend,
      ).dualWriteComboMoves([_entry('combo_moves', 'gone', 'delete')]);
      final push = backend.pushes.single;
      expect(push.upserts, isEmpty);
      expect(push.deletes.single.id, 'gone');
      expect(push.deletes.single.type, SyncEntityType.comboMove);
    });

    test('push failure is swallowed (never blocks Firestore)', () async {
      await db.combosDao.insertCombo(
        CombosCompanion.insert(id: 'c1', name: 'A'),
      );
      await prefs.setBool(SyncService.combosDualWritePrefKey, true);
      backend.throwOnPush = true;
      await _service(
        db,
        prefs,
        backend: backend,
      ).dualWriteCombos([_entry('combos', 'c1', 'insert')]);
    });
  });

  group('dual-read', () {
    test('disabled ⇒ null (falls back to Firestore)', () async {
      final svc = _service(db, prefs, backend: backend);
      expect(await svc.pullCombosFromBackend(), isNull);
      expect(await svc.pullComboMovesFromBackend(), isNull);
      // Null backend too.
      await prefs.setBool(SyncService.combosDualReadPrefKey, true);
      expect(await _service(db, prefs).pullCombosFromBackend(), isNull);
    });

    test('combo: strictly-newer remote wins; tie/older keeps local', () async {
      await prefs.setBool(SyncService.combosDualReadPrefKey, true);
      final t1 = DateTime.fromMillisecondsSinceEpoch(
        1700000000000,
        isUtc: true,
      );
      final t2 = DateTime.fromMillisecondsSinceEpoch(
        1700000100000,
        isUtc: true,
      );
      await _insertCombo(db, 'c1', t1); // local at t1
      await _insertCombo(db, 'c2', t2); // local at t2
      backend.pullResults[SyncEntityType.combo] = SyncDelta(
        upserts: [
          _comboUpsert('c1', 'RemoteNewer', t2), // newer → wins
          _comboUpsert('c2', 'RemoteOlder', t1), // older → keep local
        ],
        deletes: const [],
        cursor: t2,
      );

      final result = await _service(
        db,
        prefs,
        backend: backend,
      ).pullCombosFromBackend();
      expect(result!.applied, 1);
      expect((await db.combosDao.getById('c1')).name, 'RemoteNewer');
      expect((await db.combosDao.getById('c2')).name, 'Combo c2');
      // Combo cursor advanced.
      expect(
        prefs.getInt(SyncService.combosBackendCursorPrefKey),
        t2.millisecondsSinceEpoch,
      );
    });

    test('comboMove: strictly-newer remote wins', () async {
      await prefs.setBool(SyncService.combosDualReadPrefKey, true);
      final t1 = DateTime.fromMillisecondsSinceEpoch(
        1700000000000,
        isUtc: true,
      );
      final t2 = DateTime.fromMillisecondsSinceEpoch(
        1700000100000,
        isUtc: true,
      );
      await _insertStep(db, 'cm1', t1);
      backend.pullResults[SyncEntityType.comboMove] = SyncDelta(
        upserts: [
          SyncRecord(
            id: 'cm1',
            type: SyncEntityType.comboMove,
            json: const {
              'comboId': 'c1',
              'moveId': 'm2',
              'sequenceIndex': 9,
              'count': 3,
            },
            updatedAt: t2,
            clientOpId: 'op:cm1',
          ),
        ],
        deletes: const [],
        cursor: t2,
      );

      final result = await _service(
        db,
        prefs,
        backend: backend,
      ).pullComboMovesFromBackend();
      expect(result!.applied, 1);
      final step = await (db.select(
        db.comboMoves,
      )..where((final t) => t.id.equals('cm1'))).getSingle();
      expect(step.sequenceIndex, 9);
      expect(step.count, 3);
      expect(
        prefs.getInt(SyncService.comboMovesBackendCursorPrefKey),
        t2.millisecondsSinceEpoch,
      );
    });

    test('the pair uses independent cursors', () async {
      await prefs.setBool(SyncService.combosDualReadPrefKey, true);
      await prefs.setInt(SyncService.combosBackendCursorPrefKey, 111000);
      await prefs.setInt(SyncService.comboMovesBackendCursorPrefKey, 222000);
      final svc = _service(db, prefs, backend: backend);
      await svc.pullCombosFromBackend();
      await svc.pullComboMovesFromBackend();
      expect(
        backend.lastSince[SyncEntityType.combo]!.millisecondsSinceEpoch,
        111000,
      );
      expect(
        backend.lastSince[SyncEntityType.comboMove]!.millisecondsSinceEpoch,
        222000,
      );
    });

    test(
      'malformed record is isolated (counted, never aborts the batch)',
      () async {
        await prefs.setBool(SyncService.combosDualReadPrefKey, true);
        final ts = DateTime.fromMillisecondsSinceEpoch(
          1700000000000,
          isUtc: true,
        );
        backend.pullResults[SyncEntityType.combo] = SyncDelta(
          upserts: [
            SyncRecord(
              id: 'bad',
              type: SyncEntityType.combo,
              json: const {'notes': 'no name field'}, // decode throws
              updatedAt: ts,
              clientOpId: 'op:bad',
            ),
            _comboUpsert('good', 'Good', ts), // still applied
          ],
          deletes: const [],
        );

        final result = await _service(
          db,
          prefs,
          backend: backend,
        ).pullCombosFromBackend();
        expect(result!.failed, 1);
        expect(result.applied, 1);
        expect((await db.combosDao.getById('good')).name, 'Good');
      },
    );
  });
}
