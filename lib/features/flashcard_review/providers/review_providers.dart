import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';

/// Which learning state to filter review cards by (null = all).
final reviewStateFilterProvider = StateProvider<LearningState?>((ref) => null);

/// Which move category to filter by (null = all).
final reviewCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Session size (null = all matching moves).
final reviewSessionSizeProvider = StateProvider<int?>((ref) => null);

/// Available session size presets.
const reviewSessionSizeOptions = [5, 10, 15, null]; // null = all

/// Filtered + shuffled + capped moves for the current review session.
/// Re-fetches when filter or session size changes.
final filteredReviewMovesProvider = FutureProvider<List<Move>>((ref) async {
  final stateFilter = ref.watch(reviewStateFilterProvider);
  final categoryFilter = ref.watch(reviewCategoryFilterProvider);
  final sessionSize = ref.watch(reviewSessionSizeProvider);
  var moves = await ref.watch(moveRepositoryProvider).getAll();

  if (stateFilter != null) {
    moves = moves.where((m) => m.learningState == stateFilter.dbValue).toList();
  }
  if (categoryFilter != null) {
    moves = moves.where((m) => m.category == categoryFilter).toList();
  }

  moves.shuffle();

  // Cap to session size
  if (sessionSize != null && moves.length > sessionSize) {
    moves = moves.sublist(0, sessionSize);
  }

  return moves;
});

/// Live counts per learning state (always across ALL moves, ignoring filters).
final moveStateCountsProvider = StreamProvider<Map<LearningState, int>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll().map((moves) {
    return {
      for (final s in LearningState.values)
        s: moves.where((m) => m.learningState == s.dbValue).length,
    };
  });
});

/// Live counts per category (always across ALL moves, ignoring filters).
final moveCategoryCountsProvider =
    StreamProvider<Map<String, int>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll().map((moves) {
    final counts = <String, int>{};
    for (final m in moves) {
      counts[m.category] = (counts[m.category] ?? 0) + 1;
    }
    return counts;
  });
});

/// Total move count (all moves, no filter).
final totalMoveCountProvider = StreamProvider<int>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll().map((m) => m.length);
});

/// Whether the review dashboard filters are expanded.
final dashboardExpandedProvider = StateProvider<bool>((ref) {
  // Self-healing: auto-expand when any filter changes
  ref.listen(reviewStateFilterProvider, (prev, next) {
    ref.controller.state = true;
  });
  ref.listen(reviewCategoryFilterProvider, (prev, next) {
    ref.controller.state = true;
  });
  ref.listen(reviewSessionSizeProvider, (prev, next) {
    ref.controller.state = true;
  });
  return true;
});

/// Temporal count data for time-series badges.
class TemporalCounts {
  final int today;
  final int thisWeek;
  final int total;

  const TemporalCounts({
    required this.today,
    required this.thisWeek,
    required this.total,
  });
}

/// Temporal counts per learning state (today/week/total reviewed per state).
final reviewStateTemporalCountsProvider =
    StreamProvider<Map<LearningState, TemporalCounts>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll().map((moves) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    final result = <LearningState, TemporalCounts>{};
    for (final state in LearningState.values) {
      final stateMoves =
          moves.where((m) => m.learningState == state.dbValue).toList();
      final total = stateMoves.length;
      final today =
          stateMoves.where((m) => m.createdAt.isAfter(todayStart)).length;
      final week =
          stateMoves.where((m) => m.createdAt.isAfter(weekStart)).length;
      result[state] = TemporalCounts(
        today: today,
        thisWeek: week,
        total: total,
      );
    }
    return result;
  });
});

/// Temporal counts per category (today/week/total).
final reviewCategoryTemporalCountsProvider =
    StreamProvider<Map<String, TemporalCounts>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll().map((moves) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    final result = <String, TemporalCounts>{};
    final categories = <String>{};
    for (final m in moves) {
      categories.add(m.category);
    }
    for (final cat in categories) {
      final catMoves = moves.where((m) => m.category == cat).toList();
      final total = catMoves.length;
      final today =
          catMoves.where((m) => m.createdAt.isAfter(todayStart)).length;
      final week =
          catMoves.where((m) => m.createdAt.isAfter(weekStart)).length;
      result[cat] = TemporalCounts(
        today: today,
        thisWeek: week,
        total: total,
      );
    }
    return result;
  });
});
