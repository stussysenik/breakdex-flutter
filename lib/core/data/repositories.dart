import '../database/database.dart';
import '../database/daos/combos_dao.dart';

/// Abstract interface for move data access.
/// Implementations can wrap Drift, REST APIs, SpacetimeDB, etc.
abstract class MoveRepository {
  Stream<List<Move>> watchAll();
  Stream<List<Move>> watchArchived();
  Stream<List<Move>> watchByCategory(String category);
  Stream<Move> watchById(String id);
  Future<List<Move>> getAll();
  Future<List<Move>> getArchived();
  Future<Move> getById(String id);
  Future<void> insert(MovesCompanion move);
  Future<void> update(MovesCompanion move);
  Future<void> delete(String id);
  Future<void> archive(String id, {required String reason});
  Future<void> restore(String id);
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
  Future<void> update(CombosCompanion combo);
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

/// Abstract interface for set data access.
abstract class SetRepository {
  Stream<List<BreakdexSet>> watchAll();
  Stream<BreakdexSet> watchById(String id);
  Future<List<BreakdexSet>> getAll();
  Future<BreakdexSet> getById(String id);
  Future<void> insert(SetsCompanion set);
  Future<void> update(SetsCompanion set);
  Future<void> delete(String id);

  Future<void> addItem(SetItemsCompanion item);
  Future<void> removeItem(String id);
  Future<void> reorderItem(String itemId, int newPosition);
  Stream<List<SetItem>> watchItems(String setId);
  Future<bool> validateNoCycle(String setId, String childSetId);
  Future<int> depth(String setId);
}
