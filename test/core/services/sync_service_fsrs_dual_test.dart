/// Wave task 4.6 — `fsrs_cards` dual-read (pull-only, derived server-side).
///
/// The card is derived from the `reviewEvents` log and **never pushed**, so
/// there is no dual-write — only a pull path. These tests prove the pull's LWW
/// guard (a pulled card never clobbers a fresher local review, keyed on
/// `lastReview` at whole-second granularity), that an upsert preserves the
/// local-only `reps` / `lapses` / `lastReview` the derive does not carry, plus
/// the pref gating, own cursor, and per-record fault isolation shared with the
/// other entities.
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/auth_service.dart';
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import '../../helpers/test_database.dart';

class _FakeBackend implements SyncBackend {
  final Map<SyncEntityType, SyncDelta> pullResults = {};
  final Map<SyncEntityType, DateTime?> lastSince = {};

  @override
  String get providerType => 'fake';

  @override
  Future<void> push(
    final SyncEntityType type, {
    final List<SyncRecord> upserts = const [],
    final List<SyncTombstone> deletes = const [],
  }) async {}

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

/// A derived-card pull payload, exactly as `AppwriteSyncBackend._decodeFsrsCardRow`
/// shapes it: identity + schedule fields in `json`, newest reviewedAt as clock.
SyncRecord _pulled({
  final String entityId = 'm1',
  final String entityType = 'move',
  final double stability = 20.0,
  final double difficulty = 5.0,
  final int dueMs = 1700000500000,
  final int state = 2,
  required final int updatedAtMs,
}) => SyncRecord(
  id: '$entityType:$entityId',
  type: SyncEntityType.fsrsCard,
  json: {
    'entityId': entityId,
    'entityType': entityType,
    'stability': stability,
    'difficulty': difficulty,
    'due': dueMs,
    'state': state,
    'lastEventOpId': 'op-x',
  },
  updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs, isUtc: true),
  clientOpId: 'op-x',
);

Future<void> _insertCard(
  final AppDatabase db, {
  final String entityId = 'm1',
  final String entityType = 'move',
  final double stability = 1.0,
  final double difficulty = 1.0,
  final int reps = 5,
  final int lapses = 2,
  final int fsrsState = 1,
  final DateTime? lastReview,
}) => db.into(db.fsrsCards).insert(
      FsrsCardsCompanion.insert(
        entityId: entityId,
        entityType: Value(entityType),
        stability: Value(stability),
        difficulty: Value(difficulty),
        reps: Value(reps),
        lapses: Value(lapses),
        fsrsState: Value(fsrsState),
        lastReview: Value(lastReview),
      ),
    );

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late _FakeBackend backend;

  final oldReview = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
  final newerReview = DateTime.fromMillisecondsSinceEpoch(1700000900000, isUtc: true);

  setUp(() async {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    backend = _FakeBackend();
  });

  tearDown(() => db.close());

  test('disabled ⇒ null (falls back to Firestore); null backend ⇒ null', () async {
    expect(await _service(db, prefs, backend: backend).pullFsrsCardsFromBackend(), isNull);
    await prefs.setBool(SyncService.fsrsCardsDualReadPrefKey, true);
    expect(await _service(db, prefs).pullFsrsCardsFromBackend(), isNull);
  });

  test('no local card ⇒ derived card is inserted', () async {
    await prefs.setBool(SyncService.fsrsCardsDualReadPrefKey, true);
    backend.pullResults[SyncEntityType.fsrsCard] = SyncDelta(
      upserts: [_pulled(updatedAtMs: newerReview.millisecondsSinceEpoch)],
      deletes: const [],
      cursor: newerReview,
    );

    final result = await _service(db, prefs, backend: backend).pullFsrsCardsFromBackend();
    expect(result!.applied, 1);
    final card = await db.fsrsCardsDao.getByEntityId('m1');
    expect(card!.stability, 20.0);
    expect(card.fsrsState, 2);
    expect(prefs.getInt(SyncService.fsrsCardsBackendCursorPrefKey),
        newerReview.millisecondsSinceEpoch);
  });

  test('LWW: stale derived card does NOT clobber a fresher local review', () async {
    await prefs.setBool(SyncService.fsrsCardsDualReadPrefKey, true);
    // Local card reflects a review NEWER than what the server has folded.
    await _insertCard(db, stability: 99.0, fsrsState: 3, lastReview: newerReview);
    backend.pullResults[SyncEntityType.fsrsCard] = SyncDelta(
      upserts: [_pulled(updatedAtMs: oldReview.millisecondsSinceEpoch)],
      deletes: const [],
      cursor: newerReview,
    );

    final result = await _service(db, prefs, backend: backend).pullFsrsCardsFromBackend();
    expect(result!.applied, 0); // skipped — local is fresher
    final card = await db.fsrsCardsDao.getByEntityId('m1');
    expect(card!.stability, 99.0); // local value untouched
    expect(card.fsrsState, 3);
  });

  test('LWW: fresher derived card overwrites schedule but preserves local reps/lapses/lastReview',
      () async {
    await prefs.setBool(SyncService.fsrsCardsDualReadPrefKey, true);
    // Local card is behind: its last review is older than the derived clock.
    await _insertCard(db,
        stability: 1.0, difficulty: 1.0, reps: 5, lapses: 2, fsrsState: 1,
        lastReview: oldReview);
    backend.pullResults[SyncEntityType.fsrsCard] = SyncDelta(
      upserts: [_pulled(
          stability: 20.0, difficulty: 5.0, state: 2,
          updatedAtMs: newerReview.millisecondsSinceEpoch)],
      deletes: const [],
      cursor: newerReview,
    );

    final result = await _service(db, prefs, backend: backend).pullFsrsCardsFromBackend();
    expect(result!.applied, 1);
    final card = await db.fsrsCardsDao.getByEntityId('m1');
    // Derived schedule applied…
    expect(card!.stability, 20.0);
    expect(card.difficulty, 5.0);
    expect(card.fsrsState, 2);
    // …but the derive doesn't carry these, so the local values survive the upsert.
    expect(card.reps, 5);
    expect(card.lapses, 2);
    // Same instant, untouched (Drift reads DateTime back local-zoned).
    expect(card.lastReview!.millisecondsSinceEpoch, oldReview.millisecondsSinceEpoch);
  });

  test('whole-second tie ⇒ local wins (derived skipped)', () async {
    await prefs.setBool(SyncService.fsrsCardsDualReadPrefKey, true);
    // Same second, sub-second apart: LWW compares at second granularity.
    const localMs = 1700000000750;
    const pulledMs = 1700000000200;
    await _insertCard(db,
        stability: 42.0,
        lastReview: DateTime.fromMillisecondsSinceEpoch(localMs, isUtc: true));
    backend.pullResults[SyncEntityType.fsrsCard] = SyncDelta(
      upserts: [_pulled(stability: 20.0, updatedAtMs: pulledMs)],
      deletes: const [],
    );

    final result = await _service(db, prefs, backend: backend).pullFsrsCardsFromBackend();
    expect(result!.applied, 0);
    expect((await db.fsrsCardsDao.getByEntityId('m1'))!.stability, 42.0);
  });

  test('null local lastReview ⇒ treated as epoch-0, derived card applied', () async {
    await prefs.setBool(SyncService.fsrsCardsDualReadPrefKey, true);
    await _insertCard(db, stability: 1.0, lastReview: null);
    backend.pullResults[SyncEntityType.fsrsCard] = SyncDelta(
      upserts: [_pulled(stability: 20.0, updatedAtMs: oldReview.millisecondsSinceEpoch)],
      deletes: const [],
    );

    final result = await _service(db, prefs, backend: backend).pullFsrsCardsFromBackend();
    expect(result!.applied, 1);
    expect((await db.fsrsCardsDao.getByEntityId('m1'))!.stability, 20.0);
  });

  test('own cursor drives the pull `since`', () async {
    await prefs.setBool(SyncService.fsrsCardsDualReadPrefKey, true);
    await prefs.setInt(SyncService.fsrsCardsBackendCursorPrefKey, 444000);
    await _service(db, prefs, backend: backend).pullFsrsCardsFromBackend();
    expect(backend.lastSince[SyncEntityType.fsrsCard]!.millisecondsSinceEpoch, 444000);
  });

  test('malformed record is isolated (counted, never aborts the batch)', () async {
    await prefs.setBool(SyncService.fsrsCardsDualReadPrefKey, true);
    final bad = SyncRecord(
      id: 'move:bad',
      type: SyncEntityType.fsrsCard,
      json: const {'entityType': 'move'}, // missing entityId ⇒ merge throws
      updatedAt: newerReview,
      clientOpId: 'op-bad',
    );
    backend.pullResults[SyncEntityType.fsrsCard] = SyncDelta(
      upserts: [bad, _pulled(entityId: 'good', updatedAtMs: newerReview.millisecondsSinceEpoch)],
      deletes: const [],
    );

    final result = await _service(db, prefs, backend: backend).pullFsrsCardsFromBackend();
    expect(result!.failed, 1);
    expect(result.applied, 1);
    expect(await db.fsrsCardsDao.getByEntityId('good'), isNotNull);
    expect(await db.fsrsCardsDao.getByEntityId('bad'), isNull);
  });
}
