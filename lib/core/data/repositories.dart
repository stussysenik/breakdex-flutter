import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/combos_dao.dart';

/// Abstract interface for move data access.
/// Implementations can wrap Drift, REST APIs, SpacetimeDB, etc.
abstract class MoveRepository {
  Stream<List<Move>> watchAll();
  Stream<List<Move>> watchArchived();
  Stream<List<Move>> watchByCategory(final String category);
  Stream<Move> watchById(final String id);
  Future<List<Move>> getAll();
  Future<List<Move>> getArchived();
  Future<Move> getById(final String id);
  Future<void> insert(final MovesCompanion move);
  Future<void> update(final MovesCompanion move);
  Future<void> delete(final String id);
  Future<void> archive(final String id, {required final String reason});
  Future<void> restore(final String id);
  Stream<List<Move>> watchByState(final String state);
}

/// Abstract interface for combo data access.
abstract class ComboRepository {
  Stream<List<Combo>> watchAll();
  Stream<List<(Combo, int)>> watchAllWithMoveCounts();
  Future<List<Combo>> getAll();
  Future<Combo> getById(final String id);
  Stream<Combo> watchById(final String id);
  Stream<List<ComboMoveWithDetail>> watchComboMoves(final String comboId);
  Future<void> insert(final CombosCompanion combo);
  Future<void> update(final CombosCompanion combo);
  Future<void> addMove(final ComboMovesCompanion entry);
  Future<void> delete(final String id);
  Future<void> removeMove(final String id);
  Future<void> clearMoves(final String comboId);
}

/// Abstract interface for review data access.
abstract class ReviewRepository {
  Stream<List<Review>> watchAll();
  Future<void> insert(final ReviewsCompanion review);
  Future<List<Review>> getByMoveId(final String moveId);
  Future<int> countAll();
  Future<List<Review>> getInRange(final DateTime start, final DateTime end);
  Future<Map<DateTime, int>> dailyCountsSince(final DateTime since);
  Future<Map<String, int>> ratingDistribution();
  Future<List<MapEntry<String, int>>> topReviewedMoves(final int limit);
  Future<int> currentStreak();
}

/// Abstract interface for set data access.
abstract class SetRepository {
  Stream<List<BreakdexSet>> watchAll();
  Stream<BreakdexSet> watchById(final String id);
  Future<List<BreakdexSet>> getAll();
  Future<BreakdexSet> getById(final String id);
  Future<void> insert(final SetsCompanion set);
  Future<void> update(final SetsCompanion set);
  Future<void> delete(final String id);

  Future<void> addItem(final SetItemsCompanion item);
  Future<void> removeItem(final String id);
  Future<void> reorderItem(final String itemId, final int newPosition);
  Stream<List<SetItem>> watchItems(final String setId);
  Future<bool> validateNoCycle(final String setId, final String childSetId);
  Future<int> depth(final String setId);
}
