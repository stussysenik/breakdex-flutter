import 'package:sync_push/reconcile.dart';
import 'package:test/test.dart';

/// In-memory [SyncStore] — the parity harness. Keys rows by `id` per table
/// (single logical record per id), so `ref == id`. Proves the reconciliation
/// semantics with no live Appwrite backend, exactly as the Convex unit view of
/// `sync.ts` would.
class _FakeStore implements SyncStore {
  final Map<String, Map<String, _LiveRow>> live = {};
  final Map<String, Map<String, _TombRow>> tombs = {};

  /// Ids for which the next live write throws — exercises H.3 fault isolation.
  final Set<String> failLiveWriteOnId = {};

  Map<String, _LiveRow> _liveTable(final String t) =>
      live.putIfAbsent(t, () => {});
  Map<String, _TombRow> _tombTable(final String t) =>
      tombs.putIfAbsent(t, () => {});

  @override
  Future<StoredRow?> getLive(
    final String table,
    final String userId,
    final String id,
  ) async {
    final row = _liveTable(table)[id];
    if (row == null || row.userId != userId) {
      return null;
    }
    return StoredRow(ref: id, clock: row.updatedAt);
  }

  @override
  Future<StoredRow?> getTombstone(
    final String table,
    final String userId,
    final String id,
  ) async {
    final row = _tombTable(table)[id];
    if (row == null || row.userId != userId) {
      return null;
    }
    return StoredRow(ref: id, clock: row.deletedAt);
  }

  @override
  Future<void> createLive(
    final String table, {
    required final String userId,
    required final String id,
    required final int updatedAt,
    required final String clientOpId,
    required final Map<String, dynamic> json,
  }) async {
    if (failLiveWriteOnId.contains(id)) {
      throw StateError('injected write fault for "$id"');
    }
    _liveTable(table)[id] = _LiveRow(
      userId: userId,
      updatedAt: updatedAt,
      clientOpId: clientOpId,
      json: json,
    );
  }

  @override
  Future<void> updateLive(
    final String table,
    final String ref, {
    required final int updatedAt,
    required final String clientOpId,
    required final Map<String, dynamic> json,
  }) async {
    if (failLiveWriteOnId.contains(ref)) {
      throw StateError('injected write fault for "$ref"');
    }
    final existing = _liveTable(table)[ref]!;
    _liveTable(table)[ref] = _LiveRow(
      userId: existing.userId,
      updatedAt: updatedAt,
      clientOpId: clientOpId,
      json: json,
    );
  }

  @override
  Future<void> deleteLive(final String table, final String ref) async {
    _liveTable(table).remove(ref);
  }

  @override
  Future<void> createTombstone(
    final String table, {
    required final String userId,
    required final String id,
    required final int deletedAt,
    required final String clientOpId,
  }) async {
    _tombTable(table)[id] = _TombRow(
      userId: userId,
      deletedAt: deletedAt,
      clientOpId: clientOpId,
    );
  }

  @override
  Future<void> updateTombstone(
    final String table,
    final String ref, {
    required final int deletedAt,
    required final String clientOpId,
  }) async {
    _tombTable(table)[ref] = _TombRow(
      userId: _tombTable(table)[ref]!.userId,
      deletedAt: deletedAt,
      clientOpId: clientOpId,
    );
  }

  @override
  Future<void> deleteTombstone(final String table, final String ref) async {
    _tombTable(table).remove(ref);
  }
}

class _LiveRow {
  const _LiveRow({
    required this.userId,
    required this.updatedAt,
    required this.clientOpId,
    required this.json,
  });
  final String userId;
  final int updatedAt;
  final String clientOpId;
  final Map<String, dynamic> json;
}

class _TombRow {
  const _TombRow({
    required this.userId,
    required this.deletedAt,
    required this.clientOpId,
  });
  final String userId;
  final int deletedAt;
  final String clientOpId;
}

const _uid = 'user-1';

PushRequest _push({
  final String table = 'moves',
  final List<UpsertOp> upserts = const [],
  final List<TombstoneOp> deletes = const [],
}) => PushRequest(table: table, upserts: upserts, deletes: deletes);

UpsertOp _up(
  final String id,
  final int updatedAt, {
  final String op = 'op',
  final Map<String, dynamic> json = const {'k': 'v'},
}) => UpsertOp(id: id, json: json, updatedAt: updatedAt, clientOpId: op);

TombstoneOp _tomb(
  final String id,
  final int deletedAt, {
  final String op = 'op',
}) => TombstoneOp(id: id, deletedAt: deletedAt, clientOpId: op);

void main() {
  late _FakeStore store;
  setUp(() => store = _FakeStore());

  group('upsert LWW', () {
    test('new record inserts a live row', () async {
      final r = await applyPush(store, _uid, _push(upserts: [_up('m1', 1000)]));
      expect(r.applied, 1);
      expect(r.skipped, 0);
      expect(store.live['moves']!['m1']!.updatedAt, 1000);
      expect(store.tombs['moves'] ?? const {}, isEmpty);
    });

    test('older incoming loses to a strictly-newer stored clock', () async {
      await applyPush(store, _uid, _push(upserts: [_up('m1', 2000, op: 'a')]));
      final r = await applyPush(
        store,
        _uid,
        _push(upserts: [_up('m1', 1000, op: 'b')]),
      );
      expect(r.applied, 0);
      expect(r.skipped, 1);
      expect(store.live['moves']!['m1']!.updatedAt, 2000);
      expect(store.live['moves']!['m1']!.clientOpId, 'a');
    });

    test('newer incoming wins', () async {
      await applyPush(store, _uid, _push(upserts: [_up('m1', 1000, op: 'a')]));
      final r = await applyPush(
        store,
        _uid,
        _push(upserts: [_up('m1', 3000, op: 'b')]),
      );
      expect(r.applied, 1);
      expect(store.live['moves']!['m1']!.updatedAt, 3000);
      expect(store.live['moves']!['m1']!.clientOpId, 'b');
    });

    test('equal clocks apply (>=, tie → incoming)', () async {
      await applyPush(store, _uid, _push(upserts: [_up('m1', 1000, op: 'a')]));
      final r = await applyPush(
        store,
        _uid,
        _push(
          upserts: [_up('m1', 1000, op: 'b', json: {'k': 'changed'})],
        ),
      );
      expect(r.applied, 1);
      expect(store.live['moves']!['m1']!.json['k'], 'changed');
      expect(store.live['moves']!['m1']!.clientOpId, 'b');
    });

    test('replay never double-applies (one row, idempotent state)', () async {
      final req = _push(upserts: [_up('m1', 1000, op: 'once')]);
      await applyPush(store, _uid, req);
      await applyPush(store, _uid, req);
      expect(store.live['moves']!.length, 1);
      expect(store.live['moves']!['m1']!.updatedAt, 1000);
      expect(store.live['moves']!['m1']!.clientOpId, 'once');
    });
  });

  group('delete → tombstone (never hard-delete)', () {
    test('delete of unknown record writes a tombstone only', () async {
      final r = await applyPush(store, _uid, _push(deletes: [_tomb('m1', 500)]));
      expect(r.applied, 1);
      expect(store.live['moves'] ?? const {}, isEmpty);
      expect(store.tombs['moves']!['m1']!.deletedAt, 500);
    });

    test('newer delete removes the live row and writes a tombstone', () async {
      await applyPush(store, _uid, _push(upserts: [_up('m1', 1000)]));
      final r = await applyPush(
        store,
        _uid,
        _push(deletes: [_tomb('m1', 2000, op: 'del')]),
      );
      expect(r.applied, 1);
      expect(store.live['moves']!.containsKey('m1'), isFalse);
      expect(store.tombs['moves']!['m1']!.deletedAt, 2000);
      expect(store.tombs['moves']!['m1']!.clientOpId, 'del');
    });

    test('older delete loses to a newer live edit (skipped)', () async {
      await applyPush(store, _uid, _push(upserts: [_up('m1', 3000)]));
      final r = await applyPush(
        store,
        _uid,
        _push(deletes: [_tomb('m1', 1000)]),
      );
      expect(r.applied, 0);
      expect(r.skipped, 1);
      expect(store.live['moves']!['m1']!.updatedAt, 3000);
      expect(store.tombs['moves'] ?? const {}, isEmpty);
    });
  });

  group('un-tombstone (a fresh upsert revives a deleted record)', () {
    test('newer upsert after a tombstone revives the live row', () async {
      await applyPush(store, _uid, _push(deletes: [_tomb('m1', 1000)]));
      final r = await applyPush(
        store,
        _uid,
        _push(upserts: [_up('m1', 2000, op: 'revive')]),
      );
      expect(r.applied, 1);
      expect(store.live['moves']!['m1']!.updatedAt, 2000);
      expect(store.live['moves']!['m1']!.clientOpId, 'revive');
      expect(store.tombs['moves']!.containsKey('m1'), isFalse);
    });

    test('older upsert after a tombstone stays deleted (skipped)', () async {
      await applyPush(store, _uid, _push(deletes: [_tomb('m1', 3000)]));
      final r = await applyPush(
        store,
        _uid,
        _push(upserts: [_up('m1', 1000)]),
      );
      expect(r.applied, 0);
      expect(r.skipped, 1);
      expect(store.live['moves'] ?? const {}, isEmpty);
      expect(store.tombs['moves']!['m1']!.deletedAt, 3000);
    });
  });

  group('rejections', () {
    test('fsrsCard push is forbidden', () {
      expect(
        () => applyPush(
          store,
          _uid,
          _push(table: 'fsrsCards', upserts: [_up('c1', 1)]),
        ),
        throwsA(isA<PushRejection>()),
      );
    });

    test('reviewEvent deletes are forbidden (append-only)', () {
      expect(
        () => applyPush(
          store,
          _uid,
          _push(table: 'reviewEvents', deletes: [_tomb('r1', 1)]),
        ),
        throwsA(isA<PushRejection>()),
      );
    });

    test('reviewEvent upserts are routed away from sync-push', () {
      expect(
        () => applyPush(
          store,
          _uid,
          _push(table: 'reviewEvents', upserts: [_up('r1', 1)]),
        ),
        throwsA(isA<PushRejection>()),
      );
    });

    test('unsupported table is rejected', () {
      expect(
        () => applyPush(
          store,
          _uid,
          _push(table: 'nope', upserts: [_up('x', 1)]),
        ),
        throwsA(isA<PushRejection>()),
      );
    });

    test('all five descriptive tables are accepted', () async {
      for (final t in descriptiveTables) {
        final r = await applyPush(
          store,
          _uid,
          _push(table: t, upserts: [_up('id', 1)]),
        );
        expect(r.applied, 1, reason: t);
      }
    });
  });

  group('per-record store-fault isolation (H.3)', () {
    test('a failing write is counted, batch continues', () async {
      store.failLiveWriteOnId.add('bad');
      final r = await applyPush(
        store,
        _uid,
        _push(
          upserts: [_up('good1', 1), _up('bad', 1), _up('good2', 1)],
        ),
      );
      expect(r.applied, 2);
      expect(r.failed, 1);
      expect(store.live['moves']!.containsKey('good1'), isTrue);
      expect(store.live['moves']!.containsKey('good2'), isTrue);
      expect(store.live['moves']!.containsKey('bad'), isFalse);
    });
  });

  group('body parsing (wire shape mirrors sync:pushRecords)', () {
    test('parses upserts + deletes with ms-epoch clocks', () {
      final req = PushRequest.fromJson({
        'table': 'moves',
        'upserts': [
          {
            'localId': 'm1',
            'json': {'name': 'Six Step', 'videoPointer': 'drive:abc'},
            'updatedAt': 1717200000000,
            'clientOpId': 'op-1',
          },
        ],
        'deletes': [
          {'localId': 'm2', 'deletedAt': 1717286400000, 'clientOpId': 'op-2'},
        ],
      });
      expect(req.table, 'moves');
      expect(req.upserts.single.id, 'm1');
      expect(req.upserts.single.updatedAt, 1717200000000);
      expect(req.upserts.single.json['videoPointer'], 'drive:abc');
      expect(req.deletes.single.id, 'm2');
      expect(req.deletes.single.deletedAt, 1717286400000);
    });

    test('missing table is rejected', () {
      expect(
        () => PushRequest.fromJson({'upserts': const <dynamic>[]}),
        throwsA(isA<PushRejection>()),
      );
    });

    test('malformed op is rejected', () {
      expect(
        () => PushRequest.fromJson({
          'table': 'moves',
          'upserts': [
            {'localId': 'm1'}, // missing updatedAt / clientOpId
          ],
        }),
        throwsA(isA<PushRejection>()),
      );
    });
  });
}
