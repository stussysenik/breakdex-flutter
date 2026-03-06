import '../database/database.dart';
import '../database/daos/combos_dao.dart';

/// Abstract interface for move data access.
/// Implementations can wrap Drift, REST APIs, SpacetimeDB, etc.
abstract class MoveRepository {
  Stream<List<Move>> watchAll();
  Stream<List<Move>> watchByCategory(String category);
  Stream<Move> watchById(String id);
  Future<List<Move>> getAll();
  Future<Move> getById(String id);
  Future<void> insert(MovesCompanion move);
  Future<void> update(MovesCompanion move);
  Future<void> delete(String id);
  Stream<List<Move>> watchByState(String state);
}

/// Abstract interface for combo data access.
abstract class ComboRepository {
  Stream<List<Combo>> watchAll();
  Stream<List<(Combo, int)>> watchAllWithMoveCounts();
  Future<List<Combo>> getAll();
  Future<Combo> getById(String id);
  Stream<Combo> watchById(String id);
  Stream<List<ComboMoveWithDetail>> watchComboMoves(String comboId);
  Future<void> insert(CombosCompanion combo);
  Future<void> addMove(ComboMovesCompanion entry);
  Future<void> delete(String id);
  Future<void> removeMove(String id);
}

/// Abstract interface for review data access.
abstract class ReviewRepository {
  Stream<List<Review>> watchAll();
  Future<void> insert(ReviewsCompanion review);
  Future<List<Review>> getByMoveId(String moveId);
  Future<int> countAll();
  Future<List<Review>> getInRange(DateTime start, DateTime end);
  Future<Map<DateTime, int>> dailyCountsSince(DateTime since);
  Future<Map<String, int>> ratingDistribution();
  Future<List<MapEntry<String, int>>> topReviewedMoves(int limit);
  Future<int> currentStreak();
}
