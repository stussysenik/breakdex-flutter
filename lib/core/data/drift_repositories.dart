import 'package:flutter/foundation.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/moves_dao.dart';
import 'package:breakdex/core/database/daos/combos_dao.dart';
import 'package:breakdex/core/database/daos/reviews_dao.dart';
import 'package:breakdex/core/database/daos/sets_dao.dart';
import 'package:breakdex/core/data/repositories.dart';

class DriftMoveRepository implements MoveRepository {
  final MovesDao _dao;
  DriftMoveRepository(this._dao);

  @override
  Stream<List<Move>> watchAll() => _dao.watchAll();

  @override
  Stream<List<Move>> watchArchived() => _dao.watchArchived();

  @override
  Stream<List<Move>> watchByCategory(final String category) =>
      _dao.watchByCategory(category);

  @override
  Stream<Move> watchById(final String id) => _dao.watchById(id);

  @override
  Future<List<Move>> getAll() => _dao.getAll();

  @override
  Future<List<Move>> getArchived() => _dao.getArchived();

  @override
  Future<Move> getById(final String id) => _dao.getById(id);

  @override
  Future<void> insert(final MovesCompanion move) => _dao.insertMove(move);

  @override
  Future<void> update(final MovesCompanion move) => _dao.updateMove(move);

  @override
  Future<void> delete(final String id) => _dao.deleteMove(id);

  @override
  Future<void> archive(final String id, {required final String reason}) =>
      _dao.archiveMove(id, reason: reason);

  @override
  Future<void> restore(final String id) => _dao.restoreMove(id);

  @override
  Stream<List<Move>> watchByState(final String state) => _dao.watchByState(state);
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
  Future<Combo> getById(final String id) => _dao.getById(id);

  @override
  Stream<Combo> watchById(final String id) => _dao.watchById(id);

  @override
  Stream<List<ComboMoveWithDetail>> watchComboMoves(final String comboId) =>
      _dao.watchComboMoves(comboId);

  @override
  Future<void> insert(final CombosCompanion combo) => _dao.insertCombo(combo);

  @override
  Future<void> update(final CombosCompanion combo) => _dao.updateCombo(combo);

  @override
  Future<void> addMove(final ComboMovesCompanion entry) => _dao.addMoveToCombo(entry);

  @override
  Future<void> delete(final String id) {
    debugPrint('[DriftComboRepo] delete id=$id');
    return _dao.deleteCombo(id);
  }

  @override
  Future<void> removeMove(final String id) => _dao.removeComboMove(id);

  @override
  Future<void> clearMoves(final String comboId) => _dao.deleteAllMovesForCombo(comboId);
}

class DriftReviewRepository implements ReviewRepository {
  final ReviewsDao _dao;
  DriftReviewRepository(this._dao);

  @override
  Stream<List<Review>> watchAll() => _dao.watchAll();

  @override
  Future<void> insert(final ReviewsCompanion review) => _dao.insertReview(review);

  @override
  Future<List<Review>> getByMoveId(final String moveId) => _dao.getByMoveId(moveId);

  @override
  Future<int> countAll() => _dao.countAll();

  @override
  Future<List<Review>> getInRange(final DateTime start, final DateTime end) =>
      _dao.getInRange(start, end);

  @override
  Future<Map<DateTime, int>> dailyCountsSince(final DateTime since) =>
      _dao.dailyCountsSince(since);

  @override
  Future<Map<String, int>> ratingDistribution() => _dao.ratingDistribution();

  @override
  Future<List<MapEntry<String, int>>> topReviewedMoves(final int limit) =>
      _dao.topReviewedMoves(limit);

  @override
  Future<int> currentStreak() => _dao.currentStreak();
}

class DriftSetRepository implements SetRepository {
  final SetsDao _dao;
  DriftSetRepository(this._dao);

  @override
  Stream<List<BreakdexSet>> watchAll() => _dao.watchAll();

  @override
  Stream<BreakdexSet> watchById(final String id) => _dao.watchById(id);

  @override
  Future<List<BreakdexSet>> getAll() => _dao.getAll();

  @override
  Future<BreakdexSet> getById(final String id) => _dao.getById(id);

  @override
  Future<void> insert(final SetsCompanion set) => _dao.createSet(set);

  @override
  Future<void> update(final SetsCompanion set) => _dao.updateSet(set);

  @override
  Future<void> delete(final String id) => _dao.deleteSet(id);

  @override
  Future<void> addItem(final SetItemsCompanion item) => _dao.addSetItem(item);

  @override
  Future<void> removeItem(final String id) => _dao.removeSetItem(id);

  @override
  Future<void> reorderItem(final String itemId, final int newPosition) =>
      _dao.reorderSetItem(itemId, newPosition);

  @override
  Stream<List<SetItem>> watchItems(final String setId) => _dao.watchSetItems(setId);

  @override
  Future<bool> validateNoCycle(final String setId, final String childSetId) =>
      _dao.validateNoCycle(setId, childSetId);

  @override
  Future<int> depth(final String setId) => _dao.depth(setId);
}
