/// Pure FSRS derivation core for the `reviews-append` Appwrite Function.
///
/// A card's scheduling state (`stability` / `difficulty` / `due` / `state`) is a
/// **reduction of its `reviewEvents` log** — never client-pushed (Decision 7).
/// [deriveCard] folds an entity's ordered events through the *same* `fsrs`
/// package the Flutter client runs (`fsrs: ^2.0.1`), replaying each review with
/// its recorded `reviewedAt` as `reviewDateTime`. Between events it reconstructs
/// the card exactly as the client's `FsrsService._dbToFsrs` does on reload —
/// projecting to `(state, stability, difficulty, due, lastReview)` and rebuilding
/// `step` as `0` for learning/relearning, `null` for review — so the fold is
/// byte-identical to the client's persist→reload loop regardless of step config.
///
/// **Determinism (why fuzzing is forced off).** The client scheduler defaults to
/// `enableFuzzing: true`, and the package's fuzz draws from an *unseeded*
/// `math.Random()`, applied to Review-state intervals ≥ 2.5 days. A server replay
/// therefore cannot reproduce a live-fuzzed `due`. This core runs the scheduler
/// with `enableFuzzing: false`, which is the only choice under which the derive
/// is deterministic and idempotent (re-deriving an unchanged log yields the
/// identical row → no pull-cursor churn) and under which Phase 4.6's
/// "tolerance: exact — same math" is even meaningful: `stability` / `difficulty`
/// / `state` match the client exactly, and `due` equals the client's *canonical
/// unfuzzed* interval. The fuzz is a deliberate client-side cosmetic jitter on
/// the interval, explicitly not part of "the math".
///
/// State-enum gotcha (repo memory): the `fsrs` `State` enum is `1`-based
/// (`learning=1, review=2, relearning=3`); the DB/backend uses `0` as a custom
/// "new" convention. An entity with ≥ 1 event is never `0` here (the first
/// review graduates it out of "new"), so a [DerivedCard.state] is always 1–3.
library;

import 'package:fsrs/fsrs.dart' as fsrs;

/// Scheduler parameters, mirroring the client's `FsrsSettings`. Defaults equal
/// `FsrsSettings.defaults` (the behavior-preserving baseline), with the same
/// clamps the client applies before constructing its `fsrs.Scheduler`. Per-user
/// overrides are prefs-only on-device and not yet synced to the backend; wiring
/// them here is future plumbing — until then the derive uses these defaults.
class DeriveConfig {
  const DeriveConfig._({
    required this.desiredRetention,
    required this.learningSteps,
    required this.relearningSteps,
    required this.maximumInterval,
  });

  /// Build a config, applying the same clamps the client applies before
  /// constructing its `fsrs.Scheduler` (retention → [0.70, 0.97], interval ≥ 1).
  factory DeriveConfig({
    final double desiredRetention = 0.85,
    final List<Duration> learningSteps = const [Duration(minutes: 10)],
    final List<Duration> relearningSteps = const [Duration(minutes: 10)],
    final int maximumInterval = 36500,
  }) =>
      DeriveConfig._(
        desiredRetention: _clampRetention(desiredRetention),
        learningSteps: learningSteps,
        relearningSteps: relearningSteps,
        maximumInterval: maximumInterval < 1 ? 1 : maximumInterval,
      );

  final double desiredRetention;
  final List<Duration> learningSteps;
  final List<Duration> relearningSteps;
  final int maximumInterval;

  /// The behavior-preserving baseline — equals `FsrsSettings.defaults`.
  static const DeriveConfig defaults = DeriveConfig._(
    desiredRetention: 0.85,
    learningSteps: [Duration(minutes: 10)],
    relearningSteps: [Duration(minutes: 10)],
    maximumInterval: 36500,
  );

  static double _clampRetention(final double v) =>
      v < 0.70 ? 0.70 : (v > 0.97 ? 0.97 : v);
}

/// The reduced, backend-shaped card. `due`/`updatedAt` are ms-epoch ints (the
/// `fsrsCards` column types authored in task 1.1); `stability`/`difficulty` are
/// always non-null because a derived card has folded ≥ 1 event.
class DerivedCard {
  const DerivedCard({
    required this.stability,
    required this.difficulty,
    required this.due,
    required this.state,
    required this.lastEventOpId,
    required this.updatedAt,
  });

  final double stability;
  final double difficulty;
  final int due; // ms since epoch (UTC)
  final int state; // fsrs State value: 1=learning 2=review 3=relearning
  final String lastEventOpId; // watermark: last event folded into this state
  final int updatedAt; // ms since epoch = newest reviewedAt in the log
}

/// One review, projected from a `reviewEvents` row. `rating` is the DB index
/// (`0=again 1=hard 2=good 3=easy`) — offset from the `fsrs` `Rating` enum
/// (`again=1…easy=4`), so it is mapped explicitly, never via `Rating.fromValue`.
class DerivableEvent {
  const DerivableEvent({
    required this.rating,
    required this.reviewedAt,
    required this.clientOpId,
  });

  final int rating;
  final int reviewedAt; // ms since epoch
  final String clientOpId;
}

/// Fold an entity's [events] (ordered oldest→newest) into its card state, or
/// `null` for an empty log (nothing to derive). [entityId] seeds the fsrs
/// `cardId` the way the client does (`entityId.hashCode`); with fuzzing off it
/// is a pure identifier and does not affect the schedule.
DerivedCard? deriveCard(
  final String entityId,
  final List<DerivableEvent> events, {
  final DeriveConfig config = DeriveConfig.defaults,
}) {
  if (events.isEmpty) {
    return null;
  }

  final scheduler = fsrs.Scheduler(
    desiredRetention: config.desiredRetention,
    learningSteps: config.learningSteps,
    relearningSteps: config.relearningSteps,
    maximumInterval: config.maximumInterval,
    enableFuzzing: false,
  );
  final cardId = entityId.hashCode;

  // Projection = exactly what the client persists between reviews: it starts at
  // the "new" convention (state 0, zeroed S/D, no lastReview).
  var state = 0;
  var stability = 0.0;
  var difficulty = 0.0;
  DateTime? lastReview;
  // Seed `due` is irrelevant to a new card's first review (no lastReview ⇒ zero
  // elapsed, no retrievability term); use the first event's time for cleanliness.
  var due = DateTime.fromMillisecondsSinceEpoch(events.first.reviewedAt, isUtc: true);

  for (final e in events) {
    final card = _reconstruct(
      cardId: cardId,
      state: state,
      stability: stability,
      difficulty: difficulty,
      due: due,
      lastReview: lastReview,
    );
    final reviewedAt =
        DateTime.fromMillisecondsSinceEpoch(e.reviewedAt, isUtc: true);
    final result = scheduler.reviewCard(
      card,
      _mapRating(e.rating),
      reviewDateTime: reviewedAt,
    );
    final c = result.card;
    state = c.state.value;
    stability = c.stability ?? 0.0;
    difficulty = c.difficulty ?? 0.0;
    due = c.due;
    lastReview = c.lastReview ?? reviewedAt;
  }

  final last = events.last;
  return DerivedCard(
    stability: stability,
    difficulty: difficulty,
    due: due.toUtc().millisecondsSinceEpoch,
    state: state,
    lastEventOpId: last.clientOpId,
    updatedAt: last.reviewedAt,
  );
}

/// Rebuild the `fsrs.Card` for the next review exactly as the client's
/// `_dbToFsrs` does: a state-0 ("new") card becomes a fresh learning card at
/// step 0; otherwise `step` is `0` for learning/relearning and `null` for
/// review, and S/D are dropped when non-positive (never reviewed).
fsrs.Card _reconstruct({
  required final int cardId,
  required final int state,
  required final double stability,
  required final double difficulty,
  required final DateTime due,
  required final DateTime? lastReview,
}) {
  if (state == 0) {
    return fsrs.Card(
      cardId: cardId,
      state: fsrs.State.learning,
      step: 0,
      due: due.toUtc(),
    );
  }
  return fsrs.Card(
    cardId: cardId,
    state: fsrs.State.fromValue(state),
    step: (state == 1 || state == 3) ? 0 : null,
    stability: stability > 0 ? stability : null,
    difficulty: difficulty > 0 ? difficulty : null,
    due: due.toUtc(),
    lastReview: lastReview?.toUtc(),
  );
}

/// DB rating index → `fsrs.Rating`. Explicit (not `fromValue`) because the DB is
/// 0-based (`0=again`) while the enum is 1-based (`again=1`).
fsrs.Rating _mapRating(final int dbRating) => switch (dbRating) {
      0 => fsrs.Rating.again,
      1 => fsrs.Rating.hard,
      2 => fsrs.Rating.good,
      3 => fsrs.Rating.easy,
      _ => throw ArgumentError('invalid rating index: $dbRating'),
    };
