import '../database/database.dart';
import '../database/daos/moves_dao.dart';
import '../database/daos/combos_dao.dart';
import '../database/daos/reviews_dao.dart';
import 'repositories.dart';

class DriftMoveRepository implements MoveRepository {
  final MovesDao _dao;
  DriftMoveRepository(this._dao);

  @override
  Stream<List<Move>> watchAll() => _dao.watchAll();

  @override
  Stream<List<Move>> watchByCategory(String category) =>
      _dao.watchByCategory(category);

  @override
  Stream<Move> watchById(String id) => _dao.watchById(id);

  @override
  Future<List<Move>> getAll() => _dao.getAll();

  @override
  Future<Move> getById(String id) => _dao.getById(id);

  @override
  Future<void> insert(MovesCompanion move) => _dao.insertMove(move);

  @override
  Future<void> update(MovesCompanion move) => _dao.updateMove(move);

  @override
  Future<void> delete(String id) => _dao.deleteMove(id);

  @override
  Stream<List<Move>> watchByState(String state) => _dao.watchByState(state);
}

class DriftComboRepository implements ComboRepository {
  final CombosDao _dao;
  DriftComboRepository(this._dao);

  @override
  Stream<List<Combo>> watchAll() => _dao.watchAll();

  @override
  Stream<List<(Combo, int)>> watchAllWithMoveCounts() =>
      _dao.watchAllWithMoveCounts();

  @override
  Future<List<Combo>> getAll() => _dao.getAll();

  @override
  Future<Combo> getById(String id) => _dao.getById(id);

  @override
  Stream<Combo> watchById(String id) => _dao.watchById(id);

  @override
  Stream<List<ComboMoveWithDetail>> watchComboMoves(String comboId) =>
      _dao.watchComboMoves(comboId);

  @override
  Future<void> insert(CombosCompanion combo) => _dao.insertCombo(combo);

  @override
  Future<void> addMove(ComboMovesCompanion entry) => _dao.addMoveToCombo(entry);

  @override
  Future<void> delete(String id) => _dao.deleteCombo(id);

  @override
  Future<void> removeMove(String id) => _dao.removeComboMove(id);
}

class DriftReviewRepository implements ReviewRepository {
  final ReviewsDao _dao;
  DriftReviewRepository(this._dao);

  @override
  Stream<List<Review>> watchAll() => _dao.watchAll();

  @override
  Future<void> insert(ReviewsCompanion review) => _dao.insertReview(review);

  @override
  Future<List<Review>> getByMoveId(String moveId) => _dao.getByMoveId(moveId);

  @override
  Future<int> countAll() => _dao.countAll();

  @override
  Future<List<Review>> getInRange(DateTime start, DateTime end) =>
      _dao.getInRange(start, end);

  @override
  Future<Map<DateTime, int>> dailyCountsSince(DateTime since) =>
      _dao.dailyCountsSince(since);

  @override
  Future<Map<String, int>> ratingDistribution() => _dao.ratingDistribution();

  @override
  Future<List<MapEntry<String, int>>> topReviewedMoves(int limit) =>
      _dao.topReviewedMoves(limit);

  @override
  Future<int> currentStreak() => _dao.currentStreak();
}
