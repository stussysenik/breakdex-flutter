import 'package:reviews_append/append.dart';
import 'package:reviews_append/derive.dart';
import 'package:test/test.dart';

/// In-memory [AppendStore]: an append-only event list + a card map, keyed by the
/// trusted `userId`. Mirrors the TablesDB store's observable behavior with no
/// live backend.
class FakeAppendStore implements AppendStore {
  final List<_Ev> events = [];
  final Map<String, DerivedCard> cards = {};

  String _cardKey(final String userId, final EntityKey e) =>
      '$userId|${e.entityType}|${e.entityId}';

  @override
  Future<bool> hasEvent(final String userId, final String clientOpId) async =>
      events.any((final e) => e.userId == userId && e.op.clientOpId == clientOpId);

  @override
  Future<void> insertEvent(
      final String userId, final ReviewEventOp event) async {
    events.add(_Ev(userId, event));
  }

  @override
  Future<List<DerivableEvent>> listEventsForEntity(
      final String userId, final EntityKey entity) async {
    final matching = events
        .where((final e) =>
            e.userId == userId &&
            e.op.entityType == entity.entityType &&
            e.op.entityId == entity.entityId)
        .toList()
      ..sort((final a, final b) => a.op.reviewedAt.compareTo(b.op.reviewedAt));
    return matching
        .map((final e) => DerivableEvent(
              rating: e.op.rating,
              reviewedAt: e.op.reviewedAt,
              clientOpId: e.op.clientOpId,
            ))
        .toList();
  }

  @override
  Future<void> upsertCard(
      final String userId, final EntityKey entity, final DerivedCard card) async {
    cards[_cardKey(userId, entity)] = card;
  }
}

class _Ev {
  _Ev(this.userId, this.op);
  final String userId;
  final ReviewEventOp op;
}

/// Store whose derive-path read faults once, to exercise H.3 isolation.
class DeriveFaultStore extends FakeAppendStore {
  @override
  Future<List<DerivableEvent>> listEventsForEntity(
      final String userId, final EntityKey entity) async {
    throw StateError('transient read fault');
  }
}

ReviewEventOp op({
  required final String opId,
  final String entityId = 'move-a',
  final String entityType = 'move',
  final int rating = 2,
  final int reviewedAt = 1751760000000,
}) =>
    ReviewEventOp(
      localId: 'local-$opId',
      entityId: entityId,
      entityType: entityType,
      rating: rating,
      reviewedAt: reviewedAt,
      clientOpId: opId,
    );

const user = 'user-1';

void main() {
  group('applyAppend — idempotent ingestion', () {
    test('appends new events and derives the touched entity', () async {
      final store = FakeAppendStore();
      final req = AppendRequest(events: [op(opId: 'a', reviewedAt: 1751760000000)]);

      final r = await applyAppend(store, user, req);

      expect(r.appended, 1);
      expect(r.skipped, 0);
      expect(r.derived, 1);
      expect(r.failed, 0);
      expect(store.events, hasLength(1));
      expect(store.cards, hasLength(1));
    });

    test('replaying a batch skips duplicates and does not re-derive', () async {
      final store = FakeAppendStore();
      final req = AppendRequest(events: [op(opId: 'a')]);

      await applyAppend(store, user, req);
      final replay = await applyAppend(store, user, req);

      expect(replay.appended, 0);
      expect(replay.skipped, 1);
      expect(replay.derived, 0); // no new event ⇒ no re-derive
      expect(store.events, hasLength(1)); // log stayed append-only
    });

    test('one entity reviewed twice in a batch derives once', () async {
      final store = FakeAppendStore();
      final req = AppendRequest(events: [
        op(opId: 'a', reviewedAt: 1751760000000),
        op(opId: 'b', reviewedAt: 1751846400000),
      ]);

      final r = await applyAppend(store, user, req);

      expect(r.appended, 2);
      expect(r.derived, 1); // both touch move-a ⇒ collapsed to one derive
    });

    test('distinct entities each derive', () async {
      final store = FakeAppendStore();
      final req = AppendRequest(events: [
        op(opId: 'a', entityId: 'move-a'),
        op(opId: 'b', entityId: 'combo-b', entityType: 'combo'),
      ]);

      final r = await applyAppend(store, user, req);

      expect(r.derived, 2);
      expect(store.cards, hasLength(2));
    });

    test('userId is scoped — another user never sees the events', () async {
      final store = FakeAppendStore();
      await applyAppend(store, user, AppendRequest(events: [op(opId: 'a')]));

      // A different user replaying the same opId is NOT a duplicate for them.
      final r = await applyAppend(
          store, 'user-2', AppendRequest(events: [op(opId: 'a')]));
      expect(r.skipped, 0);
      expect(r.appended, 1);
    });
  });

  group('H.3 fault isolation', () {
    test('a derive fault increments failed without aborting', () async {
      final store = DeriveFaultStore();
      final errors = <String>[];
      final r = await applyAppend(
        store,
        user,
        AppendRequest(events: [op(opId: 'a')]),
        onError: errors.add,
      );

      expect(r.appended, 1); // event still landed
      expect(r.derived, 0);
      expect(r.failed, 1);
      expect(errors.single, contains('derive failed'));
    });
  });

  group('AppendRequest.fromJson — wire parsing', () {
    test('parses the Convex appendReviewEvents shape', () {
      final req = AppendRequest.fromJson(<String, dynamic>{
        'events': [
          <String, dynamic>{
            'localId': 'r1',
            'entityId': 'move-a',
            'entityType': 'move',
            'rating': 2,
            'reviewedAt': 1751760000000,
            'clientOpId': 'op-1',
          },
        ],
      });
      expect(req.events, hasLength(1));
      expect(req.events.single.entity, const EntityKey('move', 'move-a'));
    });

    test('rejects a missing events array', () {
      expect(() => AppendRequest.fromJson(<String, dynamic>{}),
          throwsA(isA<AppendRejection>()));
    });

    test('rejects an out-of-range rating', () {
      expect(
        () => AppendRequest.fromJson(<String, dynamic>{
          'events': [
            <String, dynamic>{
              'localId': 'r1',
              'entityId': 'move-a',
              'entityType': 'move',
              'rating': 9,
              'reviewedAt': 1751760000000,
              'clientOpId': 'op-1',
            },
          ],
        }),
        throwsA(isA<AppendRejection>()),
      );
    });

    test('rejects a missing clientOpId (idempotency key)', () {
      expect(
        () => AppendRequest.fromJson(<String, dynamic>{
          'events': [
            <String, dynamic>{
              'localId': 'r1',
              'entityId': 'move-a',
              'entityType': 'move',
              'rating': 2,
              'reviewedAt': 1751760000000,
            },
          ],
        }),
        throwsA(isA<AppendRejection>()),
      );
    });
  });
}
