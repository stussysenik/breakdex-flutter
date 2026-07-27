import 'package:breakdex/core/database/daos/achievements_dao.dart';
import 'package:breakdex/core/database/daos/fsrs_cards_dao.dart';
import 'package:breakdex/core/database/daos/reviews_dao.dart';

/// Pure-logic service that evaluates tier advancement for the Achievement Garden.
///
/// Tier progression follows a botanical metaphor — moves grow from Seed to
/// Mastered as the learner demonstrates increasing recall quality:
///
///   Seed       → move exists (auto-created on move insert)
///   Sprouting  → at least 1 review recorded
///   Growing    → 5+ reviews with >60% rated GOOD or EASY
///   Mastered   → FSRS card in Review state (fsrsState=2) with stability > 7.0
///
/// Tiers only advance forward; a move never regresses. This mirrors real
/// botanical growth — a plant doesn't un-sprout — and protects against
/// discouraging the learner after a bad session.
class AchievementService {
  AchievementService({
    required final AchievementsDao achievementsDao,
    required final ReviewsDao reviewsDao,
    required final FsrsCardsDao fsrsCardsDao,
  })  : _achievementsDao = achievementsDao,
        _reviewsDao = reviewsDao,
        _fsrsCardsDao = fsrsCardsDao;

  final AchievementsDao _achievementsDao;
  final ReviewsDao _reviewsDao;
  final FsrsCardsDao _fsrsCardsDao;

  /// Tier rank ordering — used to enforce forward-only progression.
  static const _tierRank = <String, int>{
    'seed': 0,
    'sprouting': 1,
    'growing': 2,
    'mastered': 3,
  };

  /// Check whether [moveId] qualifies for a higher tier and advance if so.
  ///
  /// Returns the new tier name if the move was promoted, or `null` if
  /// it already sits at or above the tier it qualifies for.
  ///
  /// The check walks tiers top-down (mastered → seed) and picks the highest
  /// tier the move currently qualifies for, then upserts if it exceeds the
  /// stored tier. This means a move can skip tiers (e.g. seed → growing)
  /// if the criteria are met in a single review burst.
  Future<String?> checkAndAdvanceTier(final String moveId) async {
    final currentTier = await _achievementsDao.getCurrentTier(moveId);
    final currentRank = _tierRank[currentTier] ?? -1;

    // Determine the highest tier this move qualifies for right now.
    final qualifiedTier = await _computeQualifiedTier(moveId);
    final qualifiedRank = _tierRank[qualifiedTier] ?? 0;

    if (qualifiedRank > currentRank) {
      await _achievementsDao.upsertTier(moveId, qualifiedTier);
      return qualifiedTier;
    }

    return null; // No advancement.
  }

  /// Walk the tier ladder top-down and return the highest tier the move
  /// currently satisfies.
  Future<String> _computeQualifiedTier(final String moveId) async {
    // Check mastered first (highest) — short-circuit if met.
    if (await _checkMastered(moveId)) return 'mastered';
    if (await _checkGrowing(moveId)) return 'growing';
    if (await _checkSprouting(moveId)) return 'sprouting';
    return 'seed';
  }

  /// **Mastered**: FSRS card exists with fsrsState=2 (Review) AND
  /// stability > 7.0. A stability of 7 means the card's memory half-life
  /// is ~7 days — the learner can reliably recall it a week later.
  Future<bool> _checkMastered(final String moveId) async {
    final card = await _fsrsCardsDao.getByMoveId(moveId);
    if (card == null) return false;
    return card.fsrsState == 2 && card.stability > 7.0;
  }

  /// **Growing**: 5+ reviews AND >60% rated GOOD or EASY.
  /// This ensures quantity (repeated practice) AND quality (consistent recall).
  Future<bool> _checkGrowing(final String moveId) async {
    final reviews = await _reviewsDao.getByMoveId(moveId);
    if (reviews.length < 5) return false;

    final goodOrEasy = reviews.where(
      (final r) => r.rating == 'GOOD' || r.rating == 'EASY',
    ).length;
    return goodOrEasy / reviews.length > 0.6;
  }

  /// **Sprouting**: At least 1 review exists for the move.
  Future<bool> _checkSprouting(final String moveId) async {
    final reviews = await _reviewsDao.getByMoveId(moveId);
    return reviews.isNotEmpty;
  }
}
