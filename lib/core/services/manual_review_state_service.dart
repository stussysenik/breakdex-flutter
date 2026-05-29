import 'package:drift/drift.dart';

import '../data/repositories.dart';
import '../database/daos/fsrs_cards_dao.dart';
import '../database/daos/sync_dao.dart';
import '../models/learning_state.dart';
import '../database/database.dart';

class ManualMoveStateResult {
  const ManualMoveStateResult({
    required this.reviewRating,
    required this.preFsrsState,
    required this.postFsrsState,
  });

  final ReviewRating reviewRating;
  final int preFsrsState;
  final int postFsrsState;
}

class ManualReviewStateService {
  ManualReviewStateService({
    required MoveRepository moveRepository,
    required FsrsCardsDao fsrsCardsDao,
    required SyncDao syncDao,
  }) : _moveRepository = moveRepository,
       _fsrsCardsDao = fsrsCardsDao,
       _syncDao = syncDao;

  final MoveRepository _moveRepository;
  final FsrsCardsDao _fsrsCardsDao;
  final SyncDao _syncDao;

  Future<ManualMoveStateResult> setMoveState(
    Move move,
    LearningState nextState,
  ) async {
    final existingCard = await _fsrsCardsDao.getByEntityId(move.id);
    final preFsrsState = existingCard?.fsrsState ?? 0;
    final syncAction = existingCard == null ? 'create' : 'update';

    final (targetFsrsState, rating, due, lastReview, reps) = switch (nextState) {
      LearningState.newState => (
        0,
        ReviewRating.again,
        DateTime.now().toUtc(),
        null,
        0,
      ),
      LearningState.learning => (
        1,
        ReviewRating.hard,
        DateTime.now().toUtc(),
        DateTime.now().toUtc(),
        1,
      ),
      LearningState.mastery => (
        2,
        ReviewRating.good,
        DateTime.now().toUtc().add(const Duration(hours: 24)),
        DateTime.now().toUtc(),
        1,
      ),
    };

    await _fsrsCardsDao.upsert(
      FsrsCardsCompanion(
        entityId: Value(move.id),
        entityType: const Value('move'),
        stability: const Value(0.0),
        difficulty: const Value(0.0),
        due: Value(due),
        lastReview: Value(lastReview),
        reps: Value(reps),
        lapses: const Value(0),
        fsrsState: Value(targetFsrsState),
      ),
    );

    await _moveRepository.update(
      MovesCompanion(
        id: Value(move.id),
        learningState: Value(nextState.dbValue),
      ),
    );
    await _syncDao.logChange(
      entityId: move.id,
      table: 'fsrs_cards',
      action: syncAction,
    );

    return ManualMoveStateResult(
      reviewRating: rating,
      preFsrsState: preFsrsState,
      postFsrsState: targetFsrsState,
    );
  }

}
