import 'package:breakdex/core/database/database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_data.dart';
import '../../../helpers/test_database.dart';

/// Tests for [AchievementsDao] — tier-based achievement storage for the
/// Achievement Garden.
///
/// The key invariant: tiers only advance forward (seed -> sprouting -> growing
/// -> mastered). Downgrades are silently ignored so a bad review session can
/// never regress a hard-earned milestone.
void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Seeds a move and inserts a seed-tier achievement for it.
  Future<void> seedAchievement(
    String moveId, {
    String tier = 'seed',
    String moveName = 'Test Move',
  }) async {
    await seedMove(db, id: moveId, name: moveName);
    await db.achievementsDao.upsertTier(moveId, tier);
  }

  // ---------------------------------------------------------------------------
  // upsertTier — forward advancement
  // ---------------------------------------------------------------------------

  group('upsertTier advancement', () {
    test('creates seed tier for new move', () async {
      await seedMove(db, id: 'move-1', name: 'Windmill');
      await db.achievementsDao.upsertTier('move-1', 'seed');

      final tier = await db.achievementsDao.getCurrentTier('move-1');
      expect(tier, 'seed');
    });

    test('advances from seed to sprouting', () async {
      await seedAchievement('move-1');

      await db.achievementsDao.upsertTier('move-1', 'sprouting');

      final tier = await db.achievementsDao.getCurrentTier('move-1');
      expect(tier, 'sprouting');
    });

    test('advances from sprouting to growing', () async {
      await seedAchievement('move-1', tier: 'sprouting');

      await db.achievementsDao.upsertTier('move-1', 'growing');

      final tier = await db.achievementsDao.getCurrentTier('move-1');
      expect(tier, 'growing');
    });

    test('advances from growing to mastered', () async {
      await seedAchievement('move-1', tier: 'growing');

      await db.achievementsDao.upsertTier('move-1', 'mastered');

      final tier = await db.achievementsDao.getCurrentTier('move-1');
      expect(tier, 'mastered');
    });

    test('can skip tiers (seed -> growing)', () async {
      await seedAchievement('move-1');

      await db.achievementsDao.upsertTier('move-1', 'growing');

      final tier = await db.achievementsDao.getCurrentTier('move-1');
      expect(tier, 'growing');
    });
  });

  // ---------------------------------------------------------------------------
  // upsertTier — downgrade prevention
  // ---------------------------------------------------------------------------

  group('upsertTier downgrade prevention', () {
    test('mastered ignores downgrade to seed', () async {
      await seedAchievement('move-1', tier: 'mastered');

      await db.achievementsDao.upsertTier('move-1', 'seed');

      final tier = await db.achievementsDao.getCurrentTier('move-1');
      expect(tier, 'mastered');
    });

    test('growing ignores downgrade to sprouting', () async {
      await seedAchievement('move-1', tier: 'growing');

      await db.achievementsDao.upsertTier('move-1', 'sprouting');

      final tier = await db.achievementsDao.getCurrentTier('move-1');
      expect(tier, 'growing');
    });

    test('same tier is a no-op', () async {
      await seedAchievement('move-1', tier: 'sprouting');

      await db.achievementsDao.upsertTier('move-1', 'sprouting');

      final tier = await db.achievementsDao.getCurrentTier('move-1');
      expect(tier, 'sprouting');
    });
  });

  // ---------------------------------------------------------------------------
  // getCurrentTier
  // ---------------------------------------------------------------------------

  group('getCurrentTier', () {
    test('returns null for move with no achievement', () async {
      final tier = await db.achievementsDao.getCurrentTier('nonexistent');
      expect(tier, isNull);
    });

    test('returns highest tier after multiple upserts', () async {
      await seedAchievement('move-1');
      await db.achievementsDao.upsertTier('move-1', 'sprouting');
      await db.achievementsDao.upsertTier('move-1', 'growing');

      final tier = await db.achievementsDao.getCurrentTier('move-1');
      expect(tier, 'growing');
    });
  });

  // ---------------------------------------------------------------------------
  // getAll & watchAll
  // ---------------------------------------------------------------------------

  group('getAll & watchAll', () {
    test('getAll returns all achievements', () async {
      await seedAchievement('move-1', moveName: 'Windmill');
      await seedAchievement('move-2', moveName: 'Headspin');
      await seedAchievement('move-3', moveName: 'Flare');

      final all = await db.achievementsDao.getAll();
      expect(all, hasLength(3));
    });

    test('watchAll includes all achievements reactively', () async {
      final stream = db.achievementsDao.watchAll();

      // Initially empty.
      final initial = await stream.first;
      expect(initial, isEmpty);

      // Add an achievement.
      await seedAchievement('move-1', moveName: 'Windmill');
      final afterInsert = await stream.first;
      expect(afterInsert, hasLength(1));
      expect(afterInsert.first.tier, 'seed');

      // Advance tier.
      await db.achievementsDao.upsertTier('move-1', 'sprouting');
      final afterAdvance = await stream.first;
      expect(afterAdvance, hasLength(1));
      expect(afterAdvance.first.tier, 'sprouting');
    });

    test('getByMoveId returns correct achievement', () async {
      await seedAchievement('move-1', moveName: 'Windmill');
      await seedAchievement('move-2', moveName: 'Headspin', tier: 'growing');

      final achievement = await db.achievementsDao.getByMoveId('move-2');
      expect(achievement, isNotNull);
      expect(achievement!.tier, 'growing');
      expect(achievement.moveId, 'move-2');
    });
  });
}
