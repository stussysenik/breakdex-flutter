/// Wave task 4.5 — `reviews` dual-write + dual-read (append-only).
///
/// Reviews do not use the shared LWW engines: dual-write emits **upserts only**
/// (never a tombstone — `reviewEvent` has no deletes) and dual-read merges
/// **insert-if-absent** (a re-seen id is a no-op). These tests prove exactly
/// that append-only shape, plus the pref gating, cursor, and fault isolation the
/// entity shares with moves/combos.
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/services/auth_service.dart';
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/codecs/review_codec.dart';
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

SyncLogData _entry(final String id, final String action) => SyncLogData(
  entityTable: 'reviews',
  entityId: id,
  action: action,
  changedAt: DateTime.utc(2026),
  synced: false,
  videoSynced: false,
);

Future<void> _insertReview(
  final AppDatabase db, {
  required final String id,
  final String rating = 'GOOD',
  final String? entityIdSnapshot = 'm1',
  final String? entityType = 'move',
}) => db.into(db.reviews).insert(
      ReviewsCompanion.insert(
        id: id,
        rating: rating,
        reviewType: ReviewType.move.dbValue,
        entityIdSnapshot: Value(entityIdSnapshot),
        entityType: Value(entityType),
      ),
    );

SyncRecord _event(final String id, final int rating, final DateTime ts) => SyncRecord(
  id: id,
  type: SyncEntityType.reviewEvent,
  json: {'entityId': 'm1', 'entityType': 'move', 'rating': rating},
  updatedAt: ts,
  clientOpId: id,
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
    test('pref OFF ⇒ no push', () async {
      await _insertReview(db, id: 'r1');
      await _service(db, prefs, backend: backend).dualWriteReviews([_entry('r1', 'create')]);
      expect(backend.pushes, isEmpty);
    });

    test('no backend wired ⇒ no-op (must not throw)', () async {
      await prefs.setBool(SyncService.reviewsDualWritePrefKey, true);
      await _service(db, prefs).dualWriteReviews([_entry('r1', 'create')]);
    });

    test('pref ON ⇒ byte-identical reviewEvent upsert, no deletes', () async {
      await _insertReview(db, id: 'r1', rating: ReviewRating.easy.dbValue);
      await prefs.setBool(SyncService.reviewsDualWritePrefKey, true);
      final expected = reviewToSyncRecord(
        (await db.reviewsDao.getAllOrdered()).single,
      )!;

      await _service(db, prefs, backend: backend).dualWriteReviews([_entry('r1', 'create')]);

      final push = backend.pushes.single;
      expect(push.type, SyncEntityType.reviewEvent);
      expect(push.deletes, isEmpty);
      final up = push.upserts.single;
      expect(up.id, 'r1');
      expect(up.clientOpId, expected.clientOpId);
      expect(up.updatedAt, expected.updatedAt);
      expect(up.json, expected.json);
    });

    test('delete entry is ignored (append-only ⇒ no tombstone, no push)', () async {
      await prefs.setBool(SyncService.reviewsDualWritePrefKey, true);
      await _service(db, prefs, backend: backend).dualWriteReviews([_entry('gone', 'delete')]);
      expect(backend.pushes, isEmpty);
    });

    test('unencodable review (no entity) is skipped', () async {
      await _insertReview(db, id: 'r1', entityIdSnapshot: null, entityType: null);
      await prefs.setBool(SyncService.reviewsDualWritePrefKey, true);
      await _service(db, prefs, backend: backend).dualWriteReviews([_entry('r1', 'create')]);
      expect(backend.pushes, isEmpty); // nothing encodable ⇒ no push
    });

    test('push failure is swallowed (never blocks Firestore)', () async {
      await _insertReview(db, id: 'r1');
      await prefs.setBool(SyncService.reviewsDualWritePrefKey, true);
      backend.throwOnPush = true;
      await _service(db, prefs, backend: backend).dualWriteReviews([_entry('r1', 'create')]);
    });
  });

  group('dual-read', () {
    test('disabled ⇒ null (falls back to Firestore)', () async {
      expect(await _service(db, prefs, backend: backend).pullReviewsFromBackend(), isNull);
      await prefs.setBool(SyncService.reviewsDualReadPrefKey, true);
      expect(await _service(db, prefs).pullReviewsFromBackend(), isNull); // null backend
    });

    test('insert-if-absent: new event applied, re-seen id skipped', () async {
      await prefs.setBool(SyncService.reviewsDualReadPrefKey, true);
      await _insertReview(db, id: 'r-existing', rating: ReviewRating.hard.dbValue);
      final t = DateTime.fromMillisecondsSinceEpoch(1700000100000, isUtc: true);
      backend.pullResults[SyncEntityType.reviewEvent] = SyncDelta(
        upserts: [
          _event('r-new', 3, t), // not present ⇒ appended
          _event('r-existing', 0, t), // already present ⇒ immutable, skipped
        ],
        deletes: const [],
        cursor: t,
      );

      final result = await _service(db, prefs, backend: backend).pullReviewsFromBackend();
      expect(result!.applied, 1);
      final rows = {for (final r in await db.reviewsDao.getAllOrdered()) r.id: r};
      expect(rows['r-new']!.rating, ReviewRating.easy.dbValue); // index 3
      // The pre-existing review is never overwritten by the append.
      expect(rows['r-existing']!.rating, ReviewRating.hard.dbValue);
      expect(prefs.getInt(SyncService.reviewsBackendCursorPrefKey), t.millisecondsSinceEpoch);
    });

    test('own cursor drives the pull `since`', () async {
      await prefs.setBool(SyncService.reviewsDualReadPrefKey, true);
      await prefs.setInt(SyncService.reviewsBackendCursorPrefKey, 333000);
      await _service(db, prefs, backend: backend).pullReviewsFromBackend();
      expect(backend.lastSince[SyncEntityType.reviewEvent]!.millisecondsSinceEpoch, 333000);
    });

    test('malformed record is isolated (counted, never aborts the batch)', () async {
      await prefs.setBool(SyncService.reviewsDualReadPrefKey, true);
      final t = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      backend.pullResults[SyncEntityType.reviewEvent] = SyncDelta(
        upserts: [
          _event('bad', 99, t), // rating index out of range ⇒ decode throws
          _event('good', 2, t), // still appended
        ],
        deletes: const [],
      );

      final result = await _service(db, prefs, backend: backend).pullReviewsFromBackend();
      expect(result!.failed, 1);
      expect(result.applied, 1);
      final rows = {for (final r in await db.reviewsDao.getAllOrdered()) r.id: r};
      expect(rows.containsKey('good'), isTrue);
      expect(rows.containsKey('bad'), isFalse);
    });
  });
}
