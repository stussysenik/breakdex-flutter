import 'package:breakdex/core/sync/backends/convex_sync_backend.dart';
import 'package:breakdex/core/sync/backends/convex_transport.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every call and returns canned query values shaped exactly like the
/// Convex functions in `convex/` emit — so this proves the Dart marshalling,
/// not a live deployment.
class _FakeTransport implements ConvexTransport {
  final List<({String path, Map<String, Object?> args})> mutations = [];
  final List<({String path, Map<String, Object?> args})> queries = [];
  Object? nextQueryValue;

  @override
  Future<Object?> mutation(
    final String path, {
    final Map<String, Object?> args = const {},
  }) async {
    mutations.add((path: path, args: args));
    return null;
  }

  @override
  Future<Object?> query(
    final String path, {
    final Map<String, Object?> args = const {},
  }) async {
    queries.add((path: path, args: args));
    return nextQueryValue;
  }

  @override
  Stream<Object?>? watch(
    final String path, {
    final Map<String, Object?> args = const {},
  }) => null;
}

void main() {
  late _FakeTransport transport;
  late ConvexSyncBackend backend;

  setUp(() {
    transport = _FakeTransport();
    backend = ConvexSyncBackend(transport);
  });

  test('providerType is convex', () {
    expect(backend.providerType, 'convex');
  });

  group('push', () {
    test(
      'descriptive upsert + tombstone → sync:pushRecords with ms epochs',
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

        expect(transport.mutations, hasLength(1));
        final call = transport.mutations.single;
        expect(call.path, 'sync:pushRecords');
        expect(call.args['table'], 'moves');
        final upserts = call.args['upserts']! as List;
        expect(upserts.single, {
          'localId': 'm1',
          'json': {'name': 'Six Step', 'videoPointer': 'drive:abc'},
          'updatedAt': updated.millisecondsSinceEpoch,
          'clientOpId': 'op-1',
        });
        final deletes = call.args['deletes']! as List;
        expect(deletes.single, {
          'localId': 'm2',
          'deletedAt': deleted.millisecondsSinceEpoch,
          'clientOpId': 'op-2',
        });
      },
    );

    test('empty descriptive push is a no-op (no mutation)', () async {
      await backend.push(SyncEntityType.combo);
      expect(transport.mutations, isEmpty);
    });

    test(
      'reviewEvent → reviews:appendReviewEvents flattening json fields',
      () async {
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

        final call = transport.mutations.single;
        expect(call.path, 'reviews:appendReviewEvents');
        final events = call.args['events']! as List;
        expect(events.single, {
          'localId': 'r1',
          'entityId': 'm1',
          'entityType': 'move',
          'rating': 2,
          'reviewedAt': at.millisecondsSinceEpoch,
          'clientOpId': 'op-r1',
        });
      },
    );

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
      transport.nextQueryValue = {
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

      final q = transport.queries.single;
      expect(q.path, 'sync:pullRecords');
      expect(q.args['table'], 'moves');
      expect(q.args['since'], DateTime.utc(2026).millisecondsSinceEpoch);

      expect(delta.upserts.single.id, 'm1');
      expect(delta.upserts.single.type, SyncEntityType.move);
      expect(delta.upserts.single.json['name'], 'Six Step');
      expect(delta.deletes.single.id, 'm2');
      expect(delta.cursor, DateTime.fromMillisecondsSinceEpoch(2000));
    });

    test('full pull (since null) omits the since arg', () async {
      transport.nextQueryValue = {
        'upserts': <Object?>[],
        'deletes': <Object?>[],
        'cursor': null,
      };
      final delta = await backend.pull(SyncEntityType.reviewEvent);
      expect(transport.queries.single.path, 'reviews:pullReviewEvents');
      expect(transport.queries.single.args.containsKey('since'), isFalse);
      expect(transport.queries.single.args.containsKey('table'), isFalse);
      expect(delta.isEmpty, isTrue);
      expect(delta.cursor, isNull);
    });

    test('fsrsCard pull routes to fsrs:pullCards', () async {
      transport.nextQueryValue = {
        'upserts': <Object?>[],
        'deletes': <Object?>[],
        'cursor': null,
      };
      await backend.pull(SyncEntityType.fsrsCard);
      expect(transport.queries.single.path, 'fsrs:pullCards');
    });
  });
}
