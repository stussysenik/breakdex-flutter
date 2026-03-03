import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers.dart';

class StatsBundle {
  final int totalReviews;
  final int reviewsThisWeek;
  final int reviewsThisMonth;
  final Map<String, int> ratingDistribution;
  final List<MapEntry<String, int>> topMoveEntries;
  final int currentStreak;
  final Map<DateTime, int> dailyCounts;
  final List<Move> allMoves;

  const StatsBundle({
    required this.totalReviews,
    required this.reviewsThisWeek,
    required this.reviewsThisMonth,
    required this.ratingDistribution,
    required this.topMoveEntries,
    required this.currentStreak,
    required this.dailyCounts,
    required this.allMoves,
  });
}

final statsBundleProvider = FutureProvider<StatsBundle>((ref) async {
  final db = ref.watch(databaseProvider);
  final reviewsDao = db.reviewsDao;
  final movesDao = db.movesDao;

  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final monthStart = DateTime(now.year, now.month, 1);
  final yearAgo = now.subtract(const Duration(days: 365));

  final results = await Future.wait([
    reviewsDao.countAll(),                         // 0
    reviewsDao.getInRange(weekStartDate, now),     // 1
    reviewsDao.getInRange(monthStart, now),        // 2
    reviewsDao.ratingDistribution(),               // 3
    reviewsDao.topReviewedMoves(5),                // 4
    reviewsDao.currentStreak(),                    // 5
    reviewsDao.dailyCountsSince(yearAgo),          // 6
    movesDao.getAll(),                             // 7
  ]);

  return StatsBundle(
    totalReviews: results[0] as int,
    reviewsThisWeek: (results[1] as List).length,
    reviewsThisMonth: (results[2] as List).length,
    ratingDistribution: results[3] as Map<String, int>,
    topMoveEntries: results[4] as List<MapEntry<String, int>>,
    currentStreak: results[5] as int,
    dailyCounts: results[6] as Map<DateTime, int>,
    allMoves: results[7] as List<Move>,
  );
});
