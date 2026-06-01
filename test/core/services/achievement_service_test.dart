import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/achievement_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';
import '../../helpers/test_database.dart';

/// Tests for [AchievementService] — pure-logic tier advancement for the
/// Achievement Garden.
///
/// Tier progression:
///   Seed       -> move exists (auto-created)
///   Sprouting  -> at least 1 review recorded
///   Growing    -> 5+ reviews with >60% rated GOOD or EASY
///   Mastered   -> FSRS card in Review state (fsrsState=2) with stability > 7.0
///
/// Tiers only advance forward — a move never regresses. The service evaluates
/// all criteria top-down (mastered first) and picks the highest qualified tier,
/// allowing moves to skip tiers if the criteria are met in a single burst.
void main() {
  late AppDatabase db;
  late AchievementService service;

  setUp(() {
    db = createTestDatabase();
    service = AchievementService(
      achievementsDao: db.achievementsDao,
      reviewsDao: db.reviewsDao,
      fsrsCardsDao: db.fsrsCardsDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Seeds a move and its seed-tier achievement (simulating the auto-backfill
  /// that happens on move creation in the real app).
  Future<void> seedMoveWithAchievement(
    final String moveId, {
    final String name = 'Test Move',
  }) async {
    await seedMove(db, id: moveId, name: name);
    await db.achievementsDao.upsertTier(moveId, 'seed');
  }

  /// Seeds N reviews for a move with the given rating distribution.
  Future<void> seedReviews(
    final String moveId, {
    final int goodCount = 0,
    final int easyCount = 0,
    final int hardCount = 0,
    final int againCount = 0,
  }) async {
    var idx = 0;
    for (var i = 0; i < goodCount; i++) {
      await seedReview(db,
          id: 'review-$moveId-${idx++}', moveId: moveId, rating: 'GOOD');
    }
    for (var i = 0; i < easyCount; i++) {
      await seedReview(db,
          id: 'review-$moveId-${idx++}', moveId: moveId, rating: 'EASY');
    }
    for (var i = 0; i < hardCount; i++) {
      await seedReview(db,
          id: 'review-$moveId-${idx++}', moveId: moveId, rating: 'HARD');
    }
    for (var i = 0; i < againCount; i++) {
      await seedReview(db,
          id: 'review-$moveId-${idx++}', moveId: moveId, rating: 'AGAIN');
    }
  }

  // ---------------------------------------------------------------------------
  // Tier: Seed
  // ---------------------------------------------------------------------------

  group('Seed tier', () {
    test('new move with seed achievement returns null (already at seed)',
        () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');

      final result = await service.checkAndAdvanceTier('move-1');
      // Already at seed, and no reviews => qualifies for seed => no advancement.
      expect(result, isNull);
    });

    test('move with no achievement gets seed tier', () async {
      await seedMove(db, id: 'move-1', name: 'Windmill');
      // No achievement row exists yet — currentRank will be -1.

      final result = await service.checkAndAdvanceTier('move-1');
      expect(result, 'seed');

      final tier = await db.achievementsDao.getCurrentTier('move-1');
      expect(tier, 'seed');
    });
  });

  // ---------------------------------------------------------------------------
  // Tier: Sprouting (1+ review)
  // ---------------------------------------------------------------------------

  group('Sprouting tier', () {
    test('move with 1 review advances to sprouting', () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      await seedReviews('move-1', hardCount: 1);

      final result = await service.checkAndAdvanceTier('move-1');
      expect(result, 'sprouting');

      final tier = await db.achievementsDao.getCurrentTier('move-1');
      expect(tier, 'sprouting');
    });

    test('move with 3 reviews but <60% good still gets sprouting', () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      // 1 good + 2 hard = 33% good — below 60% threshold.
      await seedReviews('move-1', goodCount: 1, hardCount: 2);

      final result = await service.checkAndAdvanceTier('move-1');
      expect(result, 'sprouting');
    });
  });

  // ---------------------------------------------------------------------------
  // Tier: Growing (5+ reviews, >60% good/easy)
  // ---------------------------------------------------------------------------

  group('Growing tier', () {
    test('5+ reviews with >60% good/easy advances to growing', () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      // 4 good + 1 easy + 1 hard = 6 total, 5/6 = 83% good/easy.
      await seedReviews('move-1', goodCount: 4, easyCount: 1, hardCount: 1);

      final result = await service.checkAndAdvanceTier('move-1');
      expect(result, 'growing');
    });

    test('exactly 5 reviews with 4 good/easy (80%) advances to growing',
        () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      // 3 good + 1 easy + 1 again = 5 total, 4/5 = 80%.
      await seedReviews('move-1', goodCount: 3, easyCount: 1, againCount: 1);

      final result = await service.checkAndAdvanceTier('move-1');
      expect(result, 'growing');
    });

    test('5 reviews with exactly 60% good/easy does NOT qualify (needs >60%)',
        () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      // 3 good + 2 hard = 5 total, 3/5 = 60% (not >60%).
      await seedReviews('move-1', goodCount: 3, hardCount: 2);

      final result = await service.checkAndAdvanceTier('move-1');
      // 60% is not >60%, so qualifies for sprouting, not growing.
      expect(result, 'sprouting');
    });

    test('4 reviews with all good does NOT qualify (needs 5+)', () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      await seedReviews('move-1', goodCount: 4);

      final result = await service.checkAndAdvanceTier('move-1');
      // Only 4 reviews — not enough for growing, so sprouting.
      expect(result, 'sprouting');
    });
  });

  // ---------------------------------------------------------------------------
  // Tier: Mastered (FSRS card state=2, stability > 7.0)
  // ---------------------------------------------------------------------------

  group('Mastered tier', () {
    test('FSRS card with state=2 and stability > 7 advances to mastered',
        () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      // Seed reviews to satisfy growing threshold too.
      await seedReviews('move-1', goodCount: 5);
      // FSRS card: fsrsState=2 (Review), stability=10.0.
      await seedFsrsCard(db,
          entityId: 'move-1',
          entityType: 'move',
          fsrsState: 2,
          stability: 10.0);

      final result = await service.checkAndAdvanceTier('move-1');
      expect(result, 'mastered');
    });

    test('FSRS card with state=2 but stability <= 7 does NOT qualify',
        () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      await seedReviews('move-1', goodCount: 5);
      await seedFsrsCard(db,
          entityId: 'move-1',
          entityType: 'move',
          fsrsState: 2,
          stability: 5.0);

      final result = await service.checkAndAdvanceTier('move-1');
      // Does not qualify for mastered, falls to growing.
      expect(result, 'growing');
    });

    test('FSRS card with state=1 (learning) does NOT qualify for mastered',
        () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      await seedReviews('move-1', goodCount: 5);
      await seedFsrsCard(db,
          entityId: 'move-1',
          entityType: 'move',
          fsrsState: 1,
          stability: 15.0);

      final result = await service.checkAndAdvanceTier('move-1');
      // state=1 is Learning, not Review — falls to growing.
      expect(result, 'growing');
    });
  });

  // ---------------------------------------------------------------------------
  // Forward-only invariant
  // ---------------------------------------------------------------------------

  group('Forward-only progression', () {
    test('already mastered returns null (no change)', () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      // Advance directly to mastered.
      await db.achievementsDao.upsertTier('move-1', 'mastered');

      final result = await service.checkAndAdvanceTier('move-1');
      // Even with no reviews/FSRS card, mastered stays mastered.
      expect(result, isNull);
    });

    test('already growing with sprouting-level criteria returns null',
        () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      await db.achievementsDao.upsertTier('move-1', 'growing');
      // Only 1 review — qualifies for sprouting, but already growing.
      await seedReviews('move-1', hardCount: 1);

      final result = await service.checkAndAdvanceTier('move-1');
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Tier skipping
  // ---------------------------------------------------------------------------

  group('Tier skipping', () {
    test('seed can jump straight to growing with sufficient reviews', () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      // 6 good reviews => qualifies for growing immediately.
      await seedReviews('move-1', goodCount: 6);

      final result = await service.checkAndAdvanceTier('move-1');
      expect(result, 'growing');
    });

    test('seed can jump straight to mastered with FSRS + reviews', () async {
      await seedMoveWithAchievement('move-1', name: 'Windmill');
      await seedReviews('move-1', goodCount: 6);
      await seedFsrsCard(db,
          entityId: 'move-1',
          entityType: 'move',
          fsrsState: 2,
          stability: 10.0);

      final result = await service.checkAndAdvanceTier('move-1');
      expect(result, 'mastered');
    });
  });
}
