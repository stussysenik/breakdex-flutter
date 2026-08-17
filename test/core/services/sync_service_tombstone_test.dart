/// Wave task 4.8 — inbound tombstones end-to-end (the delete-sync "magic").
///
/// A delete on device A crosses as a [SyncTombstone]; device B applies it as a
/// reversible soft-hide (`deletedAt`), never a hard-delete, so a delete
/// elsewhere never destroys videos/rows. These tests prove, per entity: the row
/// is hidden from every read path but preserved on disk; replay is idempotent;
/// a strictly-newer local edit keeps the row (LWW); an absent row is a no-op;
/// and a create+delete in one delta ends hidden.
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import '../../helpers/test_database.dart';

class _FakeBackend implements SyncBackend {
  final Map<SyncEntityType, SyncDelta> pullResults = {};

  @override
  String get providerType => 'fake';

  @override
  Future<void> push(
    final SyncEntityType type, {
    final List<SyncRecord> upserts = const [],
    final List<SyncTombstone> deletes = const [],
  }) async {}

  @override
  Future<SyncDelta> pull(
    final SyncEntityType type, {
    final DateTime? since,
  }) async =>
      pullResults[type] ?? const SyncDelta(upserts: [], deletes: []);

  @override
  Stream<SyncDelta> subscribe(final SyncEntityType type) =>
      const Stream.empty();
}

SyncService _service(
  final AppDatabase db,
  final SharedPreferences prefs,
  final SyncBackend backend,
) =>
    SyncService(

      syncDao: db.syncDao,
      db: db,
      prefs: prefs,
      syncBackend: backend,
    );

final _t0 = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
final _tDelete = DateTime.fromMillisecondsSinceEpoch(1700000100000, isUtc: true);
final _tNewerEdit =
    DateTime.fromMillisecondsSinceEpoch(1700000200000, isUtc: true);

SyncTombstone _tombstone(
  final String id,
  final SyncEntityType type, [
  final DateTime? at,
]) =>
    SyncTombstone(
      id: id,
      type: type,
      deletedAt: at ?? _tDelete,
      clientOpId: 'op:delete:$id',
    );

SyncDelta _deleteDelta(final SyncTombstone t) =>
    SyncDelta(upserts: const [], deletes: [t], cursor: _tDelete);

Future<void> _insertMove(
  final AppDatabase db,
  final String id, {
  final DateTime? updatedAt,
  final String video = 'videos/keep.mp4',
}) =>
    db.into(db.moves).insert(MovesCompanion.insert(
          id: id,
          name: 'Move $id',
          videoPath: Value(video),
          createdAt: Value(_t0),
          updatedAt: Value(updatedAt),
        ));

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late _FakeBackend backend;
  late SyncService svc;

  setUp(() async {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    backend = _FakeBackend();
    svc = _service(db, prefs, backend);
    await prefs.setBool(SyncService.movesDualReadPrefKey, true);
    await prefs.setBool(SyncService.combosDualReadPrefKey, true);
    await prefs.setBool(SyncService.decksDualReadPrefKey, true);
  });

  tearDown(() => db.close());

  group('move tombstone', () {
    test('hides the row + preserves the video bytes; feeds exclude it', () async {
      await _insertMove(db, 'm1');
      backend.pullResults[SyncEntityType.move] =
          _deleteDelta(_tombstone('m1', SyncEntityType.move));

      final result = await svc.pullMovesFromBackend();

      expect(result!.applied, 1);
      // Row is NOT destroyed — still on disk with its video path, just flagged.
      final row = await (db.select(db.moves)
            ..where((final t) => t.id.equals('m1')))
          .getSingle();
      expect(row.deletedAt, isNotNull);
      expect(row.videoPath, 'videos/keep.mp4');
      // But every browse feed hides it.
      expect(await db.movesDao.getAll(), isEmpty);
      expect(await db.movesDao.getArchived(), isEmpty);
      expect(await db.movesDao.watchAll().first, isEmpty);
    });

    test('replay is idempotent — second apply is a no-op', () async {
      await _insertMove(db, 'm1');
      backend.pullResults[SyncEntityType.move] =
          _deleteDelta(_tombstone('m1', SyncEntityType.move));

      final first = await svc.pullMovesFromBackend();
      // Reset the cursor so the same delta is re-pulled, not skipped.
      await prefs.remove(SyncService.movesBackendCursorPrefKey);
      final second = await svc.pullMovesFromBackend();

      expect(first!.applied, 1);
      expect(second!.applied, 0); // already hidden → no-op
      expect(await db.movesDao.getAll(), isEmpty);
    });

    test('LWW: a strictly-newer local edit keeps the row visible', () async {
      // Local edited AFTER the delete's clock — the user re-touched it.
      await _insertMove(db, 'm1', updatedAt: _tNewerEdit);
      backend.pullResults[SyncEntityType.move] =
          _deleteDelta(_tombstone('m1', SyncEntityType.move));

      final result = await svc.pullMovesFromBackend();

      expect(result!.applied, 0);
      expect(await db.movesDao.getAll(), hasLength(1));
    });

    test('absent row is a no-op (delete arrived before any create)', () async {
      backend.pullResults[SyncEntityType.move] =
          _deleteDelta(_tombstone('ghost', SyncEntityType.move));
      final result = await svc.pullMovesFromBackend();
      expect(result!.applied, 0);
    });

    test('create + delete in one delta ends hidden (upserts merge first)',
        () async {
      backend.pullResults[SyncEntityType.move] = SyncDelta(
        upserts: [
          SyncRecord(
            id: 'm1',
            type: SyncEntityType.move,
            json: {
              'name': 'Ephemeral',
              'learningState': 'NEW',
              'category': 'default',
              'videoPath': 'videos/keep.mp4',
              'count': 4,
              'createdAt': _t0.millisecondsSinceEpoch,
            },
            updatedAt: _t0,
            clientOpId: 'op:m1',
          ),
        ],
        deletes: [_tombstone('m1', SyncEntityType.move)],
        cursor: _tDelete,
      );

      final result = await svc.pullMovesFromBackend();

      expect(result!.applied, 2); // one upsert + one hide
      expect(await db.movesDao.getAll(), isEmpty);
      // Row still exists (hidden), proving the video bytes survive.
      final row = await (db.select(db.moves)
            ..where((final t) => t.id.equals('m1')))
          .getSingleOrNull();
      expect(row, isNotNull);
      expect(row!.deletedAt, isNotNull);
    });
  });

  test('combo tombstone hides the combo; getAll/watchAll exclude it', () async {
    await db.into(db.combos).insert(CombosCompanion.insert(
          id: 'c1',
          name: 'Windmill combo',
          createdAt: Value(_t0),
          updatedAt: Value(_t0),
        ));
    backend.pullResults[SyncEntityType.combo] =
        _deleteDelta(_tombstone('c1', SyncEntityType.combo));

    final result = await svc.pullCombosFromBackend();

    expect(result!.applied, 1);
    expect(await db.combosDao.getAll(), isEmpty);
    expect(await db.combosDao.watchAll().first, isEmpty);
    // Preserved on disk.
    final row = await (db.select(db.combos)
          ..where((final t) => t.id.equals('c1')))
        .getSingle();
    expect(row.deletedAt, isNotNull);
    expect(row.name, 'Windmill combo');
  });

  test('comboMove tombstone hides the step; watchComboMoves excludes it',
      () async {
    await db.into(db.combos).insert(CombosCompanion.insert(
          id: 'c1',
          name: 'C',
          createdAt: Value(_t0),
          updatedAt: Value(_t0),
        ));
    await _insertMove(db, 'm1');
    await db.into(db.comboMoves).insert(ComboMovesCompanion.insert(
          id: 'cm1',
          comboId: 'c1',
          moveId: 'm1',
          sequenceIndex: 0,
          updatedAt: Value(_t0),
        ));
    backend.pullResults[SyncEntityType.comboMove] =
        _deleteDelta(_tombstone('cm1', SyncEntityType.comboMove));

    final result = await svc.pullComboMovesFromBackend();

    expect(result!.applied, 1);
    expect(await db.combosDao.watchComboMoves('c1').first, isEmpty);
  });

  test('deck tombstone hides the deck; watchAll excludes it', () async {
    await db.into(db.decks).insert(DecksCompanion.insert(
          id: 'd1',
          name: 'Study deck',
          updatedAt: Value(_t0),
        ));
    backend.pullResults[SyncEntityType.deck] =
        _deleteDelta(_tombstone('d1', SyncEntityType.deck));

    final result = await svc.pullDecksFromBackend();

    expect(result!.applied, 1);
    expect(await db.decksDao.getAll(), isEmpty);
    expect(await db.decksDao.watchAll().first, isEmpty);
  });

  test('deckMove tombstone (composite wire id) hides the join row', () async {
    await db.into(db.decks).insert(DecksCompanion.insert(
          id: 'd1',
          name: 'D',
          updatedAt: Value(_t0),
        ));
    await _insertMove(db, 'm1');
    await db.into(db.deckMoves).insert(DeckMovesCompanion.insert(
          deckId: 'd1',
          moveId: 'm1',
          updatedAt: Value(_t0),
        ));
    // Wire id is the composite 'deckId:moveId'.
    backend.pullResults[SyncEntityType.deckMove] =
        _deleteDelta(_tombstone('d1:m1', SyncEntityType.deckMove));

    final result = await svc.pullDeckMovesFromBackend();

    expect(result!.applied, 1);
    expect(await db.decksDao.getMovesForDeck('d1'), isEmpty);
    expect(await db.decksDao.getMoveIdsForDeck('d1'), isEmpty);
  });
}
