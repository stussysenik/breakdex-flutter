import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/reviews.dart';
import '../tables/moves.dart';

part 'reviews_dao.g.dart';

@DriftAccessor(tables: [Reviews, Moves])
class ReviewsDao extends DatabaseAccessor<AppDatabase> with _$ReviewsDaoMixin {
  ReviewsDao(super.db);

  Stream<List<Review>> watchAll() =>
      (select(reviews)..orderBy([(t) => OrderingTerm.desc(t.reviewedAt)]))
          .watch();

  Future<void> insertReview(ReviewsCompanion entry) =>
      into(reviews).insert(entry);

  Future<List<Review>> getByMoveId(String moveId) =>
      (select(reviews)..where((t) => t.moveId.equals(moveId))).get();

  Future<int> countAll() async {
    final result = await (select(reviews)).get();
    return result.length;
  }

  Future<List<Review>> getInRange(DateTime start, DateTime end) =>
      (select(reviews)
            ..where((t) =>
                t.reviewedAt.isBiggerOrEqualValue(start) &
                t.reviewedAt.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.asc(t.reviewedAt)]))
          .get();

  Future<Map<DateTime, int>> dailyCountsSince(DateTime since) async {
    final rows = await (select(reviews)
          ..where((t) => t.reviewedAt.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm.asc(t.reviewedAt)]))
        .get();

    final counts = <DateTime, int>{};
    for (final r in rows) {
      final day = DateTime(
          r.reviewedAt.year, r.reviewedAt.month, r.reviewedAt.day);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }

  Future<Map<String, int>> ratingDistribution() async {
    final rows = await select(reviews).get();
    final dist = <String, int>{'AGAIN': 0, 'HARD': 0, 'GOOD': 0};
    for (final r in rows) {
      dist[r.rating] = (dist[r.rating] ?? 0) + 1;
    }
    return dist;
  }

  Future<List<MapEntry<String, int>>> topReviewedMoves(int limit) async {
    final rows = await select(reviews).get();
    final counts = <String, int>{};
    for (final r in rows) {
      if (r.moveId != null) {
        counts[r.moveId!] = (counts[r.moveId!] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  Future<int> currentStreak() async {
    final rows = await (select(reviews)
          ..orderBy([(t) => OrderingTerm.desc(t.reviewedAt)]))
        .get();

    if (rows.isEmpty) return 0;

    final days = <DateTime>{};
    for (final r in rows) {
      days.add(DateTime(r.reviewedAt.year, r.reviewedAt.month, r.reviewedAt.day));
    }

    final sortedDays = days.toList()..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Streak must include today or yesterday
    if (sortedDays.first.difference(todayDate).inDays.abs() > 1) return 0;

    int streak = 1;
    for (int i = 1; i < sortedDays.length; i++) {
      final diff = sortedDays[i - 1].difference(sortedDays[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
