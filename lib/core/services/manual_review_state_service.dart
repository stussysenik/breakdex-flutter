import 'package:drift/drift.dart';

import '../data/repositories.dart';
import '../database/daos/fsrs_cards_dao.dart';
import '../database/daos/sync_dao.dart';
import '../models/learning_state.dart';
import '../database/database.dart';
import 'fsrs_service.dart';

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
    required FsrsService fsrsService,
    required SyncDao syncDao,
  }) : _moveRepository = moveRepository,
       _fsrsCardsDao = fsrsCardsDao,
       _fsrsService = fsrsService,
       _syncDao = syncDao;

  final MoveRepository _moveRepository;
  final FsrsCardsDao _fsrsCardsDao;
  final FsrsService _fsrsService;
  final SyncDao _syncDao;

  Future<ManualMoveStateResult> setMoveState(
    Move move,
    LearningState nextState,
  ) async {
    final existingCard = await _fsrsCardsDao.getByEntityId(move.id);
    final preFsrsState = existingCard?.fsrsState ?? 0;
    final syncAction = existingCard == null ? 'create' : 'update';

    await _resetCardToNewBaseline(move.id);

    final result = switch (nextState) {
      LearningState.newState => ManualMoveStateResult(
        reviewRating: ReviewRating.again,
        preFsrsState: preFsrsState,
        postFsrsState: 0,
      ),
      LearningState.learning => await _applyFromBaseline(
        move.id,
        rating: ReviewRating.hard,
        preFsrsState: preFsrsState,
      ),
      LearningState.mastery => await _applyFromBaseline(
        move.id,
        rating: ReviewRating.good,
        preFsrsState: preFsrsState,
      ),
    };

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

    return result;
  }

  Future<void> _resetCardToNewBaseline(String moveId) {
    return _fsrsCardsDao.upsert(
      FsrsCardsCompanion(
        entityId: Value(moveId),
        entityType: const Value('move'),
        stability: const Value(0.0),
        difficulty: const Value(0.0),
        due: Value(DateTime.now().toUtc()),
        lastReview: const Value(null),
        reps: const Value(0),
        lapses: const Value(0),
        fsrsState: const Value(0),
      ),
    );
  }

  Future<ManualMoveStateResult> _applyFromBaseline(
    String moveId, {
    required ReviewRating rating,
    required int preFsrsState,
  }) async {
    final fsrsResult = await _fsrsService.processReview(
      moveId,
      rating,
      entityType: 'move',
    );
    return ManualMoveStateResult(
      reviewRating: rating,
      preFsrsState: preFsrsState,
      postFsrsState: fsrsResult.postState,
    );
  }
}
