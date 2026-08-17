import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/codecs/move_codec.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import '../../helpers/test_database.dart';

/// Serves a canned [SyncDelta] on [pull]; records nothing else. No live
/// deployment — this proves the dual-read merge logic in isolation.
class _FakeBackend implements SyncBackend {
  SyncDelta pullResult = const SyncDelta(upserts: [], deletes: []);
  int pullCalls = 0;

  /// The `since` the last [pull] was called with — proves the cursor plumbing.
  DateTime? lastSince;

  /// When set, [pull] throws it — proves failures propagate cleanly.
  Object? throwOnPull;

  @override
  String get providerType => 'fake';

  @override
  Future<SyncDelta> pull(final SyncEntityType type, {final DateTime? since}) async {
    pullCalls++;
    lastSince = since;
    final err = throwOnPull;
    // The fake rethrows the caller-supplied error object verbatim to simulate
    // an arbitrary backend failure.
    // ignore: only_throw_errors
    if (err != null) throw err;
    return pullResult;
  }

  @override
  Future<void> push(
    final SyncEntityType type, {
    final List<SyncRecord> upserts = const [],
    final List<SyncTombstone> deletes = const [],
  }) async {}

  @override
  Stream<SyncDelta> subscribe(final SyncEntityType type) => const Stream.empty();
}

/// Insert a move directly (bypassing the DAO stamp) so a test controls
/// [Moves.updatedAt] exactly for last-writer-wins assertions.
Future<void> _insertMove(
  final AppDatabase db, {
  required final String id,
  required final String name,
  required final DateTime updatedAt,
}) async {
  await db.into(db.moves).insert(MovesCompanion.insert(
        id: id,
        name: name,
        createdAt: Value(updatedAt),
        updatedAt: Value(updatedAt),
      ));
}

SyncRecord _moveUpsert(
  final String id,
  final String name,
  final DateTime updatedAt,
) =>
    SyncRecord(
      id: id,
      type: SyncEntityType.move,
      json: {
        'name': name,
        'learningState': 'NEW',
        'category': 'default',
        'count': 4,
        'createdAt': updatedAt.millisecondsSinceEpoch,
      },
      updatedAt: updatedAt,
      clientOpId: 'op:$id',
    );

/// A record whose payload omits the required `name` — decoding throws, so it
/// exercises the per-record fault isolation (H.3) without a real DB error.
SyncRecord _malformedUpsert(final String id) => SyncRecord(
      id: id,
      type: SyncEntityType.move,
      json: const {'category': 'default'}, // no name/learningState/createdAt
      updatedAt: DateTime.utc(2026),
      clientOpId: 'op:$id',
    );

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late _FakeBackend backend;

  SyncService service({final SyncBackend? withBackend}) => SyncService(

        syncDao: db.syncDao,
        db: db,
        prefs: prefs,
        syncBackend: withBackend,
      );

  setUp(() async {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    backend = _FakeBackend();
  });

  tearDown(() async => db.close());

  group('moveFromSyncRecord — inverse of moveToSyncJson', () {
    test('round-trips every field, including BigInt videoFileSize', () async {
      final created = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      await db.into(db.moves).insert(MovesCompanion.insert(
            id: 'rt-1',
            name: 'Windmill',
            learningState: const Value('LEARNING'),
            category: const Value('power'),
            videoPath: const Value('Moves/rt-1.mp4'),
            originalVideoName: const Value('IMG_0001.mov'),
            notes: const Value('elbow placement'),
            imagePaths: const Value('a.jpg,b.jpg'),
            contentHash: const Value('deadbeef'),
            count: const Value(7),
            videoFileSize: Value(BigInt.parse('9007199254740993')), // > 2^53
            archivedAt: Value(created),
            archiveReason: const Value('dup'),
            videoCreationDate: Value(created),
            createdAt: Value(created),
            updatedAt: Value(created),
          ));
      final original = await db.movesDao.getById('rt-1');

      // encode → decode → persist into a FRESH db proves nothing is lost.
      final decoded = moveFromSyncRecord(moveToSyncRecord(original));
      final db2 = createTestDatabase();
      addTearDown(db2.close);
      await db2.into(db2.moves).insertOnConflictUpdate(decoded);
      final restored = await db2.movesDao.getById('rt-1');

      expect(restored.name, original.name);
      expect(restored.learningState, original.learningState);
      expect(restored.category, original.category);
      expect(restored.videoPath, original.videoPath);
      expect(restored.originalVideoName, original.originalVideoName);
      expect(restored.notes, original.notes);
      expect(restored.imagePaths, original.imagePaths);
      expect(restored.contentHash, original.contentHash);
      expect(restored.count, original.count);
      expect(restored.videoFileSize, original.videoFileSize);
      expect(restored.archivedAt, original.archivedAt);
      expect(restored.archiveReason, original.archiveReason);
      expect(restored.videoCreationDate, original.videoCreationDate);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });
  });

  group('pullMovesFromBackend — dual-read gating', () {
    test('returns null when no backend is wired (Firestore fallback)', () async {
      final applied = await service().pullMovesFromBackend();
      expect(applied, isNull);
    });

    test('returns null when the kill-switch is off, even with a backend', () async {
      backend.pullResult = SyncDelta(upserts: [_moveUpsert('x', 'X', DateTime.utc(2026))], deletes: const []);
      final applied = await service(withBackend: backend).pullMovesFromBackend();
      expect(applied, isNull);
      expect(backend.pullCalls, 0); // never even queried the backend
    });
  });

  group('pullMovesFromBackend — last-writer-wins merge', () {
    setUp(() async => prefs.setBool(SyncService.movesDualReadPrefKey, true));

    test('inserts a move that does not exist locally', () async {
      backend.pullResult = SyncDelta(
        upserts: [_moveUpsert('new-1', 'Remote Move', DateTime.utc(2026, 6))],
        deletes: const [],
      );
      final result = await service(withBackend: backend).pullMovesFromBackend();

      expect(result?.applied, 1);
      final move = await db.movesDao.getById('new-1');
      expect(move.name, 'Remote Move');
    });

    test('remote wins when its clock is newer than the local row', () async {
      await _insertMove(db, id: 'm1', name: 'Local', updatedAt: DateTime.utc(2026, 1));
      backend.pullResult = SyncDelta(
        upserts: [_moveUpsert('m1', 'Remote', DateTime.utc(2026, 2))],
        deletes: const [],
      );
      final result = await service(withBackend: backend).pullMovesFromBackend();

      expect(result?.applied, 1);
      expect((await db.movesDao.getById('m1')).name, 'Remote');
    });

    test('local wins — a strictly-newer local edit is never clobbered', () async {
      await _insertMove(db, id: 'm1', name: 'Local Newer', updatedAt: DateTime.utc(2026, 3));
      backend.pullResult = SyncDelta(
        upserts: [_moveUpsert('m1', 'Remote Stale', DateTime.utc(2026, 1))],
        deletes: const [],
      );
      final result = await service(withBackend: backend).pullMovesFromBackend();

      expect(result?.applied, 0); // skipped
      expect((await db.movesDao.getById('m1')).name, 'Local Newer');
    });

    // H.2 (audit A3): Drift truncates local clocks to whole seconds while the
    // backend carries ms. A local edit later in a second must NOT lose to an
    // earlier-ms remote of the SAME second. On the old `isAfter` compare the
    // truncated local (.000) looked stale and the remote clobbered it — red.
    test('same-second tie keeps the local row (precision normalization)', () async {
      await _insertMove(
        db,
        id: 'm1',
        name: 'Local .900',
        updatedAt: DateTime.utc(2026, 1, 1, 12, 0, 0, 900),
      );
      backend.pullResult = SyncDelta(
        upserts: [
          _moveUpsert('m1', 'Remote .500', DateTime.utc(2026, 1, 1, 12, 0, 0, 500)),
        ],
        deletes: const [],
      );
      final result = await service(withBackend: backend).pullMovesFromBackend();

      expect(result?.applied, 0);
      expect((await db.movesDao.getById('m1')).name, 'Local .900');
    });

    // H.3: a malformed record is skipped and counted, never aborts the batch.
    test('isolates a malformed record — [good, bad, good] applies 2', () async {
      backend.pullResult = SyncDelta(
        upserts: [
          _moveUpsert('g1', 'Good One', DateTime.utc(2026, 6)),
          _malformedUpsert('bad'),
          _moveUpsert('g2', 'Good Two', DateTime.utc(2026, 6)),
        ],
        deletes: const [],
      );
      final result = await service(withBackend: backend).pullMovesFromBackend();

      expect(result?.applied, 2);
      expect(result?.failed, 1);
      expect((await db.movesDao.getById('g1')).name, 'Good One');
      expect((await db.movesDao.getById('g2')).name, 'Good Two');
    });

    test('applies a tombstone as a reversible soft-hide, never a hard-delete '
        '(task 4.8)', () async {
      await _insertMove(db, id: 'keep-1', name: 'Keep', updatedAt: DateTime.utc(2026));
      backend.pullResult = SyncDelta(
        upserts: const [],
        deletes: [
          SyncTombstone(
            id: 'keep-1',
            type: SyncEntityType.move,
            deletedAt: DateTime.utc(2027), // newer than the local edit → wins
            clientOpId: 'del:keep-1',
          ),
        ],
      );
      final result = await service(withBackend: backend).pullMovesFromBackend();

      expect(result?.applied, 1);
      // Hidden from every browse feed …
      expect(await db.movesDao.getAll(), isEmpty);
      // … but never hard-deleted — the row (and its video bytes) survive on
      // disk, only flagged `deletedAt`. A delete elsewhere never destroys data.
      final row = await db.movesDao.getById('keep-1');
      expect(row.deletedAt, isNotNull);
    });
  });

  group('pullMovesFromBackend — dedicated backend cursor (H.1)', () {
    setUp(() async => prefs.setBool(SyncService.movesDualReadPrefKey, true));

    test('first pull with no stored cursor is a full pull (since == null)', () async {
      await service(withBackend: backend).pullMovesFromBackend();
      expect(backend.lastSince, isNull);
    });

    test('advances the cursor from SyncDelta.cursor', () async {
      final cursor = DateTime.utc(2026, 5, 5, 5, 5, 5);
      backend.pullResult = SyncDelta(upserts: const [], deletes: const [], cursor: cursor);
      await service(withBackend: backend).pullMovesFromBackend();

      expect(
        prefs.getInt(SyncService.movesBackendCursorPrefKey),
        cursor.millisecondsSinceEpoch,
      );
    });

    test('next pull resumes from the backend cursor, never the Firestore clock', () async {
      // A Firestore clock that must be ignored by the backend path.
      await prefs.setInt('last_sync_at', DateTime.utc(2020).millisecondsSinceEpoch);
      final cursor = DateTime.utc(2026, 5, 5, 5, 5, 5);

      // Round 1 stores the cursor…
      backend.pullResult = SyncDelta(upserts: const [], deletes: const [], cursor: cursor);
      final svc = service(withBackend: backend);
      await svc.pullMovesFromBackend();

      // …round 2 resumes from it (disable/re-enable in between = same instance
      // reading prefs, which is what a restart would do).
      backend.pullResult = const SyncDelta(upserts: [], deletes: []);
      await svc.pullMovesFromBackend();

      expect(backend.lastSince, cursor);
    });

    test('a failed pull leaves the cursor untouched (lossless retry)', () async {
      backend.throwOnPull = StateError('backend down');
      await expectLater(
        service(withBackend: backend).pullMovesFromBackend(),
        throwsA(isA<StateError>()),
      );
      expect(prefs.getInt(SyncService.movesBackendCursorPrefKey), isNull);
    });
  });

  group('pullMovesFromBackend — pull failure propagation (H.7)', () {
    setUp(() async => prefs.setBool(SyncService.movesDualReadPrefKey, true));

    test('a backend pull error propagates and applies nothing', () async {
      await _insertMove(db, id: 'm1', name: 'Untouched', updatedAt: DateTime.utc(2026));
      backend.throwOnPull = StateError('network');

      await expectLater(
        service(withBackend: backend).pullMovesFromBackend(),
        throwsA(isA<StateError>()),
      );
      // Local row is untouched — no partial application on failure.
      expect((await db.movesDao.getById('m1')).name, 'Untouched');
    });
  });
}
