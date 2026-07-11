import 'dart:async';

import 'package:breakdex/core/sync/backends/appwrite_sync_backend.dart';
import 'package:breakdex/core/sync/backends/appwrite_transport.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every call and returns canned values shaped exactly like the deployed
/// Functions (`sync-push`/`sync-pull`/`reviews-append`) and TablesDB rows emit —
/// so this proves the Dart marshalling + routing + subscribe cancellation, not a
/// live deployment.
// --- Parity gate (task 2.3) ------------------------------------------------
// This suite is the formal parity mirror of `convex_sync_backend_test.dart`:
// every one of the 9 Convex marshalling behaviours has a mirror here on the
// same fixtures, so 2.4 can delete the Convex substrate on a checkable basis.
//
//   Convex test                          →  Appwrite mirror (this file)
//   1 providerType is convex             →  'providerType is appwrite'
//   2 descriptive push ms epochs         →  'descriptive upsert + tombstone → sync-push …' (byte-identical body)
//   3 empty descriptive push no-op       →  'empty descriptive push is a no-op'
//   4 reviewEvent → append, flatten json →  'reviewEvent → reviews-append flattening json fields'
//   5 reviewEvent rejects deletes        →  'reviewEvent rejects deletes (append-only)'
//   6 fsrsCard push forbidden            →  'fsrsCard push is forbidden (derived state)'
//   7 descriptive pull decodes delta     →  'descriptive pull decodes upserts, tombstones, cursor'
//   8 full pull (since null) omits since →  'full descriptive pull (since null) omits the since key'  [ADAPTED ↓]
//   9 fsrsCard pull routing              →  'fsrsCard pull synthesizes composite id + lastEventOpId key'  [ADAPTED ↓]
//
// Two adaptations, forced by the routing split (2.2): Convex pulls every entity
// through a Function; Appwrite pulls reviewEvent/fsrsCard via direct TablesDB
// reads (no pull Function exists — the log is append-only, the card derived).
//   • #8 — Convex asserted "omits since" on the reviewEvent *Function* pull.
//     Here that assertion moves to a descriptive type (combo), still on the
//     Function path; reviewEvent's direct read gets its own fold test.
//   • #9 — Convex asserted fsrsCard routes to `fsrs:pullCards`. Here there is no
//     such Function, so the mirror asserts the direct-read convention instead:
//     the `entityType:entityId` composite id + `lastEventOpId` idempotency key.
//
// Round-trip guarantee under test: DateTime → ms (`millisecondsSinceEpoch`),
// exercised on every clock field. The task line also names "BigInt → string",
// but neither backend's Dart marshalling performs that conversion (clocks are
// ints, `json` passes through untouched) — there is no such Dart behaviour to
// mirror, so no test asserts one.
//
// Beyond the 9, this file adds the 2.2-specific rigor with no Convex twin:
// reviewEvent direct-read fold, empty-direct-pull cursor semantics, and the
// four subscribe tests (Realtime trigger, channel set, poll fallback, audit B1).

class _FakeTransport implements AppwriteTransport {
  final List<({String functionId, Map<String, Object?> body})> executions = [];
  final List<({String table, String orderField, int? since})> reads = [];
  final List<List<String>> subscribedChannels = [];

  Object? nextExecuteValue;
  List<Map<String, Object?>> nextRows = const [];

  /// When set, [channelEvents] returns its stream (reactive path); when null the
  /// backend falls back to interval polling.
  StreamController<void>? trigger;

  int get pullExecutions =>
      executions.where((final e) => e.functionId == 'sync-pull').length;

  @override
  Future<Object?> execute(
    final String functionId, {
    final Map<String, Object?> body = const {},
  }) async {
    executions.add((functionId: functionId, body: body));
    return nextExecuteValue;
  }

  @override
  Future<List<Map<String, Object?>>> listRows(
    final String table, {
    required final String orderField,
    final int? since,
  }) async {
    reads.add((table: table, orderField: orderField, since: since));
    return nextRows;
  }

  @override
  Stream<void>? channelEvents(final List<String> channels) {
    subscribedChannels.add(channels);
    return trigger?.stream;
  }
}

void main() {
  late _FakeTransport transport;
  late AppwriteSyncBackend backend;

  setUp(() {
    transport = _FakeTransport();
    backend = AppwriteSyncBackend(transport);
  });

  test('providerType is appwrite', () {
    expect(backend.providerType, 'appwrite');
  });

  group('push', () {
    test(
      'descriptive upsert + tombstone → sync-push with ms epochs',
      () async {
        final updated = DateTime.utc(2026, 6, 1);
        final deleted = DateTime.utc(2026, 6, 2);
        await backend.push(
          SyncEntityType.move,
          upserts: [
            SyncRecord(
              id: 'm1',
              type: SyncEntityType.move,
              json: {'name': 'Six Step', 'videoPointer': 'drive:abc'},
              updatedAt: updated,
              clientOpId: 'op-1',
            ),
          ],
          deletes: [
            SyncTombstone(
              id: 'm2',
              type: SyncEntityType.move,
              deletedAt: deleted,
              clientOpId: 'op-2',
            ),
          ],
        );

        expect(transport.executions, hasLength(1));
        final call = transport.executions.single;
        expect(call.functionId, 'sync-push');
        expect(call.body['table'], 'moves');
        expect((call.body['upserts']! as List).single, {
          'localId': 'm1',
          'json': {'name': 'Six Step', 'videoPointer': 'drive:abc'},
          'updatedAt': updated.millisecondsSinceEpoch,
          'clientOpId': 'op-1',
        });
        expect((call.body['deletes']! as List).single, {
          'localId': 'm2',
          'deletedAt': deleted.millisecondsSinceEpoch,
          'clientOpId': 'op-2',
        });
      },
    );

    test('empty descriptive push is a no-op (no execution)', () async {
      await backend.push(SyncEntityType.combo);
      expect(transport.executions, isEmpty);
    });

    test('reviewEvent → reviews-append flattening json fields', () async {
      final at = DateTime.utc(2026, 6, 3);
      await backend.push(
        SyncEntityType.reviewEvent,
        upserts: [
          SyncRecord(
            id: 'r1',
            type: SyncEntityType.reviewEvent,
            json: {'entityId': 'm1', 'entityType': 'move', 'rating': 2},
            updatedAt: at,
            clientOpId: 'op-r1',
          ),
        ],
      );

      final call = transport.executions.single;
      expect(call.functionId, 'reviews-append');
      expect((call.body['events']! as List).single, {
        'localId': 'r1',
        'entityId': 'm1',
        'entityType': 'move',
        'rating': 2,
        'reviewedAt': at.millisecondsSinceEpoch,
        'clientOpId': 'op-r1',
      });
    });

    test('reviewEvent rejects deletes (append-only)', () {
      expect(
        () => backend.push(
          SyncEntityType.reviewEvent,
          deletes: [
            SyncTombstone(
              id: 'r1',
              type: SyncEntityType.reviewEvent,
              deletedAt: DateTime.utc(2026),
              clientOpId: 'op',
            ),
          ],
        ),
        throwsStateError,
      );
    });

    test('fsrsCard push is forbidden (derived state)', () {
      expect(
        () => backend.push(
          SyncEntityType.fsrsCard,
          upserts: [
            SyncRecord(
              id: 'move:m1',
              type: SyncEntityType.fsrsCard,
              json: const {},
              updatedAt: DateTime.utc(2026),
              clientOpId: 'op',
            ),
          ],
        ),
        throwsStateError,
      );
    });
  });

  group('pull', () {
    test('descriptive pull decodes upserts, tombstones, cursor', () async {
      transport.nextExecuteValue = {
        'upserts': [
          {
            'id': 'm1',
            'json': {'name': 'Six Step'},
            'updatedAt': 1000,
            'clientOpId': 'op-1',
          },
        ],
        'deletes': [
          {'id': 'm2', 'deletedAt': 2000, 'clientOpId': 'op-2'},
        ],
        'cursor': 2000,
      };

      final delta = await backend.pull(
        SyncEntityType.move,
        since: DateTime.utc(2026),
      );

      final q = transport.executions.single;
      expect(q.functionId, 'sync-pull');
      expect(q.body['table'], 'moves');
      expect(q.body['since'], DateTime.utc(2026).millisecondsSinceEpoch);

      expect(delta.upserts.single.id, 'm1');
      expect(delta.upserts.single.type, SyncEntityType.move);
      expect(delta.upserts.single.json['name'], 'Six Step');
      expect(delta.deletes.single.id, 'm2');
      expect(delta.cursor, DateTime.fromMillisecondsSinceEpoch(2000));
    });

    test('full descriptive pull (since null) omits the since key', () async {
      transport.nextExecuteValue = {
        'upserts': <Object?>[],
        'deletes': <Object?>[],
        'cursor': null,
      };
      final delta = await backend.pull(SyncEntityType.combo);
      final q = transport.executions.single;
      expect(q.functionId, 'sync-pull');
      expect(q.body['table'], 'combos');
      expect(q.body.containsKey('since'), isFalse);
      expect(delta.isEmpty, isTrue);
      expect(delta.cursor, isNull);
    });

    test(
      'reviewEvent pull reads reviewEvents directly, folding json + cursor',
      () async {
        transport.nextRows = [
          {
            'id': 'r1',
            'entityId': 'm1',
            'entityType': 'move',
            'rating': 2,
            'reviewedAt': 1500,
            'clientOpId': 'op-r1',
          },
        ];
        final delta = await backend.pull(
          SyncEntityType.reviewEvent,
          since: DateTime.fromMillisecondsSinceEpoch(1000),
        );

        expect(transport.executions, isEmpty, reason: 'no pull Function exists');
        final read = transport.reads.single;
        expect(read.table, 'reviewEvents');
        expect(read.orderField, 'reviewedAt');
        expect(read.since, 1000);

        final rec = delta.upserts.single;
        expect(rec.id, 'r1');
        expect(rec.type, SyncEntityType.reviewEvent);
        expect(rec.json, {'entityId': 'm1', 'entityType': 'move', 'rating': 2});
        expect(rec.clientOpId, 'op-r1');
        expect(delta.deletes, isEmpty);
        expect(delta.cursor, DateTime.fromMillisecondsSinceEpoch(1500));
      },
    );

    test('fsrsCard pull synthesizes composite id + lastEventOpId key', () async {
      transport.nextRows = [
        {
          'entityId': 'm1',
          'entityType': 'move',
          'stability': 3.2,
          'difficulty': 5.0,
          'due': 2000,
          'state': 2,
          'lastEventOpId': 'op-r7',
          'updatedAt': 1800,
        },
      ];
      final delta = await backend.pull(SyncEntityType.fsrsCard);

      final read = transport.reads.single;
      expect(read.table, 'fsrsCards');
      expect(read.orderField, 'updatedAt');
      expect(read.since, isNull);

      final rec = delta.upserts.single;
      expect(rec.id, 'move:m1');
      expect(rec.type, SyncEntityType.fsrsCard);
      expect(rec.clientOpId, 'op-r7');
      expect(rec.json['stability'], 3.2);
      expect(rec.json['state'], 2);
      expect(delta.cursor, DateTime.fromMillisecondsSinceEpoch(1800));
    });

    test('empty direct pull keeps the since cursor unchanged', () async {
      transport.nextRows = const [];
      final since = DateTime.fromMillisecondsSinceEpoch(1234);
      final delta = await backend.pull(SyncEntityType.fsrsCard, since: since);
      expect(delta.isEmpty, isTrue);
      expect(delta.cursor, since);
    });
  });

  group('subscribe', () {
    test('descriptive subscribe watches its table + tombstones channels', () async {
      transport.trigger = StreamController<void>();
      transport.nextExecuteValue = {
        'upserts': <Object?>[],
        'deletes': <Object?>[],
        'cursor': null,
      };
      final sub = backend.subscribe(SyncEntityType.move).listen((final _) {});
      expect(transport.subscribedChannels.single, [
        'databases.breakdex.tables.moves.rows',
        'databases.breakdex.tables.tombstones.rows',
      ]);
      await sub.cancel();
      await transport.trigger!.close();
    });

    test('a Realtime trigger drives a cursor-advancing re-pull', () async {
      final trigger = StreamController<void>();
      transport.trigger = trigger;
      transport.nextExecuteValue = {
        'upserts': [
          {
            'id': 'm1',
            'json': {'name': 'x'},
            'updatedAt': 1000,
            'clientOpId': 'op-1',
          },
        ],
        'deletes': <Object?>[],
        'cursor': 1000,
      };

      final deltas = <SyncDelta>[];
      final sub = backend.subscribe(SyncEntityType.move).listen(deltas.add);

      await pumpEventQueue(); // initial pull
      expect(deltas, hasLength(1));
      expect(transport.pullExecutions, 1);

      trigger.add(null);
      await pumpEventQueue();
      expect(transport.pullExecutions, 2);
      // cursor advanced: the second pull carried the prior high-water mark.
      expect(transport.executions.last.body['since'], 1000);

      await sub.cancel();
      await trigger.close();
    });

    test('cancellation stops all I/O (audit B1)', () async {
      final trigger = StreamController<void>();
      transport.trigger = trigger;
      transport.nextExecuteValue = {
        'upserts': <Object?>[],
        'deletes': <Object?>[],
        'cursor': null,
      };

      final sub = backend.subscribe(SyncEntityType.move).listen((final _) {});
      await pumpEventQueue();
      expect(transport.pullExecutions, 1, reason: 'initial pull');

      trigger.add(null);
      await pumpEventQueue();
      expect(transport.pullExecutions, 2);

      await sub.cancel();
      expect(
        trigger.hasListener,
        isFalse,
        reason: 'transport-side stream released on cancel',
      );

      // Any trigger after cancel must not start new I/O.
      trigger.add(null);
      await pumpEventQueue();
      expect(transport.pullExecutions, 2);

      await trigger.close();
    });

    test('poll fallback pulls on the interval and stops on cancel', () {
      fakeAsync((final async) {
        // No trigger set → channelEvents returns null → interval polling.
        transport.nextExecuteValue = {
          'upserts': <Object?>[],
          'deletes': <Object?>[],
          'cursor': null,
        };
        backend = AppwriteSyncBackend(
          transport,
          pollInterval: const Duration(seconds: 5),
        );

        final sub = backend.subscribe(SyncEntityType.move).listen((final _) {});
        async.flushMicrotasks();
        expect(transport.pullExecutions, 1, reason: 'initial pull');

        async.elapse(const Duration(seconds: 12)); // two poll ticks
        expect(transport.pullExecutions, 3);

        unawaited(sub.cancel());
        async.elapse(const Duration(seconds: 20)); // timer torn down
        expect(transport.pullExecutions, 3, reason: 'no polling after cancel');
      });
    });
  });
}
