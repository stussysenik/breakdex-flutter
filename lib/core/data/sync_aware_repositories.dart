import '../database/database.dart';
import '../database/daos/combos_dao.dart';
import '../database/daos/sync_dao.dart';
import 'repositories.dart';

/// Decorator that wraps a [MoveRepository] and logs mutations to [SyncDao].
class SyncAwareMoveRepository implements MoveRepository {
  final MoveRepository _inner;
  final SyncDao _syncDao;

  SyncAwareMoveRepository(this._inner, this._syncDao);

  // Reads — zero overhead, delegate directly
  @override
  Stream<List<Move>> watchAll() => _inner.watchAll();
  @override
  Stream<List<Move>> watchByCategory(String category) =>
      _inner.watchByCategory(category);
  @override
  Stream<Move> watchById(String id) => _inner.watchById(id);
  @override
  Future<List<Move>> getAll() => _inner.getAll();
  @override
  Future<Move> getById(String id) => _inner.getById(id);
  @override
  Stream<List<Move>> watchByState(String state) => _inner.watchByState(state);

  // Writes — delegate + log
  @override
  Future<void> insert(MovesCompanion move) async {
    await _inner.insert(move);
    final hasVideo = move.videoPath.present && move.videoPath.value != null;
    await _syncDao.logChange(
      entityId: move.id.value,
      table: 'moves',
      action: 'create',
      hasVideo: hasVideo,
    );
  }

  @override
  Future<void> update(MovesCompanion move) async {
    await _inner.update(move);
    final hasVideo = move.videoPath.present && move.videoPath.value != null;
    await _syncDao.logChange(
      entityId: move.id.value,
      table: 'moves',
      action: 'update',
      hasVideo: hasVideo,
    );
  }

  @override
  Future<void> delete(String id) async {
    await _inner.delete(id);
    await _syncDao.logChange(entityId: id, table: 'moves', action: 'delete');
  }
}

/// Decorator that wraps a [ComboRepository] and logs mutations to [SyncDao].
class SyncAwareComboRepository implements ComboRepository {
  final ComboRepository _inner;
  final SyncDao _syncDao;

  SyncAwareComboRepository(this._inner, this._syncDao);

  // Reads
  @override
  Stream<List<Combo>> watchAll() => _inner.watchAll();
  @override
  Stream<List<(Combo, int)>> watchAllWithMoveCounts() =>
      _inner.watchAllWithMoveCounts();
  @override
  Future<List<Combo>> getAll() => _inner.getAll();
  @override
  Future<Combo> getById(String id) => _inner.getById(id);
  @override
  Stream<Combo> watchById(String id) => _inner.watchById(id);
  @override
  Stream<List<ComboMoveWithDetail>> watchComboMoves(String comboId) =>
      _inner.watchComboMoves(comboId);

  // Writes
  @override
  Future<void> insert(CombosCompanion combo) async {
    await _inner.insert(combo);
    final hasVideo =
        combo.activeVideoPath.present && combo.activeVideoPath.value != null;
    await _syncDao.logChange(
      entityId: combo.id.value,
      table: 'combos',
      action: 'create',
      hasVideo: hasVideo,
    );
  }

  @override
  Future<void> addMove(ComboMovesCompanion entry) async {
    await _inner.addMove(entry);
    await _syncDao.logChange(
      entityId: entry.id.value,
      table: 'combo_moves',
      action: 'create',
    );
  }

  @override
  Future<void> delete(String id) async {
    await _inner.delete(id);
    await _syncDao.logChange(entityId: id, table: 'combos', action: 'delete');
  }

  @override
  Future<void> removeMove(String id) async {
    await _inner.removeMove(id);
    await _syncDao.logChange(
      entityId: id,
      table: 'combo_moves',
      action: 'delete',
    );
  }
}

/// Decorator that wraps a [ReviewRepository] and logs mutations to [SyncDao].
class SyncAwareReviewRepository implements ReviewRepository {
  final ReviewRepository _inner;
  final SyncDao _syncDao;

  SyncAwareReviewRepository(this._inner, this._syncDao);

  // Reads
  @override
  Stream<List<Review>> watchAll() => _inner.watchAll();
  @override
  Future<List<Review>> getByMoveId(String moveId) => _inner.getByMoveId(moveId);
  @override
  Future<int> countAll() => _inner.countAll();
  @override
  Future<List<Review>> getInRange(DateTime start, DateTime end) =>
      _inner.getInRange(start, end);
  @override
  Future<Map<DateTime, int>> dailyCountsSince(DateTime since) =>
      _inner.dailyCountsSince(since);
  @override
  Future<Map<String, int>> ratingDistribution() => _inner.ratingDistribution();
  @override
  Future<List<MapEntry<String, int>>> topReviewedMoves(int limit) =>
      _inner.topReviewedMoves(limit);
  @override
  Future<int> currentStreak() => _inner.currentStreak();

  // Writes
  @override
  Future<void> insert(ReviewsCompanion review) async {
    await _inner.insert(review);
    await _syncDao.logChange(
      entityId: review.id.value,
      table: 'reviews',
      action: 'create',
    );
  }
}
