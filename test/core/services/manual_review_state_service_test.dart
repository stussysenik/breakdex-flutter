import 'package:breakdex/core/data/drift_repositories.dart';
import 'package:breakdex/core/data/sync_aware_repositories.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/services/manual_review_state_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ManualReviewStateService service;

  setUp(() {
    db = createTestDatabase();
    service = ManualReviewStateService(
      moveRepository: SyncAwareMoveRepository(
        DriftMoveRepository(db.movesDao),
        db.syncDao,
      ),
      fsrsCardsDao: db.fsrsCardsDao,
      syncDao: db.syncDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('resetting a move to New keeps move and FSRS in sync', () async {
    await seedMove(db, id: 'manual-sync-new', name: 'Manual Sync');
    await (db.update(db.moves)..where((final t) => t.id.equals('manual-sync-new')))
        .write(const MovesCompanion(learningState: Value('MASTERY')));
    await seedFsrsCard(
      db,
      entityId: 'manual-sync-new',
      entityType: 'move',
      fsrsState: 2,
      stability: 9.0,
      difficulty: 4.0,
      due: DateTime.now().toUtc().add(const Duration(days: 7)),
    );

    final move = await db.movesDao.getById('manual-sync-new');
    final result = await service.setMoveState(move, LearningState.newState);
    final updatedMove = await db.movesDao.getById('manual-sync-new');
    final updatedCard = await db.fsrsCardsDao.getByEntityId('manual-sync-new');

    expect(result.reviewRating, ReviewRating.again);
    expect(result.preFsrsState, 2);
    expect(result.postFsrsState, 0);
    expect(updatedMove.learningState, 'NEW');
    expect(updatedCard, isNotNull);
    expect(updatedCard!.fsrsState, 0);
    expect(updatedCard.lastReview, isNull);
    expect(updatedCard.reps, 0);
    expect(updatedCard.lapses, 0);
    expect(updatedCard.due.isAfter(DateTime.now().toUtc()), isFalse);

    final pending = await db.syncDao.getPendingChanges();
    expect(
      pending.any(
        (final entry) =>
            entry.entityId == 'manual-sync-new' &&
            entry.entityTable == 'moves' &&
            entry.action == 'update',
      ),
      isTrue,
    );
    expect(
      pending.any(
        (final entry) =>
            entry.entityId == 'manual-sync-new' &&
            entry.entityTable == 'fsrs_cards' &&
            entry.action == 'update',
      ),
      isTrue,
    );
  });

  test(
    'setting a move to Mastery creates a matching review-state FSRS card',
    () async {
      await seedMove(db, id: 'manual-sync-mastery', name: 'Freeze');

      final move = await db.movesDao.getById('manual-sync-mastery');
      final result = await service.setMoveState(move, LearningState.mastery);
      final updatedMove = await db.movesDao.getById('manual-sync-mastery');
      final updatedCard = await db.fsrsCardsDao.getByEntityId(
        'manual-sync-mastery',
      );

      expect(result.reviewRating, ReviewRating.good);
      expect(result.preFsrsState, 0);
      expect(result.postFsrsState, 2);
      expect(updatedMove.learningState, 'MASTERY');
      expect(updatedCard, isNotNull);
      expect(updatedCard!.fsrsState, 2);
      expect(updatedCard.due.isAfter(DateTime.now().toUtc()), isTrue);

      final pending = await db.syncDao.getPendingChanges();
      expect(
        pending.any(
          (final entry) =>
              entry.entityId == 'manual-sync-mastery' &&
              entry.entityTable == 'fsrs_cards' &&
              entry.action == 'create',
        ),
        isTrue,
      );
    },
  );

  test('setting a move to Learning produces a learning FSRS state', () async {
    await seedMove(db, id: 'manual-sync-learning', name: 'Six Step');

    final move = await db.movesDao.getById('manual-sync-learning');
    final result = await service.setMoveState(move, LearningState.learning);
    final updatedMove = await db.movesDao.getById('manual-sync-learning');
    final updatedCard = await db.fsrsCardsDao.getByEntityId(
      'manual-sync-learning',
    );

    expect(result.reviewRating, ReviewRating.hard);
    expect(result.preFsrsState, 0);
    expect(result.postFsrsState, 1);
    expect(updatedMove.learningState, 'LEARNING');
    expect(updatedCard, isNotNull);
    expect(updatedCard!.fsrsState, 1);
  });
}
