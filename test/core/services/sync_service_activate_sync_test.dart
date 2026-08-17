/// SyncService.activateSync() — the all-or-nothing production activation seam.
///
/// Verifies: it composes the eight backfill*() calls in order, on full
/// success flips every dual-write then dual-read pref ON, returns the reports,
/// and on any backfill throw changes NO prefs and lets the exception propagate.
library;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/backfill/sync_backfill_service.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  SyncService syncService({required SyncBackfillService backfill}) => SyncService(

        syncDao: db.syncDao,
        db: db,
        prefs: prefs,
        syncBackfillService: backfill,
      );

  const r = BackfillReport(
    entityType: SyncEntityType.move,
    recordCount: 3,
    batchCount: 1,
  );

  test('no backfill service → no-op, returns empty list, touches no prefs',
      () async {
    final s = SyncService(

      syncDao: db.syncDao,
      db: db,
      prefs: prefs,
    );
    final reports = await s.activateSync();
    expect(reports, isEmpty);
    expect(s.prefs.getBool(SyncService.movesDualWritePrefKey), isNull);
  });

  test('success → returns 8 reports, calls backfill*() in order, flips all '
      'write+read prefs ON', () async {
    final calls = <String>[];
    final s = syncService(
      backfill: _RecordingBackfill(db: db, onCall: calls.add, reports: const [r]),
    );
    final reports = await s.activateSync();

    expect(reports, hasLength(8));
    expect(calls, <String>[
      'backfillMoves',
      'backfillCombos',
      'backfillComboMoves',
      'backfillReviews',
      'backfillDecks',
      'backfillDeckMoves',
      'backfillMoveNoteEntries',
      'backfillComboNoteEntries',
    ]);
    // Every dual-write pref is ON (fsrsCards has no write key).
    expect(s.prefs.getBool(SyncService.movesDualWritePrefKey), isTrue);
    expect(s.prefs.getBool(SyncService.combosDualWritePrefKey), isTrue);
    expect(s.prefs.getBool(SyncService.reviewsDualWritePrefKey), isTrue);
    expect(s.prefs.getBool(SyncService.decksDualWritePrefKey), isTrue);
    expect(s.prefs.getBool(SyncService.noteEntriesDualWritePrefKey), isTrue);
    // Every dual-read pref is ON (incl. fsrsCards, read-only).
    expect(s.prefs.getBool(SyncService.movesDualReadPrefKey), isTrue);
    expect(s.prefs.getBool(SyncService.combosDualReadPrefKey), isTrue);
    expect(s.prefs.getBool(SyncService.reviewsDualReadPrefKey), isTrue);
    expect(s.prefs.getBool(SyncService.fsrsCardsDualReadPrefKey), isTrue);
    expect(s.prefs.getBool(SyncService.decksDualReadPrefKey), isTrue);
    expect(s.prefs.getBool(SyncService.noteEntriesDualReadPrefKey), isTrue);
  });

  test('throw → no prefs flipped, exception propagates', () async {
    final s = syncService(backfill: _ThrowingBackfill(db: db));
    await expectLater(
      s.activateSync(),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        'backend down',
      )),
    );
    // No write/read pref was touched.
    expect(s.prefs.getBool(SyncService.movesDualWritePrefKey), isNull);
    expect(s.prefs.getBool(SyncService.movesDualReadPrefKey), isNull);
  });
}

/// Minimal fake backend — [SyncBackfillService] stores it but our overrides
/// never call through.
class _FakeBackend implements SyncBackend {
  @override
  String get providerType => 'fake';
  @override
  Future<void> push(
    SyncEntityType type, {
    List<SyncRecord> upserts = const [],
    List<SyncTombstone> deletes = const [],
  }) async {}
  @override
  Future<SyncDelta> pull(SyncEntityType type, {DateTime? since}) async =>
      const SyncDelta(upserts: [], deletes: []);
  @override
  Stream<SyncDelta> subscribe(SyncEntityType type) => const Stream.empty();
}

/// Records each backfill*() call name and returns canned reports (cycling).
class _RecordingBackfill extends SyncBackfillService {
  _RecordingBackfill({
    required this.db,
    required this.onCall,
    this.reports = const [],
  }) : super(_FakeBackend(), db.movesDao);

  final AppDatabase db;
  final void Function(String) onCall;
  final List<BackfillReport> reports;

  int _i = 0;
  BackfillReport _r(String name) {
    onCall(name);
    final out = reports[_i % reports.length];
    _i++;
    return out;
  }

  @override
  Future<BackfillReport> backfillMoves() async => _r('backfillMoves');
  @override
  Future<BackfillReport> backfillCombos() async => _r('backfillCombos');
  @override
  Future<BackfillReport> backfillComboMoves() async => _r('backfillComboMoves');
  @override
  Future<BackfillReport> backfillReviews() async => _r('backfillReviews');
  @override
  Future<BackfillReport> backfillDecks() async => _r('backfillDecks');
  @override
  Future<BackfillReport> backfillDeckMoves() async => _r('backfillDeckMoves');
  @override
  Future<BackfillReport> backfillMoveNoteEntries() async =>
      _r('backfillMoveNoteEntries');
  @override
  Future<BackfillReport> backfillComboNoteEntries() async =>
      _r('backfillComboNoteEntries');
}

class _ThrowingBackfill extends SyncBackfillService {
  _ThrowingBackfill({required this.db}) : super(_FakeBackend(), db.movesDao);
  final AppDatabase db;
  @override
  Future<BackfillReport> backfillMoves() async => throw StateError('backend down');
  @override
  Future<BackfillReport> backfillCombos() async => throw StateError('backend down');
  @override
  Future<BackfillReport> backfillComboMoves() async => throw StateError('backend down');
  @override
  Future<BackfillReport> backfillReviews() async => throw StateError('backend down');
  @override
  Future<BackfillReport> backfillDecks() async => throw StateError('backend down');
  @override
  Future<BackfillReport> backfillDeckMoves() async => throw StateError('backend down');
  @override
  Future<BackfillReport> backfillMoveNoteEntries() async => throw StateError('backend down');
  @override
  Future<BackfillReport> backfillComboNoteEntries() async => throw StateError('backend down');
}
