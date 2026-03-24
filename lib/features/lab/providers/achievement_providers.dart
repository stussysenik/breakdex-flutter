import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/database/daos/achievements_dao.dart';
import '../../../core/providers.dart';
import '../../../core/services/achievement_service.dart';

// ---------------------------------------------------------------------------
// DAO provider — follows the same pattern as movesDaoProvider, etc.
// ---------------------------------------------------------------------------

final achievementsDaoProvider = Provider<AchievementsDao>((ref) {
  return ref.watch(databaseProvider).achievementsDao;
});

// ---------------------------------------------------------------------------
// Service provider — pure logic, no UI. Mirrors fsrsServiceProvider pattern.
// ---------------------------------------------------------------------------

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService(
    achievementsDao: ref.watch(achievementsDaoProvider),
    reviewsDao: ref.watch(reviewsDaoProvider),
    fsrsCardsDao: ref.watch(fsrsCardsDaoProvider),
  );
});

// ---------------------------------------------------------------------------
// Reactive stream — all achievements. Rebuilds when any tier changes.
// Follows the same StreamProvider pattern as fsrsCardsRefreshProvider.
// ---------------------------------------------------------------------------

final allAchievementsProvider = StreamProvider<List<Achievement>>((ref) {
  return ref.watch(achievementsDaoProvider).watchAll();
});

// ---------------------------------------------------------------------------
// Single-move tier lookup. FutureProvider.family keyed by moveId.
// ---------------------------------------------------------------------------

final moveAchievementProvider =
    FutureProvider.family<String?, String>((ref, moveId) async {
  // Re-evaluate when the achievements stream changes.
  ref.watch(allAchievementsProvider);
  return ref.watch(achievementsDaoProvider).getCurrentTier(moveId);
});

// ---------------------------------------------------------------------------
// Garden data — achievements enriched with move names for display.
// Sorted by tier descending (mastered first), then alphabetically.
// ---------------------------------------------------------------------------

/// A single tile in the Achievement Garden grid.
class GardenEntry {
  const GardenEntry({
    required this.moveId,
    required this.moveName,
    required this.tier,
  });

  final String moveId;
  final String moveName;
  final String tier;
}

/// Tier counts for the summary header.
class GardenSummary {
  const GardenSummary({
    required this.entries,
    required this.mastered,
    required this.growing,
    required this.sprouting,
    required this.seed,
  });

  final List<GardenEntry> entries;
  final int mastered;
  final int growing;
  final int sprouting;
  final int seed;
}

/// Tier rank for sorting — mastered first, seed last.
const _tierSortRank = <String, int>{
  'mastered': 0,
  'growing': 1,
  'sprouting': 2,
  'seed': 3,
};

final achievementGardenProvider = FutureProvider<GardenSummary>((ref) async {
  // Watch both streams so the garden updates on move or achievement changes.
  ref.watch(allAchievementsProvider);
  final db = ref.watch(databaseProvider);

  final results = await Future.wait([
    db.achievementsDao.getAll(),
    db.movesDao.getAll(),
  ]);

  final achievements = results[0] as List<Achievement>;
  final moves = results[1] as List<Move>;
  final moveMap = {for (final m in moves) m.id: m};

  int mastered = 0, growing = 0, sprouting = 0, seed = 0;
  final entries = <GardenEntry>[];

  for (final achievement in achievements) {
    final move = moveMap[achievement.moveId];
    if (move == null) continue; // Orphan achievement — move was deleted.

    entries.add(GardenEntry(
      moveId: move.id,
      moveName: move.name,
      tier: achievement.tier,
    ));

    switch (achievement.tier) {
      case 'mastered':
        mastered++;
      case 'growing':
        growing++;
      case 'sprouting':
        sprouting++;
      case 'seed':
        seed++;
    }
  }

  // Sort: mastered first, then growing, sprouting, seed.
  // Within same tier, alphabetical by move name.
  entries.sort((a, b) {
    final rankCompare =
        (_tierSortRank[a.tier] ?? 3).compareTo(_tierSortRank[b.tier] ?? 3);
    if (rankCompare != 0) return rankCompare;
    return a.moveName.toLowerCase().compareTo(b.moveName.toLowerCase());
  });

  return GardenSummary(
    entries: entries,
    mastered: mastered,
    growing: growing,
    sprouting: sprouting,
    seed: seed,
  );
});
