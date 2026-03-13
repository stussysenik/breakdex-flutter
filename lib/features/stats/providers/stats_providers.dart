import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers.dart';
import '../../../core/services/fsrs_service.dart';

/// A single move-level review entry for the day detail drilldown.
class DayMoveReview {
  final String moveId;
  final String entityType;
  final String moveName;
  final String category;
  final String rating;
  final DateTime reviewedAt;
  final bool isDeleted;
  final int? fsrsPreState;
  final int? fsrsPostState;

  const DayMoveReview({
    required this.moveId,
    required this.entityType,
    required this.moveName,
    required this.category,
    required this.rating,
    required this.reviewedAt,
    required this.isDeleted,
    this.fsrsPreState,
    this.fsrsPostState,
  });

  /// Whether this review caused a graduation (non-Review → Review).
  bool get isGraduation =>
      fsrsPreState != null &&
      fsrsPostState != null &&
      fsrsPreState != 2 &&
      fsrsPostState == 2;
}

/// Currently selected date in the calendar / daily breakdown.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Fetches per-move/combo review detail for a given day.
/// Returns chronologically sorted list of [DayMoveReview].
final dayDetailProvider = FutureProvider.family<List<DayMoveReview>, DateTime>((
  ref,
  date,
) async {
  final db = ref.watch(databaseProvider);
  final results = await Future.wait([
    db.reviewsDao.getForDay(date),
    db.movesDao.getAll(),
    db.combosDao.getAll(),
  ]);
  final reviews = results[0] as List<Review>;
  final allMoves = results[1] as List<Move>;
  final allCombos = results[2] as List<Combo>;
  final moveMap = {for (final m in allMoves) m.id: m};
  final comboMap = {for (final c in allCombos) c.id: c};

  return reviews
      .map((r) {
        final entity = _resolveReviewEntity(r, moveMap, comboMap);
        if (entity == null) return null;
        return DayMoveReview(
          moveId: entity.entityId,
          entityType: entity.entityType,
          moveName: entity.displayName,
          category: entity.category,
          rating: r.rating,
          reviewedAt: r.reviewedAt,
          isDeleted: entity.isDeleted,
          fsrsPreState: r.fsrsPreState,
          fsrsPostState: r.fsrsPostState,
        );
      })
      .whereType<DayMoveReview>()
      .toList();
});

/// A single move + rating entry within a day, used by the card-based breakdown.
class DayMoveEntry {
  final String moveName;
  final String rating;
  final String category;

  const DayMoveEntry({
    required this.moveName,
    required this.rating,
    required this.category,
  });
}

/// Per-day stats for the daily breakdown view.
class DayStats {
  final DateTime date;
  final int reviewCount;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;

  /// Per-move review entries for the card-based breakdown display.
  final List<DayMoveEntry> moveEntries;

  const DayStats({
    required this.date,
    required this.reviewCount,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    this.moveEntries = const [],
  });

  /// Accuracy: fraction of reviews rated Good or Easy.
  double get accuracy =>
      reviewCount > 0 ? (goodCount + easyCount) / reviewCount : 0.0;
}

/// Enriched top-move entry with category, FSRS state, and last reviewed date.
class TopMoveInfo {
  final String moveId;
  final String moveName;
  final int reviewCount;
  final String category;
  final String fsrsStateLabel;
  final DateTime? lastReviewed;

  const TopMoveInfo({
    required this.moveId,
    required this.moveName,
    required this.reviewCount,
    required this.category,
    required this.fsrsStateLabel,
    this.lastReviewed,
  });
}

class CardReviewStats {
  const CardReviewStats({
    required this.entityId,
    required this.entityType,
    required this.displayName,
    required this.category,
    required this.shownCount,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    required this.isDeleted,
    this.firstReviewedAt,
    this.lastReviewedAt,
  });

  final String entityId;
  final String entityType;
  final String displayName;
  final String category;
  final int shownCount;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final bool isDeleted;
  final DateTime? firstReviewedAt;
  final DateTime? lastReviewedAt;

  int get successfulCount => goodCount + easyCount;
  double get successRatio =>
      shownCount > 0 ? successfulCount / shownCount : 0.0;
}

class ReviewTimelineEntry {
  const ReviewTimelineEntry({
    required this.entityId,
    required this.entityType,
    required this.displayName,
    required this.category,
    required this.rating,
    required this.reviewedAt,
    required this.isDeleted,
    this.fsrsPreState,
    this.fsrsPostState,
  });

  final String entityId;
  final String entityType;
  final String displayName;
  final String category;
  final String rating;
  final DateTime reviewedAt;
  final bool isDeleted;
  final int? fsrsPreState;
  final int? fsrsPostState;

  bool get graduated =>
      fsrsPreState != null &&
      fsrsPostState != null &&
      fsrsPreState != 2 &&
      fsrsPostState == 2;
}

class StatsBundle {
  final Map<String, int> ratingDistribution;
  final List<MapEntry<String, int>> topMoveEntries;
  final List<TopMoveInfo> topMoves;
  final int currentStreak;
  final Map<DateTime, int> dailyCounts;
  final List<Move> allMoves;

  // FSRS-powered metrics
  final DueSummary dueSummary;
  final TotalStateCounts totalStateCounts;
  final double overallRetention;
  final List<CategoryMastery> categoryMastery;
  final List<DayStats> dailyBreakdown;
  final List<CardReviewStats> cardStats;
  final List<ReviewTimelineEntry> reviewTimeline;

  const StatsBundle({
    required this.ratingDistribution,
    required this.topMoveEntries,
    required this.topMoves,
    required this.currentStreak,
    required this.dailyCounts,
    required this.allMoves,
    required this.dueSummary,
    required this.totalStateCounts,
    required this.overallRetention,
    required this.categoryMastery,
    required this.dailyBreakdown,
    required this.cardStats,
    required this.reviewTimeline,
  });
}

class _ResolvedReviewEntity {
  const _ResolvedReviewEntity({
    required this.entityId,
    required this.entityType,
    required this.displayName,
    required this.category,
    required this.isDeleted,
  });

  final String entityId;
  final String entityType;
  final String displayName;
  final String category;
  final bool isDeleted;
}

/// Watches the review stream so stats auto-rebuild after any review change.
/// Drift watch streams provide Flutter-first reactivity without manual refresh.
final statsRefreshProvider = StreamProvider<void>((ref) {
  final db = ref.watch(databaseProvider);
  return db.reviewsDao.watchAll().map((_) {});
});

final statsBundleProvider = FutureProvider<StatsBundle>((ref) async {
  // Auto-rebuild when reviews change (Drift watch stream reactivity)
  ref.watch(statsRefreshProvider);
  // Also rebuild when FSRS card state changes (due counts, retention, mastery)
  ref.watch(fsrsCardsRefreshProvider);
  final db = ref.watch(databaseProvider);
  final fsrsService = ref.watch(fsrsServiceProvider);
  final reviewsDao = db.reviewsDao;
  final movesDao = db.movesDao;

  final now = DateTime.now();
  final yearAgo = now.subtract(const Duration(days: 365));
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  // Run all queries concurrently — removed Total/Week/Month vanity queries
  final results = await Future.wait([
    reviewsDao.ratingDistribution(), // 0
    reviewsDao.topReviewedMoves(5), // 1
    reviewsDao.graduationStreak(), // 2 — mastery streak (graduation events)
    reviewsDao.dailyCountsSince(yearAgo), // 3
    movesDao.getAll(), // 4
    fsrsService.getDueSummary(), // 5
    fsrsService.getOverallRetention(), // 6
    fsrsService.getCategoryMastery(), // 7
    reviewsDao.getInRange(thirtyDaysAgo, now), // 8 — last 30 days reviews
    fsrsService.getTotalStateCounts(), // 9 — total state counts
    db.combosDao.getAll(), // 10 — all combos
    reviewsDao.getAllOrdered(), // 11 — all reviews for card/time modes
  ]);

  // Build daily breakdown from last 30 days of reviews
  final allMoves = results[4] as List<Move>;
  final moveMap = {for (final m in allMoves) m.id: m};
  final allCombos = results[10] as List<Combo>;
  final comboMap = {for (final c in allCombos) c.id: c};
  final last30Reviews = results[8] as List<Review>;
  final allReviews = results[11] as List<Review>;
  final dailyBreakdown = _buildDailyBreakdown(
    last30Reviews,
    thirtyDaysAgo,
    now,
    moveMap,
    comboMap,
  );
  final cardStats = _buildCardStats(allReviews, moveMap, comboMap);
  final reviewTimeline = _buildReviewTimeline(allReviews, moveMap, comboMap);

  // Filter out top move entries where the move no longer exists
  final moveIds = {for (final m in allMoves) m.id};
  final topMoveEntries = (results[1] as List<MapEntry<String, int>>)
      .where((e) => moveIds.contains(e.key))
      .toList();

  // Build enriched top-moves list with category, state, last reviewed
  final fsrsCards = await db.fsrsCardsDao.getAll();
  final fsrsMap = {for (final c in fsrsCards) c.entityId: c};
  final topMoves = topMoveEntries
      .map((entry) {
        final move = moveMap[entry.key];
        if (move == null) return null;
        final card = fsrsMap[move.id];
        return TopMoveInfo(
          moveId: move.id,
          moveName: move.name,
          reviewCount: entry.value,
          category: move.category,
          fsrsStateLabel: _fsrsStateLabel(card?.fsrsState ?? 0),
          lastReviewed: card?.lastReview,
        );
      })
      .whereType<TopMoveInfo>()
      .toList();

  return StatsBundle(
    ratingDistribution: results[0] as Map<String, int>,
    topMoveEntries: topMoveEntries,
    topMoves: topMoves,
    currentStreak: results[2] as int,
    dailyCounts: results[3] as Map<DateTime, int>,
    allMoves: allMoves,
    dueSummary: results[5] as DueSummary,
    totalStateCounts: results[9] as TotalStateCounts,
    overallRetention: results[6] as double,
    categoryMastery: results[7] as List<CategoryMastery>,
    dailyBreakdown: dailyBreakdown,
    cardStats: cardStats,
    reviewTimeline: reviewTimeline,
  );
});

String _fsrsStateLabel(int state) => switch (state) {
  0 => 'New',
  1 => 'Learning',
  2 => 'Mastered',
  3 => 'Relearning',
  _ => 'Unknown',
};

_ResolvedReviewEntity? _resolveReviewEntity(
  Review review,
  Map<String, Move> moveMap,
  Map<String, Combo> comboMap,
) {
  final move = review.moveId != null ? moveMap[review.moveId] : null;
  if (move != null) {
    return _ResolvedReviewEntity(
      entityId: move.id,
      entityType: 'move',
      displayName: move.name,
      category: move.category,
      isDeleted: false,
    );
  }

  final combo = review.comboId != null ? comboMap[review.comboId] : null;
  if (combo != null) {
    return _ResolvedReviewEntity(
      entityId: combo.id,
      entityType: 'combo',
      displayName: combo.name,
      category: 'combo',
      isDeleted: false,
    );
  }

  final entityId = review.entityIdSnapshot ?? review.moveId ?? review.comboId;
  final entityType =
      review.entityType ??
      (review.comboId != null ? 'combo' : review.moveId != null ? 'move' : null);
  final entityDisplayName = review.entityDisplayName;
  if (entityId == null && entityDisplayName == null && entityType == null) {
    return null;
  }

  return _ResolvedReviewEntity(
    entityId: entityId ?? review.id,
    entityType: entityType ?? 'move',
    displayName: entityDisplayName ?? 'Deleted card',
    category: review.entityCategory ?? (entityType == 'combo' ? 'combo' : 'deleted'),
    isDeleted: true,
  );
}

/// Build per-day stats for the last 30 days from raw review records.
/// Includes both move and combo reviews in the daily breakdown.
List<DayStats> _buildDailyBreakdown(
  List<Review> reviews,
  DateTime from,
  DateTime to,
  Map<String, Move> moveMap,
  Map<String, Combo> comboMap,
) {
  // Group reviews by date
  final byDay = <DateTime, List<Review>>{};
  for (final r in reviews) {
    final day = DateTime(
      r.reviewedAt.year,
      r.reviewedAt.month,
      r.reviewedAt.day,
    );
    byDay.putIfAbsent(day, () => []).add(r);
  }

  // Build stats for each of the last 30 days
  final result = <DayStats>[];
  for (int i = 0; i < 30; i++) {
    final date = DateTime(
      to.year,
      to.month,
      to.day,
    ).subtract(Duration(days: i));
    final dayReviews = byDay[date] ?? [];

    int again = 0, hard = 0, good = 0, easy = 0;
    final entries = <DayMoveEntry>[];
    for (final r in dayReviews) {
      if (r.rating == 'AGAIN') {
        again++;
      } else if (r.rating == 'HARD') {
        hard++;
      } else if (r.rating == 'GOOD') {
        good++;
      } else if (r.rating == 'EASY') {
        easy++;
      }
      final entity = _resolveReviewEntity(r, moveMap, comboMap);
      if (entity != null) {
        entries.add(
          DayMoveEntry(
            moveName: entity.displayName,
            rating: r.rating,
            category: entity.category,
          ),
        );
      }
    }

    result.add(
      DayStats(
        date: date,
        reviewCount: dayReviews.length,
        againCount: again,
        hardCount: hard,
        goodCount: good,
        easyCount: easy,
        moveEntries: entries,
      ),
    );
  }

  return result;
}

List<CardReviewStats> _buildCardStats(
  List<Review> reviews,
  Map<String, Move> moveMap,
  Map<String, Combo> comboMap,
) {
  final aggregates = <String, _MutableCardStats>{};

  for (final review in reviews) {
    final entity = _resolveReviewEntity(review, moveMap, comboMap);
    if (entity == null) continue;

    final key = '${entity.entityType}:${entity.entityId}';
    final aggregate = aggregates.putIfAbsent(
      key,
      () => _MutableCardStats(
        entityId: entity.entityId,
        entityType: entity.entityType,
        displayName: entity.displayName,
        category: entity.category,
        isDeleted: entity.isDeleted,
      ),
    );
    aggregate.shownCount++;
    if (aggregate.firstReviewedAt == null ||
        review.reviewedAt.isBefore(aggregate.firstReviewedAt!)) {
      aggregate.firstReviewedAt = review.reviewedAt;
    }
    if (aggregate.lastReviewedAt == null ||
        review.reviewedAt.isAfter(aggregate.lastReviewedAt!)) {
      aggregate.lastReviewedAt = review.reviewedAt;
    }
    if (review.rating == 'AGAIN') {
      aggregate.againCount++;
    } else if (review.rating == 'HARD') {
      aggregate.hardCount++;
    } else if (review.rating == 'GOOD') {
      aggregate.goodCount++;
    } else if (review.rating == 'EASY') {
      aggregate.easyCount++;
    }
  }

  final items = aggregates.values
      .map(
        (aggregate) => CardReviewStats(
          entityId: aggregate.entityId,
          entityType: aggregate.entityType,
          displayName: aggregate.displayName,
          category: aggregate.category,
          shownCount: aggregate.shownCount,
          againCount: aggregate.againCount,
          hardCount: aggregate.hardCount,
          goodCount: aggregate.goodCount,
          easyCount: aggregate.easyCount,
          isDeleted: aggregate.isDeleted,
          firstReviewedAt: aggregate.firstReviewedAt,
          lastReviewedAt: aggregate.lastReviewedAt,
        ),
      )
      .toList();

  items.sort((a, b) {
    final shownCompare = b.shownCount.compareTo(a.shownCount);
    if (shownCompare != 0) return shownCompare;
    final aTime = a.lastReviewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.lastReviewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });

  return items;
}

List<ReviewTimelineEntry> _buildReviewTimeline(
  List<Review> reviews,
  Map<String, Move> moveMap,
  Map<String, Combo> comboMap,
) {
  final items = <ReviewTimelineEntry>[];

  for (final review in reviews) {
    final entity = _resolveReviewEntity(review, moveMap, comboMap);
    if (entity == null) continue;
    items.add(
      ReviewTimelineEntry(
        entityId: entity.entityId,
        entityType: entity.entityType,
        displayName: entity.displayName,
        category: entity.category,
        rating: review.rating,
        reviewedAt: review.reviewedAt,
        isDeleted: entity.isDeleted,
        fsrsPreState: review.fsrsPreState,
        fsrsPostState: review.fsrsPostState,
      ),
    );
  }

  items.sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
  return items;
}

// ---------------------------------------------------------------------------
// Granular providers — lightweight alternatives to statsBundleProvider.
// Each fetches only the data it needs, so screens that display a single
// stat (e.g. calendar heatmap, streak badge) don't trigger 12 concurrent
// DB queries on every rebuild.
// ---------------------------------------------------------------------------

/// Calendar heatmap data — one year of daily review counts.
final dailyCountsProvider =
    FutureProvider.autoDispose<Map<DateTime, int>>((ref) async {
  ref.watch(statsRefreshProvider);
  final db = ref.watch(databaseProvider);
  return db.reviewsDao.dailyCountsSince(
    DateTime.now().subtract(const Duration(days: 365)),
  );
});

/// Leaderboard — top 5 most-reviewed moves with category + FSRS enrichment.
final topMovesProvider =
    FutureProvider.autoDispose<List<TopMoveInfo>>((ref) async {
  ref.watch(statsRefreshProvider);
  final db = ref.watch(databaseProvider);
  final topEntries = await db.reviewsDao.topReviewedMoves(5);
  final allMoves = await db.movesDao.getAll();
  final moveMap = {for (final m in allMoves) m.id: m};
  final moveIds = moveMap.keys.toSet();

  final filtered = topEntries.where((e) => moveIds.contains(e.key)).toList();
  final fsrsCards = await db.fsrsCardsDao.getAll();
  final fsrsMap = {for (final c in fsrsCards) c.entityId: c};

  return filtered
      .map((entry) {
        final move = moveMap[entry.key];
        if (move == null) return null;
        final card = fsrsMap[move.id];
        return TopMoveInfo(
          moveId: move.id,
          moveName: move.name,
          reviewCount: entry.value,
          category: move.category,
          fsrsStateLabel: _fsrsStateLabel(card?.fsrsState ?? 0),
          lastReviewed: card?.lastReview,
        );
      })
      .whereType<TopMoveInfo>()
      .toList();
});

/// Due summary — FSRS card states and due counts.
final dueSummaryProvider =
    FutureProvider.autoDispose<({DueSummary due, TotalStateCounts counts})>(
        (ref) async {
  ref.watch(fsrsCardsRefreshProvider);
  final fsrs = ref.watch(fsrsServiceProvider);
  return (
    due: await fsrs.getDueSummary(),
    counts: await fsrs.getTotalStateCounts(),
  );
});

/// Streak — single int, lightweight read for badge display.
final streakProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(statsRefreshProvider);
  return ref.watch(databaseProvider).reviewsDao.graduationStreak();
});

class _MutableCardStats {
  _MutableCardStats({
    required this.entityId,
    required this.entityType,
    required this.displayName,
    required this.category,
    required this.isDeleted,
  });

  final String entityId;
  final String entityType;
  final String displayName;
  final String category;
  final bool isDeleted;
  int shownCount = 0;
  int againCount = 0;
  int hardCount = 0;
  int goodCount = 0;
  int easyCount = 0;
  DateTime? firstReviewedAt;
  DateTime? lastReviewedAt;
}
