import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers.dart';
import '../../../core/services/fsrs_service.dart';

/// A single move-level review entry for the day detail drilldown.
class DayMoveReview {
  final String moveId;
  final String moveName;
  final String category;
  final String rating;
  final DateTime reviewedAt;
  final int? fsrsPreState;
  final int? fsrsPostState;

  const DayMoveReview({
    required this.moveId,
    required this.moveName,
    required this.category,
    required this.rating,
    required this.reviewedAt,
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

/// Fetches per-move review detail for a given day.
/// Returns chronologically sorted list of [DayMoveReview].
final dayDetailProvider =
    FutureProvider.family<List<DayMoveReview>, DateTime>((ref, date) async {
  final db = ref.watch(databaseProvider);
  final reviews = await db.reviewsDao.getForDay(date);
  final allMoves = await db.movesDao.getAll();
  final moveMap = {for (final m in allMoves) m.id: m};

  // Filter out reviews for deleted moves — never show "Unknown"
  return reviews
      .where((r) => r.moveId != null && moveMap.containsKey(r.moveId))
      .map((r) {
        final move = moveMap[r.moveId]!;
        return DayMoveReview(
          moveId: r.moveId!,
          moveName: move.name,
          category: move.category,
          rating: r.rating,
          reviewedAt: r.reviewedAt,
          fsrsPreState: r.fsrsPreState,
          fsrsPostState: r.fsrsPostState,
        );
      })
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
  });
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
  final db = ref.watch(databaseProvider);
  final fsrsService = ref.watch(fsrsServiceProvider);
  final reviewsDao = db.reviewsDao;
  final movesDao = db.movesDao;

  final now = DateTime.now();
  final yearAgo = now.subtract(const Duration(days: 365));
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  // Run all queries concurrently — removed Total/Week/Month vanity queries
  final results = await Future.wait([
    reviewsDao.ratingDistribution(),               // 0
    reviewsDao.topReviewedMoves(5),                // 1
    reviewsDao.graduationStreak(),                 // 2 — mastery streak (graduation events)
    reviewsDao.dailyCountsSince(yearAgo),          // 3
    movesDao.getAll(),                             // 4
    fsrsService.getDueSummary(),                   // 5
    fsrsService.getOverallRetention(),             // 6
    fsrsService.getCategoryMastery(),              // 7
    reviewsDao.getInRange(thirtyDaysAgo, now),     // 8 — last 30 days reviews
    fsrsService.getTotalStateCounts(),             // 9 — total state counts
  ]);

  // Build daily breakdown from last 30 days of reviews
  final allMoves = results[4] as List<Move>;
  final moveMap = {for (final m in allMoves) m.id: m};
  final last30Reviews = results[8] as List<Review>;
  final dailyBreakdown = _buildDailyBreakdown(last30Reviews, thirtyDaysAgo, now, moveMap);

  // Filter out top move entries where the move no longer exists
  final moveIds = {for (final m in allMoves) m.id};
  final topMoveEntries = (results[1] as List<MapEntry<String, int>>)
      .where((e) => moveIds.contains(e.key))
      .toList();

  // Build enriched top-moves list with category, state, last reviewed
  final fsrsCards = await db.fsrsCardsDao.getAll();
  final fsrsMap = {for (final c in fsrsCards) c.entityId: c};
  final topMoves = topMoveEntries.map((entry) {
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
  }).whereType<TopMoveInfo>().toList();

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
  );
});

String _fsrsStateLabel(int state) => switch (state) {
  0 => 'New',
  1 => 'Learning',
  2 => 'Mastered',
  3 => 'Relearning',
  _ => 'Unknown',
};

/// Build per-day stats for the last 30 days from raw review records.
List<DayStats> _buildDailyBreakdown(
  List<Review> reviews,
  DateTime from,
  DateTime to,
  Map<String, Move> moveMap,
) {
  // Group reviews by date
  final byDay = <DateTime, List<Review>>{};
  for (final r in reviews) {
    final day = DateTime(r.reviewedAt.year, r.reviewedAt.month, r.reviewedAt.day);
    byDay.putIfAbsent(day, () => []).add(r);
  }

  // Build stats for each of the last 30 days
  final result = <DayStats>[];
  for (int i = 0; i < 30; i++) {
    final date = DateTime(to.year, to.month, to.day).subtract(Duration(days: i));
    final dayReviews = byDay[date] ?? [];

    int again = 0, hard = 0, good = 0, easy = 0;
    final entries = <DayMoveEntry>[];
    for (final r in dayReviews) {
      switch (r.rating) {
        case 'AGAIN':
          again++;
        case 'HARD':
          hard++;
        case 'GOOD':
          good++;
        case 'EASY':
          easy++;
      }
      final move = r.moveId != null ? moveMap[r.moveId] : null;
      if (move != null) {
        entries.add(DayMoveEntry(
          moveName: move.name,
          rating: r.rating,
          category: move.category,
        ));
      }
    }

    result.add(DayStats(
      date: date,
      reviewCount: dayReviews.length,
      againCount: again,
      hardCount: hard,
      goodCount: good,
      easyCount: easy,
      moveEntries: entries,
    ));
  }

  return result;
}
