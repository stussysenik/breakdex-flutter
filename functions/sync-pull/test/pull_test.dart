import 'package:sync_pull/pull.dart';
import 'package:test/test.dart';

/// In-memory [PullStore] — the parity harness. Returns canned, already-`since`-
/// filtered lists (the real store does the filtering + pagination), so tests
/// exercise the pure delta/cursor semantics with no live Appwrite backend.
class _FakeStore implements PullStore {
  _FakeStore({this.live = const [], this.tombstones = const []});

  final List<LiveRecord> live;
  final List<TombstoneRecord> tombstones;

  int liveCalls = 0;
  int tombstoneCalls = 0;

  @override
  Future<List<LiveRecord>> listLiveSince(
    final String table,
    final String userId,
    final int? since,
  ) async {
    liveCalls++;
    return live;
  }

  @override
  Future<List<TombstoneRecord>> listTombstonesSince(
    final String table,
    final String userId,
    final int? since,
  ) async {
    tombstoneCalls++;
    return tombstones;
  }
}

void main() {
  group('validatePullTable', () {
    test('accepts every descriptive table (incl. note entries, task 4.9)', () {
      expect(descriptiveTables,
          containsAll(<String>['moveNoteEntries', 'comboNoteEntries']));
      for (final t in descriptiveTables) {
        expect(() => validatePullTable(t), returnsNormally);
      }
    });

    test('rejects fsrsCards (derived, pulled via FSRS Function)', () {
      expect(
        () => validatePullTable('fsrsCards'),
        throwsA(isA<PullRejection>()),
      );
    });

    test('rejects reviewEvents (append-only, pulled via reviews Function)', () {
      expect(
        () => validatePullTable('reviewEvents'),
        throwsA(isA<PullRejection>()),
      );
    });

    test('rejects an unknown table', () {
      expect(
        () => validatePullTable('widgets'),
        throwsA(isA<PullRejection>()),
      );
    });
  });

  group('PullRequest.fromJson', () {
    test('parses table + integer since', () {
      final req = PullRequest.fromJson({'table': 'moves', 'since': 1700});
      expect(req.table, 'moves');
      expect(req.since, 1700);
    });

    test('absent since ⇒ full pull (null)', () {
      final req = PullRequest.fromJson({'table': 'moves'});
      expect(req.since, isNull);
    });

    test('explicit null since ⇒ full pull (null)', () {
      final req = PullRequest.fromJson({'table': 'moves', 'since': null});
      expect(req.since, isNull);
    });

    test('integral num since is coerced to int', () {
      final req = PullRequest.fromJson({'table': 'moves', 'since': 1700.0});
      expect(req.since, 1700);
    });

    test('missing table ⇒ PullRejection', () {
      expect(
        () => PullRequest.fromJson({'since': 1}),
        throwsA(isA<PullRejection>()),
      );
    });

    test('non-numeric since ⇒ PullRejection', () {
      expect(
        () => PullRequest.fromJson({'table': 'moves', 'since': 'soon'}),
        throwsA(isA<PullRejection>()),
      );
    });
  });

  group('buildPullDelta', () {
    test('empty entity, full pull ⇒ empty delta, null cursor', () {
      final d = buildPullDelta(since: null, live: [], tombstones: []);
      expect(d.upserts, isEmpty);
      expect(d.deletes, isEmpty);
      expect(d.cursor, isNull);
    });

    test('no changes since a cursor ⇒ cursor unchanged (not reset)', () {
      final d = buildPullDelta(since: 500, live: [], tombstones: []);
      expect(d.cursor, 500);
    });

    test('live rows only ⇒ upserts shaped, cursor = max updatedAt', () {
      final d = buildPullDelta(
        since: null,
        live: [
          const LiveRecord(
            id: 'a',
            json: {'name': 'six-step'},
            updatedAt: 10,
            clientOpId: 'op-a',
          ),
          const LiveRecord(id: 'b', json: {}, updatedAt: 30, clientOpId: 'op-b'),
        ],
        tombstones: [],
      );
      expect(d.upserts.map((u) => u.id), ['a', 'b']);
      expect(d.upserts.first.json, {'name': 'six-step'});
      expect(d.deletes, isEmpty);
      expect(d.cursor, 30);
    });

    test('tombstones only ⇒ deletes shaped, cursor = max deletedAt', () {
      final d = buildPullDelta(
        since: null,
        live: [],
        tombstones: [
          const TombstoneRecord(id: 'x', deletedAt: 42, clientOpId: 'op-x'),
        ],
      );
      expect(d.upserts, isEmpty);
      expect(d.deletes.single.id, 'x');
      expect(d.deletes.single.deletedAt, 42);
      expect(d.cursor, 42);
    });

    test('union: cursor is the max across BOTH clocks (delete newest)', () {
      final d = buildPullDelta(
        since: null,
        live: [
          const LiveRecord(id: 'a', json: {}, updatedAt: 10, clientOpId: 'op-a'),
        ],
        tombstones: [
          const TombstoneRecord(id: 'b', deletedAt: 15, clientOpId: 'op-b'),
        ],
      );
      expect(d.upserts.single.id, 'a');
      expect(d.deletes.single.id, 'b');
      expect(d.cursor, 15);
    });

    test('union: cursor is the max across BOTH clocks (upsert newest)', () {
      final d = buildPullDelta(
        since: 5,
        live: [
          const LiveRecord(id: 'a', json: {}, updatedAt: 20, clientOpId: 'op-a'),
        ],
        tombstones: [
          const TombstoneRecord(id: 'b', deletedAt: 15, clientOpId: 'op-b'),
        ],
      );
      expect(d.cursor, 20);
    });

    test('cursor never regresses below since', () {
      // Defensive: a returned clock at/under `since` cannot lower the cursor.
      final d = buildPullDelta(
        since: 100,
        live: [
          const LiveRecord(id: 'a', json: {}, updatedAt: 40, clientOpId: 'op-a'),
        ],
        tombstones: [],
      );
      expect(d.cursor, 100);
    });
  });

  group('PullDelta.toJson (wire shape parity with Convex pullRecords)', () {
    test('serializes upserts, deletes, and a null cursor', () {
      final json = buildPullDelta(
        since: null,
        live: [],
        tombstones: [],
      ).toJson();
      expect(json, {
        'upserts': <dynamic>[],
        'deletes': <dynamic>[],
        'cursor': null,
      });
    });

    test('serializes element field names 1:1', () {
      final json = buildPullDelta(
        since: null,
        live: [
          const LiveRecord(
            id: 'a',
            json: {'k': 'v'},
            updatedAt: 7,
            clientOpId: 'op-a',
          ),
        ],
        tombstones: [
          const TombstoneRecord(id: 'b', deletedAt: 9, clientOpId: 'op-b'),
        ],
      ).toJson();
      expect(json['upserts'], [
        {'id': 'a', 'json': {'k': 'v'}, 'updatedAt': 7, 'clientOpId': 'op-a'},
      ]);
      expect(json['deletes'], [
        {'id': 'b', 'deletedAt': 9, 'clientOpId': 'op-b'},
      ]);
      expect(json['cursor'], 9);
    });
  });

  group('pull (orchestration)', () {
    test('validates the table BEFORE any store read', () async {
      final store = _FakeStore();
      await expectLater(
        pull(store, 'user-1', const PullRequest(table: 'fsrsCards', since: null)),
        throwsA(isA<PullRejection>()),
      );
      expect(store.liveCalls, 0);
      expect(store.tombstoneCalls, 0);
    });

    test('reads both states and unions them into one delta', () async {
      final store = _FakeStore(
        live: [
          const LiveRecord(id: 'a', json: {}, updatedAt: 12, clientOpId: 'op-a'),
        ],
        tombstones: [
          const TombstoneRecord(id: 'b', deletedAt: 18, clientOpId: 'op-b'),
        ],
      );
      final delta = await pull(
        store,
        'user-1',
        const PullRequest(table: 'moves', since: 5),
      );
      expect(store.liveCalls, 1);
      expect(store.tombstoneCalls, 1);
      expect(delta.upserts.single.id, 'a');
      expect(delta.deletes.single.id, 'b');
      expect(delta.cursor, 18);
    });
  });
}
