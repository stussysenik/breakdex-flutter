import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../database/database.dart';
import '../database/daos/fsrs_cards_dao.dart';
import '../models/fsrs_settings.dart';
import '../models/learning_state.dart';
import '../models/reviewable_item.dart';
import '../utils/app_clock.dart';

/// Anki-style due count breakdown by card state.
///
/// FSRS categorizes cards into states. The app mirrors Anki's
/// "New / Learning / Review" breakdown for due cards before a session starts.
class DueSummary {
  /// Cards never reviewed (fsrsState==0), due now.
  final int newDue;

  /// Cards in Learning or Relearning state (fsrsState==1 or 3), due now.
  final int learningDue;

  /// Cards in Review state (fsrsState==2), due now.
  final int reviewDue;

  /// All cards due by end of today.
  final int totalDueToday;

  /// Cards due between end of today and end of tomorrow.
  final int dueTomorrow;

  /// Sum of all currently-due cards (new + learning + review).
  int get totalDueNow => newDue + learningDue + reviewDue;

  const DueSummary({
    required this.newDue,
    required this.learningDue,
    required this.reviewDue,
    required this.totalDueToday,
    required this.dueTomorrow,
  });
}

/// Total card counts by FSRS state — independent of due dates.
///
/// Unlike [DueSummary] which only counts currently-due cards, this gives
/// the full picture of where all cards sit in the learning pipeline.
/// Used by the Stats screen to show accurate NEW / LEARN / MASTERY totals.
class TotalStateCounts {
  /// Cards never reviewed (fsrsState == 0).
  final int newCount;

  /// Cards in Learning/Relearning state (fsrsState == 1 or 3).
  final int learningCount;

  /// Cards in Review/mastered state (fsrsState == 2).
  final int reviewCount;

  int get total => newCount + learningCount + reviewCount;

  const TotalStateCounts({
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
  });
}

/// Per-category mastery data for the pre-screen display.
class CategoryMastery {
  final String category;
  final int totalCards;
  final int newCount;
  final int learningCount;
  final int reviewCount;
  final int dueCount;

  const CategoryMastery({
    required this.category,
    required this.totalCards,
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
    required this.dueCount,
  });

  /// Mastery percentage: cards in Review state / total cards.
  double get masteryPercent => totalCards > 0 ? reviewCount / totalCards : 0.0;
}

/// Result of processing an FSRS review, containing scheduling data and
/// state transitions needed for graduation streak tracking.
class FsrsReviewResult {
  /// Next due date for this card.
  final DateTime dueDate;

  /// FSRS state before this review (0=New, 1=Learning, 2=Review, 3=Relearning).
  final int preState;

  /// FSRS state after this review.
  final int postState;

  /// Whether the card "graduated" — transitioned into Review state (2)
  /// from a non-Review state.
  bool get isGraduation => preState != 2 && postState == 2;

  const FsrsReviewResult({
    required this.dueDate,
    required this.preState,
    required this.postState,
  });
}

/// Static FSRS configuration exposed to the UI.
///
/// Lets the schedule screen show the algorithm parameters so learners
/// understand *why* their reviews are spaced the way they are.
class FsrsConfig {
  final double desiredRetention;
  final List<Duration> learningSteps;
  final List<Duration> relearningSteps;
  final int maximumInterval;
  final bool enableFuzzing;

  const FsrsConfig({
    required this.desiredRetention,
    required this.learningSteps,
    required this.relearningSteps,
    required this.maximumInterval,
    required this.enableFuzzing,
  });
}

/// Bridges the `fsrs` package with the local database.
///
/// ## How FSRS works (for learners reading this code)
///
/// FSRS models human memory using two key variables:
///
/// 1. **Stability (S)**: The number of days it takes for retrievability to
///    drop from 100% to the desired retention rate (e.g. 85%). Higher
///    stability = longer intervals between reviews.
///
/// 2. **Difficulty (D)**: A 0–10 scale representing how inherently hard
///    the item is to remember. Updated after each review based on rating.
///
/// The **forgetting curve** formula is: R(t) = (1 + t/(9*S))^(-1)
/// where t = elapsed days since last review, S = stability.
///
/// ## Why 0.85 retention for motor skills
///
/// Academic SRS apps typically use 0.9 (90%). Breakdancing moves are motor
/// skills — once your body learns a windmill, it decays slower than a
/// vocabulary word. We use 0.85 to space reviews further apart, reducing
/// review fatigue while still maintaining muscle memory.
class FsrsService {
  final FsrsCardsDao _dao;
  final AppClock _clock;
  final fsrs.Scheduler _scheduler;

  /// [clock] is the single trusted time source. It defaults to [SystemClock]
  /// so direct constructions keep working, but production wires in the
  /// app-wide [appClockProvider] so all scheduling reads "now" from one seam
  /// (deterministic under test, and a future hook for trusted/NTP time).
  ///
  /// [settings] supplies the scheduler parameters. It defaults to
  /// [FsrsSettings.defaults] — the prior hardcoded constants — so existing
  /// direct constructions and tests schedule identically. In production
  /// `fsrsServiceProvider` injects the user's persisted settings and rebuilds
  /// the service when they change, so the *next* review uses current values.
  FsrsService(
    this._dao, {
    final AppClock? clock,
    final FsrsSettings settings = FsrsSettings.defaults,
  })  : _clock = clock ?? SystemClock(),
        _scheduler = fsrs.Scheduler(
          desiredRetention:
              FsrsSettings.clampRetention(settings.desiredRetention),
          learningSteps: settings.learningSteps,
          relearningSteps: settings.relearningSteps,
          maximumInterval:
              FsrsSettings.clampMaximumInterval(settings.maximumInterval),
          enableFuzzing: settings.enableFuzzing,
        );

  /// Process a review rating for an entity and update FSRS scheduling data.
  ///
  /// This is the core scheduling loop:
  /// 1. Load (or create) the FSRS card for this entity
  /// 2. Convert DB row → fsrs.Card
  /// 3. Call scheduler.reviewCard() to compute new scheduling params
  /// 4. Persist the updated card back to the database
  Future<FsrsReviewResult> processReview(
    final String entityId,
    final ReviewRating rating, {
    final String entityType = 'move',
  }) async {
    final dbCard = await _dao.ensureCard(entityId, entityType: entityType);
    final preState = dbCard.fsrsState;

    final fsrsCard = _dbToFsrs(dbCard);
    final fsrsRating = _mapRating(rating);

    final result = _scheduler.reviewCard(fsrsCard, fsrsRating);
    final updated = result.card;
    final postState = updated.state.value;

    // Track reps and lapses ourselves since the fsrs package Card doesn't
    final newReps = (rating != ReviewRating.again) ? dbCard.reps + 1 : 0;
    final newLapses = (rating == ReviewRating.again && dbCard.fsrsState == 2)
        ? dbCard.lapses + 1
        : dbCard.lapses;

    await _dao.upsert(
      FsrsCardsCompanion(
        entityId: Value(entityId),
        entityType: Value(entityType),
        stability: Value(updated.stability ?? 0.0),
        difficulty: Value(updated.difficulty ?? 0.0),
        due: Value(updated.due),
        lastReview: Value(updated.lastReview ?? _clock.nowUtc()),
        reps: Value(newReps),
        lapses: Value(newLapses),
        fsrsState: Value(postState),
      ),
    );

    return FsrsReviewResult(
      dueDate: updated.due,
      preState: preState,
      postState: postState,
    );
  }

  /// Get the current retrievability for an entity.
  Future<double> getRetrievability(
    final String entityId, {
    final String entityType = 'move',
  }) async {
    final dbCard = await _dao.getByEntityId(entityId, entityType: entityType);
    if (dbCard == null || dbCard.lastReview == null) return 0.0;

    final fsrsCard = _dbToFsrs(dbCard);
    return _scheduler.getCardRetrievability(fsrsCard);
  }

  /// Get all cards that are currently due for review.
  Future<List<FsrsCardWithEntity>> getDueCards({final String? category}) {
    return _dao.getDueCardsWithEntities(
      asOf: _clock.nowUtc(),
      category: category,
    );
  }

  /// Get all reviewable items with their FSRS cards (the unified list).
  Future<List<ReviewableItemWithCard>> getAllItems({final String? category}) async {
    final entities = await _dao.getCardsWithEntities(category: category);
    return entities.map((final e) => ReviewableItemWithCard.fromEntity(e)).toList();
  }

  /// Anki-style due summary: breaks down due cards by FSRS state.
  Future<DueSummary> getDueSummary() async {
    final now = _clock.nowUtc();
    final endOfToday = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
    final endOfTomorrow = endOfToday.add(const Duration(days: 1));

    final allCards = await _dao.getAll();
    int newDue = 0, learningDue = 0, reviewDue = 0;
    int totalDueToday = 0, dueTomorrow = 0;

    for (final card in allCards) {
      final isDueNow = !card.due.isAfter(now);
      final isDueToday =
          card.due.isBefore(endOfToday) ||
          card.due.isAtSameMomentAs(endOfToday);
      final isDueTomorrow =
          !isDueToday &&
          (card.due.isBefore(endOfTomorrow) ||
              card.due.isAtSameMomentAs(endOfTomorrow));

      if (isDueNow) {
        switch (card.fsrsState) {
          case 0:
            newDue++;
          case 1 || 3:
            learningDue++;
          case 2:
            reviewDue++;
        }
      }

      if (isDueToday) totalDueToday++;
      if (isDueTomorrow) dueTomorrow++;
    }

    return DueSummary(
      newDue: newDue,
      learningDue: learningDue,
      reviewDue: reviewDue,
      totalDueToday: totalDueToday,
      dueTomorrow: dueTomorrow,
    );
  }

  /// Preview the scheduling interval for each rating without committing.
  Future<Map<ReviewRating, Duration>> previewIntervals(
    final String entityId, {
    final String entityType = 'move',
  }) async {
    final dbCard = await _dao.ensureCard(entityId, entityType: entityType);
    final fsrsCard = _dbToFsrs(dbCard);
    final now = _clock.nowUtc();

    return {
      for (final rating in ReviewRating.values)
        rating: _scheduler
            .reviewCard(fsrsCard, _mapRating(rating), reviewDateTime: now)
            .card
            .due
            .difference(now),
    };
  }

  /// Get SRS coefficients for a specific entity (for detail sheet).
  Future<SrsCoefficients> getSrsCoefficients(
    final String entityId, {
    final String entityType = 'move',
  }) async {
    final dbCard = await _dao.getByEntityId(entityId, entityType: entityType);
    if (dbCard == null) {
      return const SrsCoefficients(
        stability: 0,
        difficulty: 0,
        retrievability: 0,
        interval: Duration.zero,
        reps: 0,
        lapses: 0,
        fsrsState: 0,
      );
    }

    double retrievability = 0.0;
    if (dbCard.lastReview != null && dbCard.stability > 0) {
      final fsrsCard = _dbToFsrs(dbCard);
      retrievability = _scheduler.getCardRetrievability(fsrsCard);
    }

    final interval = dbCard.lastReview != null
        ? dbCard.due.difference(dbCard.lastReview!)
        : Duration.zero;

    return SrsCoefficients(
      stability: dbCard.stability,
      difficulty: dbCard.difficulty,
      retrievability: retrievability,
      interval: interval,
      reps: dbCard.reps,
      lapses: dbCard.lapses,
      fsrsState: dbCard.fsrsState,
    );
  }

  /// Get mastery breakdown per category.
  Future<List<CategoryMastery>> getCategoryMastery() async {
    final cardsWithEntities = await _dao.getCardsWithEntities();
    final now = _clock.nowUtc();

    // Group by category (combos without category go under 'combos')
    final byCategory = <String, List<FsrsCardWithEntity>>{};
    for (final cw in cardsWithEntities) {
      final cat = cw.category ?? 'combos';
      byCategory.putIfAbsent(cat, () => []).add(cw);
    }

    return byCategory.entries.map((final entry) {
      final cards = entry.value;
      int newCount = 0, learningCount = 0, reviewCount = 0;
      int dueCount = 0;

      for (final cw in cards) {
        switch (cw.card.fsrsState) {
          case 0:
            newCount++;
          case 1 || 3:
            learningCount++;
          case 2:
            reviewCount++;
        }
        if (!cw.card.due.isAfter(now)) {
          dueCount++;
        }
      }

      return CategoryMastery(
        category: entry.key,
        totalCards: cards.length,
        newCount: newCount,
        learningCount: learningCount,
        reviewCount: reviewCount,
        dueCount: dueCount,
      );
    }).toList();
  }

  /// Count all cards by FSRS state regardless of due date.
  Future<TotalStateCounts> getTotalStateCounts() async {
    final allCards = await _dao.getAll();
    int newCount = 0, learningCount = 0, reviewCount = 0;

    for (final card in allCards) {
      switch (card.fsrsState) {
        case 0:
          newCount++;
        case 1 || 3:
          learningCount++;
        case 2:
          reviewCount++;
      }
    }

    return TotalStateCounts(
      newCount: newCount,
      learningCount: learningCount,
      reviewCount: reviewCount,
    );
  }

  /// Compute overall retention across all reviewed cards.
  Future<double> getOverallRetention() async {
    final cards = await _dao.getAll();
    if (cards.isEmpty) return 0.0;

    final reviewed = cards.where((final c) => c.lastReview != null).toList();
    if (reviewed.isEmpty) return 0.0;

    double totalR = 0;
    for (final card in reviewed) {
      final fsrsCard = _dbToFsrs(card);
      totalR += _scheduler.getCardRetrievability(fsrsCard);
    }
    return totalR / reviewed.length;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Convert a database FsrsCard row to the fsrs package Card object.
  fsrs.Card _dbToFsrs(final FsrsCard dbCard) {
    if (dbCard.fsrsState == 0) {
      return fsrs.Card(
        cardId: dbCard.entityId.hashCode,
        state: fsrs.State.learning,
        step: 0,
        due: dbCard.due.toUtc(),
      );
    }

    return fsrs.Card(
      cardId: dbCard.entityId.hashCode,
      state: fsrs.State.fromValue(dbCard.fsrsState),
      step: (dbCard.fsrsState == 1 || dbCard.fsrsState == 3) ? 0 : null,
      stability: dbCard.stability > 0 ? dbCard.stability : null,
      difficulty: dbCard.difficulty > 0 ? dbCard.difficulty : null,
      due: dbCard.due.toUtc(),
      lastReview: dbCard.lastReview?.toUtc(),
    );
  }

  /// Map our app's ReviewRating enum to the fsrs package Rating.
  fsrs.Rating _mapRating(final ReviewRating rating) => switch (rating) {
    ReviewRating.again => fsrs.Rating.again,
    ReviewRating.hard => fsrs.Rating.hard,
    ReviewRating.good => fsrs.Rating.good,
    ReviewRating.easy => fsrs.Rating.easy,
  };
}

/// Maps an FSRS state to the app's visible learning state labels.
///
/// FSRS keeps relearning in state 3, but the UI groups it with Learning so
/// the user sees a simple NEW / LEARNING / MASTERY progression.
LearningState learningStateFromFsrsState(final int? fsrsState) => switch (fsrsState) {
  2 => LearningState.mastery,
  1 || 3 => LearningState.learning,
  _ => LearningState.newState,
};
