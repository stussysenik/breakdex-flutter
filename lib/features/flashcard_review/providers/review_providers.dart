import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/models/reviewable_item.dart';
import '../../../core/providers.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/fsrs_service.dart';
import 'deck_providers.dart';

enum ReviewSessionSource {
  stateBased,
  deck;

  static ReviewSessionSource fromString(String? value) => switch (value) {
    'deck' => ReviewSessionSource.deck,
    _ => ReviewSessionSource.stateBased,
  };
}

final reviewSessionSourceProvider =
    NotifierProvider<ReviewSessionSourceNotifier, ReviewSessionSource>(
      ReviewSessionSourceNotifier.new,
    );

class ReviewSessionSourceNotifier extends Notifier<ReviewSessionSource> {
  static const _key = 'review_session_source';

  @override
  ReviewSessionSource build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ReviewSessionSource.fromString(prefs.getString(_key));
  }

  Future<void> set(ReviewSessionSource source) async {
    state = source;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, source.name);
  }
}

/// Which learning state to filter review cards by (null = all).
final reviewStateFilterProvider = StateProvider<LearningState?>((ref) => null);

/// Which move category to filter by (null = all).
final reviewCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Session size (null = all matching moves).
final reviewSessionSizeProvider = StateProvider<int?>((ref) => null);

/// Available session size presets.
const reviewSessionSizeOptions = [5, 10, 15, null]; // null = all

/// Cache the initial session so ratings don't cause the deck to reshuffle
/// while the user is actively swiping through it.
final _sessionSeedProvider = StateProvider<int>(
  (ref) => DateTime.now().millisecondsSinceEpoch,
);

/// Optional targeted move IDs for ad-hoc sessions launched from the schedule.
/// When set, this takes precedence over state/deck session resolution.
final reviewSessionTargetMoveIdsProvider = StateProvider<Set<String>?>(
  (ref) => null,
);

/// Filtered + shuffled moves for the current review session.
final filteredReviewMovesProvider = FutureProvider<List<Move>>((ref) async {
  // Bind to a seed so we only re-fetch/reshuffle when explicitly requested
  final seed = ref.watch(_sessionSeedProvider);
  final source = ref.watch(reviewSessionSourceProvider);
  final stateFilter = ref.watch(reviewStateFilterProvider);
  final sessionSize = ref.watch(reviewSessionSizeProvider);
  final selectedDeck = ref.watch(selectedDeckProvider);
  final targetMoveIds = ref.watch(reviewSessionTargetMoveIdsProvider);

  List<Move> moves;
  if (targetMoveIds != null && targetMoveIds.isNotEmpty) {
    final allMoves = await ref.watch(movesDaoProvider).getAll();
    moves = allMoves.where((move) => targetMoveIds.contains(move.id)).toList();
  } else if (source == ReviewSessionSource.deck) {
    if (selectedDeck == null) return [];
    moves = await ref.watch(deckServiceProvider).resolveDeck(selectedDeck);
  } else {
    moves = await ref.watch(movesDaoProvider).getAll();
    if (stateFilter != null) {
      moves = moves
          .where((move) => move.learningState == stateFilter.dbValue)
          .toList();
    }
  }

  final shuffled = List<Move>.from(moves)..shuffle(Random(seed));
  final effectiveSessionSize = switch (source) {
    ReviewSessionSource.deck => selectedDeck?.sessionSize,
    ReviewSessionSource.stateBased => sessionSize,
  };
  if (effectiveSessionSize != null && shuffled.length > effectiveSessionSize) {
    return shuffled.sublist(0, effectiveSessionSize);
  }
  return shuffled;
});

/// Refreshes the active review session (fetches new due cards and reshuffles).
void refreshReviewSession(WidgetRef ref) {
  ref.read(_sessionSeedProvider.notifier).state =
      DateTime.now().millisecondsSinceEpoch;
}

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
final moveCategoryCountsProvider = StreamProvider<Map<String, int>>((ref) {
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

// ---------------------------------------------------------------------------
// FSRS-powered pre-screen providers
// ---------------------------------------------------------------------------

/// Whether the user is in an active review session (showing flashcards)
/// or on the mastery pre-screen.
final reviewSessionActiveProvider = StateProvider<bool>((ref) => false);

/// FSRS category mastery data for the pre-screen grid.
final categoryMasteryProvider = FutureProvider<List<CategoryMastery>>((
  ref,
) async {
  return ref.watch(fsrsServiceProvider).getCategoryMastery();
});

/// Anki-style due summary: New / Learning / Review breakdown.
final dueSummaryProvider = FutureProvider<DueSummary>((ref) async {
  return ref.watch(fsrsServiceProvider).getDueSummary();
});

/// Preview the scheduling interval for each rating on the current move.
final intervalPreviewProvider =
    FutureProvider.family<Map<ReviewRating, Duration>, String>((
      ref,
      moveId,
    ) async {
      return ref.watch(fsrsServiceProvider).previewIntervals(moveId);
    });

/// Next due date for empty-state countdown ("Next review in 2h 14m").
final nextDueDateProvider = FutureProvider<DateTime?>((ref) async {
  final dao = ref.watch(fsrsCardsDaoProvider);
  return dao.getNextDueDate();
});

// ---------------------------------------------------------------------------
// Schedule mode providers (calendar-based review)
// ---------------------------------------------------------------------------

/// Master list of all reviewable items with their FSRS cards.
/// Refreshes whenever FSRS cards change (reviews processed).
final allReviewableItemsProvider = FutureProvider<List<ReviewableItemWithCard>>(
  (ref) async {
    // Watch the refresh stream to auto-invalidate on card changes
    ref.watch(fsrsCardsRefreshProvider);
    return ref.watch(fsrsServiceProvider).getAllItems();
  },
);

/// Currently selected date on the schedule calendar.
final reviewCalendarSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Due counts per date for the schedule calendar dots.
///
/// Groups all FSRS cards by their due date (midnight-normalized) so the
/// calendar can show colored indicators on each day.
final calendarDueCountsProvider = FutureProvider<Map<DateTime, int>>((
  ref,
) async {
  ref.watch(fsrsCardsRefreshProvider);
  final items = await ref.watch(allReviewableItemsProvider.future);
  final counts = <DateTime, int>{};
  for (final item in items) {
    final due = item.dueDate;
    final day = DateTime(due.year, due.month, due.day);
    counts[day] = (counts[day] ?? 0) + 1;
  }
  return counts;
});

/// Items grouped by due date for the calendar drilldown.
final calendarDueMapProvider =
    FutureProvider<Map<DateTime, List<ReviewableItemWithCard>>>((ref) async {
      ref.watch(fsrsCardsRefreshProvider);
      final items = await ref.watch(allReviewableItemsProvider.future);
      final map = <DateTime, List<ReviewableItemWithCard>>{};
      for (final item in items) {
        final due = item.dueDate;
        final day = DateTime(due.year, due.month, due.day);
        map.putIfAbsent(day, () => []).add(item);
      }
      return map;
    });

/// Items due on the currently selected calendar date.
final itemsDueOnSelectedDateProvider =
    FutureProvider<List<ReviewableItemWithCard>>((ref) async {
      final selectedDate = ref.watch(reviewCalendarSelectedDateProvider);
      final dueMap = await ref.watch(calendarDueMapProvider.future);
      final day = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      // For today and past dates, also include overdue items
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (!day.isAfter(today)) {
        // Include items due on or before selected date
        final items = <ReviewableItemWithCard>[];
        for (final entry in dueMap.entries) {
          if (!entry.key.isAfter(day)) {
            items.addAll(entry.value);
          }
        }
        // Sort by due date (most overdue first)
        items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        return items;
      }

      return dueMap[day] ?? [];
    });

/// Per-item FSRS math coefficients for the detail sheet.
final srsCoefficientsProvider =
    FutureProvider.family<
      SrsCoefficients,
      ({String entityId, String entityType})
    >((ref, params) async {
      return ref
          .watch(fsrsServiceProvider)
          .getSrsCoefficients(params.entityId, entityType: params.entityType);
    });

/// Aggregate SRS overview stats.
final srsOverviewProvider = FutureProvider<SrsOverview>((ref) async {
  ref.watch(fsrsCardsRefreshProvider);
  final items = await ref.watch(allReviewableItemsProvider.future);
  final now = DateTime.now().toUtc();
  final endOfToday = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
  final endOfTomorrow = endOfToday.add(const Duration(days: 1));

  int dueNow = 0, dueToday = 0, dueTomorrow = 0;
  double totalRetention = 0;
  double totalStability = 0;
  int reviewedCount = 0;

  for (final item in items) {
    final card = item.card;
    if (card == null) continue;

    if (!card.due.isAfter(now)) dueNow++;
    if (!card.due.isAfter(endOfToday)) dueToday++;
    if (card.due.isAfter(endOfToday) && !card.due.isAfter(endOfTomorrow)) {
      dueTomorrow++;
    }

    if (card.lastReview != null) {
      totalRetention += item.retrievability;
      totalStability += card.stability;
      reviewedCount++;
    }
  }

  return SrsOverview(
    totalCards: items.length,
    dueNow: dueNow,
    dueToday: dueToday,
    dueTomorrow: dueTomorrow,
    avgRetention: reviewedCount > 0 ? totalRetention / reviewedCount : 0,
    avgStability: reviewedCount > 0 ? totalStability / reviewedCount : 0,
  );
});
