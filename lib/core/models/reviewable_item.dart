import 'dart:math';

import '../database/database.dart';
import '../database/daos/fsrs_cards_dao.dart';
import '../services/video_path_resolver.dart';

/// A polymorphic wrapper for anything that can be reviewed — moves and combos.
///
/// Sealed classes in Dart work like algebraic data types (ADTs): the compiler
/// knows every possible subtype, enabling exhaustive pattern matching in switch
/// expressions. This eliminates runtime type-check bugs when branching on
/// entity type.
sealed class ReviewableItem {
  String get entityId;
  String get entityType;
  String get displayName;
  String? get category;
  String? get videoPath;
}

/// A move that can be reviewed.
class ReviewableMove extends ReviewableItem {
  final Move move;

  ReviewableMove(this.move);

  @override
  String get entityId => move.id;
  @override
  String get entityType => 'move';
  @override
  String get displayName => move.name;
  @override
  String? get category => move.category;
  @override
  String? get videoPath => move.resolvedVideoPath;
}

/// A combo that can be reviewed.
class ReviewableCombo extends ReviewableItem {
  final Combo combo;

  ReviewableCombo(this.combo);

  @override
  String get entityId => combo.id;
  @override
  String get entityType => 'combo';
  @override
  String get displayName => combo.name;
  @override
  String? get category => null; // Combos don't have categories
  @override
  String? get videoPath => combo.resolvedActiveVideoPath;
}

/// Resolves stored (possibly relative) video paths to absolute paths at
/// access time. This lets the DB store portable relative paths while all
/// UI consumers receive ready-to-use absolute paths.
extension MoveVideoPath on Move {
  String? get resolvedVideoPath =>
      videoPath != null ? VideoPathResolver.toAbsolute(videoPath!) : null;
}

extension ComboVideoPath on Combo {
  String? get resolvedActiveVideoPath =>
      activeVideoPath != null
          ? VideoPathResolver.toAbsolute(activeVideoPath!)
          : null;
}

/// A reviewable item paired with its FSRS card (scheduling data).
///
/// This is the primary data class for the unified review list — every item
/// the user can review, with its current FSRS scheduling state attached.
class ReviewableItemWithCard {
  final ReviewableItem item;
  final FsrsCard? card;

  const ReviewableItemWithCard({required this.item, this.card});

  /// Compute memory retrievability using the FSRS forgetting curve:
  ///
  ///   R(t) = (1 + t / (9 * S))^(-1)
  ///
  /// where t = elapsed days since last review, S = stability in days.
  /// Returns 1.0 for new/unreviewed cards, 0.0 if stability is zero.
  double get retrievability {
    final c = card;
    if (c == null || c.lastReview == null || c.stability <= 0) return 0.0;
    final elapsedDays =
        DateTime.now().toUtc().difference(c.lastReview!).inMinutes / 1440.0;
    return pow(1 + elapsedDays / (9 * c.stability), -1).toDouble();
  }

  /// FSRS state label for display.
  String get stateLabel => switch (card?.fsrsState) {
        0 => 'New',
        1 => 'Learning',
        2 => 'Review',
        3 => 'Relearning',
        _ => 'New',
      };

  /// Due date from the card, or now if no card exists.
  DateTime get dueDate => card?.due ?? DateTime.now().toUtc();

  /// Convenience: construct from a FsrsCardWithEntity JOIN result.
  factory ReviewableItemWithCard.fromEntity(FsrsCardWithEntity entity) {
    final ReviewableItem item;
    if (entity.move != null) {
      item = ReviewableMove(entity.move!);
    } else if (entity.combo != null) {
      item = ReviewableCombo(entity.combo!);
    } else {
      // Orphan card — create a placeholder move
      item = ReviewableMove(Move(
        id: entity.card.entityId,
        name: 'Unknown',
        learningState: 'NEW',
        category: 'default',
        videoPath: null,
        originalVideoName: null,
        createdAt: DateTime.now(),
      ));
    }
    return ReviewableItemWithCard(item: item, card: entity.card);
  }
}

/// Full FSRS math coefficients exposed for UI display.
///
/// Shows the learner the "why" behind scheduling decisions — transparency
/// builds trust in the algorithm and helps power users tune their practice.
class SrsCoefficients {
  /// Memory stability in days — how long until retrievability drops to 85%.
  final double stability;

  /// Item difficulty on 0–10 scale.
  final double difficulty;

  /// Current probability of recall (0.0–1.0).
  final double retrievability;

  /// Current interval to next review (from last review to due date).
  final Duration interval;

  /// Consecutive successful reviews.
  final int reps;

  /// Number of times the card lapsed.
  final int lapses;

  /// FSRS state (0=New, 1=Learning, 2=Review, 3=Relearning).
  final int fsrsState;

  const SrsCoefficients({
    required this.stability,
    required this.difficulty,
    required this.retrievability,
    required this.interval,
    required this.reps,
    required this.lapses,
    required this.fsrsState,
  });

  String get stateLabel => switch (fsrsState) {
        0 => 'New',
        1 => 'Learning',
        2 => 'Review',
        3 => 'Relearning',
        _ => 'New',
      };

  /// Format stability as human-readable duration.
  String get stabilityFormatted {
    if (stability < 1) return '${(stability * 24).round()}h';
    if (stability < 30) return '${stability.round()}d';
    return '${(stability / 30).toStringAsFixed(1)}mo';
  }
}

/// Aggregate SRS overview stats for the schedule screen header.
class SrsOverview {
  final int totalCards;
  final int dueNow;
  final int dueToday;
  final int dueTomorrow;
  final double avgRetention;
  final double avgStability;

  const SrsOverview({
    required this.totalCards,
    required this.dueNow,
    required this.dueToday,
    required this.dueTomorrow,
    required this.avgRetention,
    required this.avgStability,
  });
}

/// Review mode: flashcard review or deck-based review.
enum ReviewMode {
  review,
  deck;

  static ReviewMode fromString(String? value) => switch (value) {
        'deck' => ReviewMode.deck,
        // Backward compat: old 'session' and 'schedule' both map to review
        'session' || 'schedule' || _ => ReviewMode.review,
      };
}
