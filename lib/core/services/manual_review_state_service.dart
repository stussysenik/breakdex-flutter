import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:breakdex/core/data/repositories.dart';
import 'package:breakdex/core/database/daos/fsrs_cards_dao.dart';
import 'package:breakdex/core/database/daos/sync_dao.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/database/database.dart';

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
    required final MoveRepository moveRepository,
    required final FsrsCardsDao fsrsCardsDao,
    required final SyncDao syncDao,
  }) : _moveRepository = moveRepository,
       _fsrsCardsDao = fsrsCardsDao,
       _syncDao = syncDao;

  final MoveRepository _moveRepository;
  final FsrsCardsDao _fsrsCardsDao;
  final SyncDao _syncDao;

  Future<ManualMoveStateResult> setMoveState(
    final Move move,
    final LearningState nextState,
  ) async {
    debugPrint('[ManualReviewState] setMoveState moveId=${move.id} oldState=${move.learningState} nextState=${nextState.name} dbValue=${nextState.dbValue}');
    final existingCard = await _fsrsCardsDao.getByEntityId(move.id);
    final preFsrsState = existingCard?.fsrsState ?? 0;
    final syncAction = existingCard == null ? 'create' : 'update';
    debugPrint('[ManualReviewState] existingCard=${existingCard != null} preFsrsState=$preFsrsState');

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
    debugPrint('[ManualReviewState] targetFsrsState=$targetFsrsState');

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
    debugPrint('[ManualReviewState] fsrsCard upserted');

    await _moveRepository.update(
      MovesCompanion(
        id: Value(move.id),
        learningState: Value(nextState.dbValue),
      ),
    );
    debugPrint('[ManualReviewState] moveRepo updated learningState=${nextState.dbValue}');

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
