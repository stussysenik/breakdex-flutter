import 'package:drift/drift.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/tables/achievements.dart';

part 'achievements_dao.g.dart';

/// Tier ordering from lowest to highest. Used by [AchievementsDao.upsertTier]
/// to decide whether a new tier supersedes the existing one.
const _tierRank = <String, int>{
  'seed': 0,
  'sprouting': 1,
  'growing': 2,
  'mastered': 3,
};

@DriftAccessor(tables: [Achievements])
class AchievementsDao extends DatabaseAccessor<AppDatabase>
    with _$AchievementsDaoMixin {
  AchievementsDao(super.db);

  /// Watch all achievements as a reactive stream.
  Stream<List<Achievement>> watchAll() => select(achievements).watch();

  /// Get all achievements.
  Future<List<Achievement>> getAll() => select(achievements).get();

  /// Get the achievement for a specific move, or null if none exists.
  Future<Achievement?> getByMoveId(final String moveId) =>
      (select(achievements)..where((final t) => t.moveId.equals(moveId)))
          .getSingleOrNull();

  /// Get the current (highest) tier for a move, or null if no achievement.
  Future<String?> getCurrentTier(final String moveId) async {
    final row = await getByMoveId(moveId);
    return row?.tier;
  }

  /// Insert or upgrade the tier for a move. If the new [tier] is higher than
  /// the current one the row is updated; if equal or lower it is silently
  /// ignored so callers don't need to pre-check.
  Future<void> upsertTier(final String moveId, final String tier) async {
    final existing = await getByMoveId(moveId);

    final newRank = _tierRank[tier] ?? 0;

    if (existing == null) {
      // No achievement yet — insert.
      await into(achievements).insert(
        AchievementsCompanion.insert(
          id: '${moveId}_$tier',
          moveId: moveId,
          tier: tier,
          unlockedAt: DateTime.now(),
        ),
      );
    } else {
      final currentRank = _tierRank[existing.tier] ?? 0;
      if (newRank > currentRank) {
        await (update(achievements)
              ..where((final t) => t.id.equals(existing.id)))
            .write(AchievementsCompanion(
              tier: Value(tier),
              unlockedAt: Value(DateTime.now()),
            ));
      }
      // newRank <= currentRank → no-op
    }
  }
}
