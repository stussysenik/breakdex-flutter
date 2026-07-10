import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:reviews_append/derive.dart';
import 'package:test/test.dart';

/// Independent reference fold, transcribed from the Flutter client's
/// `FsrsService` (`_dbToFsrs` reconstruction + `processReview` projection) with
/// fuzzing off. `deriveCard` must reproduce this exactly; a divergence between
/// the two implementations surfaces here.
({int state, double stability, double difficulty, DateTime due})
    clientReferenceFold(
  final String entityId,
  final List<({int rating, int reviewedAt})> events,
) {
  final scheduler = fsrs.Scheduler(
    desiredRetention: 0.85,
    learningSteps: const [Duration(minutes: 10)],
    relearningSteps: const [Duration(minutes: 10)],
    maximumInterval: 36500,
    enableFuzzing: false,
  );
  final cardId = entityId.hashCode;

  var state = 0;
  var stability = 0.0;
  var difficulty = 0.0;
  DateTime? lastReview;
  var due =
      DateTime.fromMillisecondsSinceEpoch(events.first.reviewedAt, isUtc: true);

  for (final e in events) {
    // _dbToFsrs reconstruction.
    final fsrs.Card card;
    if (state == 0) {
      card = fsrs.Card(
        cardId: cardId,
        state: fsrs.State.learning,
        step: 0,
        due: due.toUtc(),
      );
    } else {
      card = fsrs.Card(
        cardId: cardId,
        state: fsrs.State.fromValue(state),
        step: (state == 1 || state == 3) ? 0 : null,
        stability: stability > 0 ? stability : null,
        difficulty: difficulty > 0 ? difficulty : null,
        due: due.toUtc(),
        lastReview: lastReview?.toUtc(),
      );
    }
    final reviewedAt =
        DateTime.fromMillisecondsSinceEpoch(e.reviewedAt, isUtc: true);
    final result = scheduler.reviewCard(
      card,
      switch (e.rating) {
        0 => fsrs.Rating.again,
        1 => fsrs.Rating.hard,
        2 => fsrs.Rating.good,
        _ => fsrs.Rating.easy,
      },
      reviewDateTime: reviewedAt,
    );
    state = result.card.state.value;
    stability = result.card.stability ?? 0.0;
    difficulty = result.card.difficulty ?? 0.0;
    due = result.card.due;
    lastReview = result.card.lastReview ?? reviewedAt;
  }
  return (state: state, stability: stability, difficulty: difficulty, due: due);
}

DerivableEvent ev(final int rating, final int reviewedAt, [final String? op]) =>
    DerivableEvent(
      rating: rating,
      reviewedAt: reviewedAt,
      clientOpId: op ?? 'op-$reviewedAt',
    );

void main() {
  // A day in ms — review timestamps spaced realistically so intervals advance.
  const day = 86400000;
  const t0 = 1751760000000; // fixed UTC ms epoch (2025-07-06)

  group('deriveCard matches the client scheduler fold', () {
    test('single good review on a new card', () {
      final events = [ev(2, t0)];
      final card = deriveCard('move-a', events)!;
      final ref = clientReferenceFold(
        'move-a',
        events.map((final e) => (rating: e.rating, reviewedAt: e.reviewedAt)).toList(),
      );

      expect(card.state, ref.state);
      expect(card.stability, closeTo(ref.stability, 1e-9));
      expect(card.difficulty, closeTo(ref.difficulty, 1e-9));
      expect(card.due, ref.due.toUtc().millisecondsSinceEpoch);
    });

    test('mixed multi-review sequence (again/hard/good/easy) over days', () {
      final events = [
        ev(2, t0), // good
        ev(0, t0 + day), // again (lapse path once in review)
        ev(1, t0 + 2 * day), // hard
        ev(2, t0 + 3 * day), // good
        ev(3, t0 + 10 * day), // easy
      ];
      final card = deriveCard('combo-x', events)!;
      final ref = clientReferenceFold(
        'combo-x',
        events.map((final e) => (rating: e.rating, reviewedAt: e.reviewedAt)).toList(),
      );

      expect(card.state, ref.state);
      expect(card.stability, closeTo(ref.stability, 1e-9));
      expect(card.difficulty, closeTo(ref.difficulty, 1e-9));
      expect(card.due, ref.due.toUtc().millisecondsSinceEpoch);
    });
  });

  group('invariants', () {
    test('empty log derives nothing', () {
      expect(deriveCard('move-a', const []), isNull);
    });

    test('state is always 1..3 after ≥1 review — never the DB "new" 0', () {
      // State-enum gotcha: fsrs State is 1-based; 0 is our DB-only "new".
      for (final rating in [0, 1, 2, 3]) {
        final card = deriveCard('move-$rating', [ev(rating, t0)])!;
        expect(card.state, inInclusiveRange(1, 3));
      }
    });

    test('derivation is deterministic (fuzzing off — no Random)', () {
      final events = [ev(2, t0), ev(2, t0 + day), ev(3, t0 + 5 * day)];
      final a = deriveCard('move-a', events)!;
      final b = deriveCard('move-a', events)!;
      expect(a.due, b.due);
      expect(a.stability, b.stability);
      expect(a.difficulty, b.difficulty);
      expect(a.state, b.state);
    });

    test('updatedAt is the newest reviewedAt; watermark is the last opId', () {
      final events = [
        ev(2, t0, 'op-1'),
        ev(2, t0 + day, 'op-2'),
        ev(3, t0 + 3 * day, 'op-3'),
      ];
      final card = deriveCard('move-a', events)!;
      expect(card.updatedAt, t0 + 3 * day);
      expect(card.lastEventOpId, 'op-3');
    });

    test('due is a valid UTC ms epoch strictly after the last review', () {
      final events = [ev(2, t0), ev(3, t0 + day)];
      final card = deriveCard('move-a', events)!;
      expect(card.due, greaterThan(t0 + day));
    });
  });

  group('config', () {
    test('retention and interval are clamped like the client', () {
      final c = DeriveConfig(desiredRetention: 0.5, maximumInterval: -3);
      expect(c.desiredRetention, 0.70);
      expect(c.maximumInterval, 1);
    });
  });
}
