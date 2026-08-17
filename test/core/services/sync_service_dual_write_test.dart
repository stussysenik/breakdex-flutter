/// Wave task 4.2 — `moves` dual-write to the Appwrite shadow.
///
/// `SyncService.dualWriteMoves` is extracted from `pushMetadata` (which touches
/// `FirebaseFirestore.instance`) precisely so it is provable offline: pref-gated,
/// idempotent, tombstone-for-delete, and non-throwing so it never blocks the
/// Firestore flush that already committed.
library;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/codecs/move_codec.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

/// Captures pushes; can be made to throw to prove the swallow.
class _FakeBackend implements SyncBackend {
  final List<({List<SyncRecord> upserts, List<SyncTombstone> deletes})> pushes =
      [];
  bool throwOnPush = false;

  @override
  String get providerType => 'fake';

  @override
  Future<void> push(
    final SyncEntityType type, {
    final List<SyncRecord> upserts = const [],
    final List<SyncTombstone> deletes = const [],
  }) async {
    if (throwOnPush) throw StateError('backend down');
    pushes.add((upserts: upserts, deletes: deletes));
  }

  @override
  Future<SyncDelta> pull(final SyncEntityType type, {final DateTime? since}) async =>
      const SyncDelta(upserts: [], deletes: []);

  @override
  Stream<SyncDelta> subscribe(final SyncEntityType type) => const Stream.empty();
}

SyncService _service(
  final AppDatabase db,
  final SharedPreferences prefs, {
  final SyncBackend? backend,
}) =>
    SyncService(

      syncDao: db.syncDao,
      db: db,
      prefs: prefs,
      syncBackend: backend,
    );

SyncLogData _entry(final String id, final String action) => SyncLogData(
      entityTable: 'moves',
      entityId: id,
      action: action,
      changedAt: DateTime.utc(2026),
      synced: false,
      videoSynced: false,
    );

Future<void> _seedMove(final AppDatabase db, final String id) =>
    db.movesDao.insertMove(MovesCompanion.insert(id: id, name: 'Move $id'));

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

  test('pref OFF ⇒ no push (Firestore-only, byte-identical)', () async {
    await _seedMove(db, 'm1');
    await _service(db, prefs, backend: backend)
        .dualWriteMoves([_entry('m1', 'insert')]);
    expect(backend.pushes, isEmpty);
  });

  test('no backend wired ⇒ no-op', () async {
    await _seedMove(db, 'm1');
    await prefs.setBool(SyncService.movesDualWritePrefKey, true);
    // Must not throw despite a null backend.
    await _service(db, prefs).dualWriteMoves([_entry('m1', 'insert')]);
  });

  test('pref ON ⇒ upserts the move as a byte-identical SyncRecord', () async {
    await _seedMove(db, 'm1');
    await prefs.setBool(SyncService.movesDualWritePrefKey, true);
    final expected = moveToSyncRecord(await db.movesDao.getById('m1'));

    await _service(db, prefs, backend: backend)
        .dualWriteMoves([_entry('m1', 'insert')]);

    expect(backend.pushes, hasLength(1));
    final up = backend.pushes.single.upserts.single;
    expect(up.id, 'm1');
    expect(up.clientOpId, expected.clientOpId);
    expect(up.updatedAt, expected.updatedAt);
    expect(up.json, expected.json);
    expect(backend.pushes.single.deletes, isEmpty);
  });

  test('delete entry ⇒ tombstone, never a hard-delete', () async {
    await prefs.setBool(SyncService.movesDualWritePrefKey, true);
    await _service(db, prefs, backend: backend)
        .dualWriteMoves([_entry('gone', 'delete')]);

    expect(backend.pushes, hasLength(1));
    expect(backend.pushes.single.upserts, isEmpty);
    final tomb = backend.pushes.single.deletes.single;
    expect(tomb.id, 'gone');
    expect(tomb.type, SyncEntityType.move);
  });

  test('backend push failure is swallowed (never blocks Firestore)', () async {
    await _seedMove(db, 'm1');
    await prefs.setBool(SyncService.movesDualWritePrefKey, true);
    backend.throwOnPush = true;
    // Completes normally despite the backend throwing.
    await _service(db, prefs, backend: backend)
        .dualWriteMoves([_entry('m1', 'insert')]);
  });
}
