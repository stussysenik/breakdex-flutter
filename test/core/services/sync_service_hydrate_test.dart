import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/auth_service.dart';
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import '../../helpers/test_database.dart';

/// Serves a per-type canned [SyncDelta] and records which types were pulled, so
/// a test can prove [SyncService.hydrateAllFromBackend] force-pulls every entity
/// regardless of the dual-read kill-switches (the inbound mirror of backfill).
class _PerTypeBackend implements SyncBackend {
  final Map<SyncEntityType, SyncDelta> deltas = {};
  final List<SyncEntityType> pulledTypes = [];

  @override
  String get providerType => 'fake';

  @override
  Future<SyncDelta> pull(final SyncEntityType type, {final DateTime? since}) async {
    pulledTypes.add(type);
    return deltas[type] ?? const SyncDelta(upserts: [], deletes: []);
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

SyncRecord _moveUpsert(final String id, final String name, final DateTime at) =>
    SyncRecord(
      id: id,
      type: SyncEntityType.move,
      json: {
        'name': name,
        'learningState': 'NEW',
        'category': 'default',
        'count': 4,
        'createdAt': at.millisecondsSinceEpoch,
      },
      updatedAt: at,
      clientOpId: 'op:$id',
    );

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late _PerTypeBackend backend;

  SyncService service({final SyncBackend? withBackend}) => SyncService(
        authService: AuthService(prefs),
        syncDao: db.syncDao,
        db: db,
        prefs: prefs,
        syncBackend: withBackend,
      );

  setUp(() async {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    backend = _PerTypeBackend();
  });

  tearDown(() async => db.close());

  group('hydrateAllFromBackend — inbound seed (mirror of backfill)', () {
    test('no backend wired ⇒ empty report, no work', () async {
      final reports = await service().hydrateAllFromBackend();
      expect(reports, isEmpty);
    });

    test('force-pulls a move into empty local Drift even with dual-read OFF '
        '(the whole point: bypasses the kill-switch a live pull respects)',
        () async {
      // Kill-switch is off by default — pullMovesFromBackend would no-op here.
      expect(prefs.getBool(SyncService.movesDualReadPrefKey), isNull);
      backend.deltas[SyncEntityType.move] = SyncDelta(
        upserts: [_moveUpsert('h1', 'Hydrated Move', DateTime.utc(2026, 6))],
        deletes: const [],
      );

      final svc = service(withBackend: backend);
      // Sanity: the gated live path is indeed closed…
      expect(await svc.pullMovesFromBackend(), isNull);
      expect((await db.movesDao.getAll()), isEmpty);

      // …but the deliberate hydrate seeds it anyway.
      final reports = await svc.hydrateAllFromBackend();

      final move = await db.movesDao.getById('h1');
      expect(move.name, 'Hydrated Move');
      final moveReport = reports.firstWhere((final r) => r.label == 'move');
      expect(moveReport.applied, 1);
    });

    test('covers all nine entity types — never silently skips one', () async {
      final reports =
          await service(withBackend: backend).hydrateAllFromBackend();
      expect(
        reports.map((final r) => r.label).toSet(),
        {
          'move', 'combo', 'comboMove', 'review', 'fsrsCard',
          'deck', 'deckMove', 'moveNoteEntry', 'comboNoteEntry',
        },
      );
      // Every type was actually queried against the backend.
      expect(backend.pulledTypes, containsAll(<SyncEntityType>[
        SyncEntityType.move,
        SyncEntityType.combo,
        SyncEntityType.comboMove,
        SyncEntityType.reviewEvent,
        SyncEntityType.fsrsCard,
        SyncEntityType.deck,
        SyncEntityType.deckMove,
        SyncEntityType.moveNoteEntry,
        SyncEntityType.comboNoteEntry,
      ]));
    });

    test('advances the entity cursor so a later live pull resumes (H.1)',
        () async {
      final cursor = DateTime.utc(2026, 5, 5, 5, 5, 5);
      backend.deltas[SyncEntityType.move] =
          SyncDelta(upserts: const [], deletes: const [], cursor: cursor);

      await service(withBackend: backend).hydrateAllFromBackend();

      expect(
        prefs.getInt(SyncService.movesBackendCursorPrefKey),
        cursor.millisecondsSinceEpoch,
      );
    });
  });
}
