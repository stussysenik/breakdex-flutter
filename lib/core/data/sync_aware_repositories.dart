import 'package:flutter/foundation.dart';

import '../database/database.dart';
import '../database/daos/combos_dao.dart';
import '../database/daos/sync_dao.dart';
import '../services/provenance_service.dart';
import 'repositories.dart';

/// Decorator that wraps a [MoveRepository] and logs mutations to [SyncDao].
class SyncAwareMoveRepository implements MoveRepository {
  final MoveRepository _inner;
  final SyncDao _syncDao;
  final ProvenanceService? _provenance;

  SyncAwareMoveRepository(this._inner, this._syncDao, {final ProvenanceService? provenance})
      : _provenance = provenance;

  // Reads — zero overhead, delegate directly
  @override
  Stream<List<Move>> watchAll() => _inner.watchAll();
  @override
  Stream<List<Move>> watchArchived() => _inner.watchArchived();
  @override
  Stream<List<Move>> watchByCategory(final String category) =>
      _inner.watchByCategory(category);
  @override
  Stream<Move> watchById(final String id) => _inner.watchById(id);
  @override
  Future<List<Move>> getAll() => _inner.getAll();
  @override
  Future<List<Move>> getArchived() => _inner.getArchived();
  @override
  Future<Move> getById(final String id) => _inner.getById(id);
  @override
  Stream<List<Move>> watchByState(final String state) => _inner.watchByState(state);

  // Writes — delegate + log
  @override
  Future<void> insert(final MovesCompanion move) async {
    await _inner.insert(move);
    final hasVideo = move.videoPath.present && move.videoPath.value != null;
    await _syncDao.logChange(
      entityId: move.id.value,
      table: 'moves',
      action: 'create',
      hasVideo: hasVideo,
    );
    await _provenance?.logCreated('move', move.id.value,
        metadata: {'name': move.name.value});
  }

  @override
  Future<void> update(final MovesCompanion move) async {
    await _inner.update(move);
    final hasVideo = move.videoPath.present && move.videoPath.value != null;
    await _syncDao.logChange(
      entityId: move.id.value,
      table: 'moves',
      action: 'update',
      hasVideo: hasVideo,
    );
    await _provenance?.logEdited('move', move.id.value, {
      if (move.name.present) 'name': move.name.value,
      if (move.category.present) 'category': move.category.value,
    });
  }

  @override
  Future<void> delete(final String id) async {
    await _inner.delete(id);
    await _syncDao.logChange(entityId: id, table: 'moves', action: 'delete');
    await _provenance?.logEdited('move', id, {'archived': true});
  }

  @override
  Future<void> archive(final String id, {required final String reason}) async {
    debugPrint('[SyncAwareMoveRepo] archive id=$id reason=$reason');
    await _inner.archive(id, reason: reason);
    await _syncDao.logChange(entityId: id, table: 'moves', action: 'update');
    await _provenance?.logEdited('move', id, {'archived': true, 'reason': reason});
    debugPrint('[SyncAwareMoveRepo] archive DONE id=$id');
  }

  @override
  Future<void> restore(final String id) async {
    debugPrint('[SyncAwareMoveRepo] restore id=$id');
    await _inner.restore(id);
    await _syncDao.logChange(entityId: id, table: 'moves', action: 'update');
    await _provenance?.logEdited('move', id, {'restored': true});
    debugPrint('[SyncAwareMoveRepo] restore DONE id=$id');
  }
}

/// Decorator that wraps a [ComboRepository] and logs mutations to [SyncDao].
class SyncAwareComboRepository implements ComboRepository {
  final ComboRepository _inner;
  final SyncDao _syncDao;
  final ProvenanceService? _provenance;

  SyncAwareComboRepository(this._inner, this._syncDao, {final ProvenanceService? provenance})
      : _provenance = provenance;

  // Reads
  @override
  Stream<List<Combo>> watchAll() => _inner.watchAll();
  @override
  Stream<List<(Combo, int)>> watchAllWithMoveCounts() =>
      _inner.watchAllWithMoveCounts();
  @override
  Future<List<Combo>> getAll() => _inner.getAll();
  @override
  Future<Combo> getById(final String id) => _inner.getById(id);
  @override
  Stream<Combo> watchById(final String id) => _inner.watchById(id);
  @override
  Stream<List<ComboMoveWithDetail>> watchComboMoves(final String comboId) =>
      _inner.watchComboMoves(comboId);

  // Writes
  @override
  Future<void> insert(final CombosCompanion combo) async {
    await _inner.insert(combo);
    final hasVideo =
        combo.activeVideoPath.present && combo.activeVideoPath.value != null;
    await _syncDao.logChange(
      entityId: combo.id.value,
      table: 'combos',
      action: 'create',
      hasVideo: hasVideo,
    );
    await _provenance?.logCreated('combo', combo.id.value,
        metadata: {'name': combo.name.value});
  }

  @override
  Future<void> update(final CombosCompanion combo) async {
    await _inner.update(combo);
    final hasVideo =
        combo.activeVideoPath.present && combo.activeVideoPath.value != null;
    await _syncDao.logChange(
      entityId: combo.id.value,
      table: 'combos',
      action: 'update',
      hasVideo: hasVideo,
    );
    await _provenance?.logEdited('combo', combo.id.value, {
      if (combo.name.present) 'name': combo.name.value,
    });
  }

  @override
  Future<void> addMove(final ComboMovesCompanion entry) async {
    await _inner.addMove(entry);
    await _syncDao.logChange(
      entityId: entry.id.value,
      table: 'combo_moves',
      action: 'create',
    );
  }

  @override
  Future<void> delete(final String id) async {
    debugPrint('[SyncAwareComboRepo] delete id=$id');
    await _inner.delete(id);
    debugPrint('[SyncAwareComboRepo] delete inner done id=$id');
    await _syncDao.logChange(entityId: id, table: 'combos', action: 'delete');
    debugPrint('[SyncAwareComboRepo] delete sync logged id=$id');
  }

  @override
  Future<void> removeMove(final String id) async {
    await _inner.removeMove(id);
    await _syncDao.logChange(
      entityId: id,
      table: 'combo_moves',
      action: 'delete',
    );
  }

  @override
  Future<void> clearMoves(final String comboId) => _inner.clearMoves(comboId);
}

/// Decorator that wraps a [ReviewRepository] and logs mutations to [SyncDao].
class SyncAwareReviewRepository implements ReviewRepository {
  final ReviewRepository _inner;
  final SyncDao _syncDao;
  final ProvenanceService? _provenance;

  SyncAwareReviewRepository(this._inner, this._syncDao, {final ProvenanceService? provenance})
      : _provenance = provenance;

  // Reads
  @override
  Stream<List<Review>> watchAll() => _inner.watchAll();
  @override
  Future<List<Review>> getByMoveId(final String moveId) => _inner.getByMoveId(moveId);
  @override
  Future<int> countAll() => _inner.countAll();
  @override
  Future<List<Review>> getInRange(final DateTime start, final DateTime end) =>
      _inner.getInRange(start, end);
  @override
  Future<Map<DateTime, int>> dailyCountsSince(final DateTime since) =>
      _inner.dailyCountsSince(since);
  @override
  Future<Map<String, int>> ratingDistribution() => _inner.ratingDistribution();
  @override
  Future<List<MapEntry<String, int>>> topReviewedMoves(final int limit) =>
      _inner.topReviewedMoves(limit);
  @override
  Future<int> currentStreak() => _inner.currentStreak();

  // Writes
  @override
  Future<void> insert(final ReviewsCompanion review) async {
    await _inner.insert(review);
    await _syncDao.logChange(
      entityId: review.id.value,
      table: 'reviews',
      action: 'create',
    );

    if (_provenance == null) return;
    if (review.comboId.present && review.comboId.value != null) {
      await _provenance.logReviewed(
          'combo', review.comboId.value!, review.rating.value);
    } else if (review.moveId.present && review.moveId.value != null) {
      await _provenance.logReviewed(
          'move', review.moveId.value!, review.rating.value);
    }
  }
}

/// Decorator that wraps a [SetRepository] and logs mutations to [SyncDao].
class SyncAwareSetRepository implements SetRepository {
  final SetRepository _inner;
  final SyncDao _syncDao;
  final ProvenanceService? _provenance;

  SyncAwareSetRepository(this._inner, this._syncDao, {final ProvenanceService? provenance})
      : _provenance = provenance;

  // Reads
  @override
  Stream<List<BreakdexSet>> watchAll() => _inner.watchAll();
  @override
  Stream<BreakdexSet> watchById(final String id) => _inner.watchById(id);
  @override
  Future<List<BreakdexSet>> getAll() => _inner.getAll();
  @override
  Future<BreakdexSet> getById(final String id) => _inner.getById(id);
  @override
  Stream<List<SetItem>> watchItems(final String setId) => _inner.watchItems(setId);
  @override
  Future<bool> validateNoCycle(final String setId, final String childSetId) =>
      _inner.validateNoCycle(setId, childSetId);
  @override
  Future<int> depth(final String setId) => _inner.depth(setId);

  // Writes
  @override
  Future<void> insert(final SetsCompanion set) async {
    await _inner.insert(set);
    await _syncDao.logChange(
      entityId: set.id.value,
      table: 'sets',
      action: 'create',
    );
    await _provenance?.logCreated('set', set.id.value,
        metadata: {'name': set.name.value});
  }

  @override
  Future<void> update(final SetsCompanion set) async {
    await _inner.update(set);
    await _syncDao.logChange(
      entityId: set.id.value,
      table: 'sets',
      action: 'update',
    );
    await _provenance?.logEdited('set', set.id.value, {
      if (set.name.present) 'name': set.name.value,
    });
  }

  @override
  Future<void> delete(final String id) async {
    await _inner.delete(id);
    await _syncDao.logChange(entityId: id, table: 'sets', action: 'delete');
  }

  @override
  Future<void> addItem(final SetItemsCompanion item) async {
    await _inner.addItem(item);
    await _syncDao.logChange(
      entityId: item.id.value,
      table: 'set_items',
      action: 'create',
    );
  }

  @override
  Future<void> removeItem(final String id) async {
    await _inner.removeItem(id);
    await _syncDao.logChange(
      entityId: id,
      table: 'set_items',
      action: 'delete',
    );
  }

  @override
  Future<void> reorderItem(final String itemId, final int newPosition) async {
    await _inner.reorderItem(itemId, newPosition);
    await _syncDao.logChange(
      entityId: itemId,
      table: 'set_items',
      action: 'update',
    );
  }
}
