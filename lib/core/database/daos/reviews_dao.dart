import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/reviews.dart';
import '../tables/moves.dart';
import '../tables/combos.dart';

part 'reviews_dao.g.dart';

@DriftAccessor(tables: [Reviews, Moves, Combos])
class ReviewsDao extends DatabaseAccessor<AppDatabase> with _$ReviewsDaoMixin {
  ReviewsDao(super.db);

  Stream<List<Review>> watchAll() => (select(
    reviews,
  )..orderBy([(final t) => OrderingTerm.desc(t.reviewedAt)])).watch();

  Future<void> insertReview(final ReviewsCompanion entry) =>
      into(reviews).insert(entry);

  Future<List<Review>> getAllOrdered() => (select(
    reviews,
  )..orderBy([(final t) => OrderingTerm.desc(t.reviewedAt)])).get();

  Future<List<Review>> getByMoveId(final String moveId) =>
      (select(reviews)..where((final t) => t.moveId.equals(moveId))).get();

  Future<int> countAll() async {
    final result = await (select(reviews)).get();
    return result.length;
  }

  Future<List<Review>> getInRange(final DateTime start, final DateTime end) =>
      (select(reviews)
            ..where(
              (final t) =>
                  t.reviewedAt.isBiggerOrEqualValue(start) &
                  t.reviewedAt.isSmallerOrEqualValue(end),
            )
            ..orderBy([(final t) => OrderingTerm.asc(t.reviewedAt)]))
          .get();

  /// Get all reviews for a single calendar day, sorted chronologically.
  Future<List<Review>> getForDay(final DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return getInRange(start, end);
  }

  Future<Map<DateTime, int>> dailyCountsSince(final DateTime since) async {
    final rows =
        await (select(reviews)
              ..where((final t) => t.reviewedAt.isBiggerOrEqualValue(since))
              ..orderBy([(final t) => OrderingTerm.asc(t.reviewedAt)]))
            .get();

    final counts = <DateTime, int>{};
    for (final r in rows) {
      final day = DateTime(
        r.reviewedAt.year,
        r.reviewedAt.month,
        r.reviewedAt.day,
      );
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }

  Future<Map<String, int>> ratingDistribution() async {
    final rows = await select(reviews).get();
    final dist = <String, int>{'AGAIN': 0, 'HARD': 0, 'GOOD': 0, 'EASY': 0};
    for (final r in rows) {
      dist[r.rating] = (dist[r.rating] ?? 0) + 1;
    }
    return dist;
  }

  Future<List<MapEntry<String, int>>> topReviewedMoves(final int limit) async {
    final rows = await select(reviews).get();
    final counts = <String, int>{};
    for (final r in rows) {
      if (r.moveId != null) {
        counts[r.moveId!] = (counts[r.moveId!] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((final a, final b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Legacy streak: consecutive days with any review activity.
  Future<int> currentStreak() async {
    final rows = await (select(
      reviews,
    )..orderBy([(final t) => OrderingTerm.desc(t.reviewedAt)])).get();

    if (rows.isEmpty) return 0;

    final days = <DateTime>{};
    for (final r in rows) {
      days.add(
        DateTime(r.reviewedAt.year, r.reviewedAt.month, r.reviewedAt.day),
      );
    }

    final sortedDays = days.toList()..sort((final a, final b) => b.compareTo(a));
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

  /// Graduation streak: consecutive days where at least one card graduated
  /// (transitioned from non-Review to Review state in FSRS).
  ///
  /// This is more meaningful than "days with any review" because it measures
  /// actual learning progress — the learner proved they can recall a move
  /// reliably enough for FSRS to promote it to Review state.
  Future<int> graduationStreak() async {
    final rows =
        await (select(reviews)
              ..where(
                (final t) =>
                    t.fsrsPostState.equals(2) &
                    t.fsrsPreState.isNotNull() &
                    t.fsrsPreState.isNotValue(2),
              )
              ..orderBy([(final t) => OrderingTerm.desc(t.reviewedAt)]))
            .get();

    if (rows.isEmpty) return 0;

    // Collect unique days with graduation events
    final days = <DateTime>{};
    for (final r in rows) {
      days.add(
        DateTime(r.reviewedAt.year, r.reviewedAt.month, r.reviewedAt.day),
      );
    }

    final sortedDays = days.toList()..sort((final a, final b) => b.compareTo(a));
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
