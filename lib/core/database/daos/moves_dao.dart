import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database.dart';
import '../tables/moves.dart';

part 'moves_dao.g.dart';

@DriftAccessor(tables: [Moves])
class MovesDao extends DatabaseAccessor<AppDatabase> with _$MovesDaoMixin {
  MovesDao(super.db);

  Expression<bool> _isActive(final $MovesTable t) => t.archivedAt.isNull();
  Expression<bool> _isArchived(final $MovesTable t) => t.archivedAt.isNotNull();

  String _normalizeName(final String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Stream<List<Move>> watchAll() {
    debugPrint('[MovesDao] watchAll() subscribed');
    return (select(moves)
          ..where(_isActive)
          ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<Move> watchById(final String id) =>
      (select(moves)..where((final t) => t.id.equals(id))).watchSingle();

  Future<List<Move>> getAll() =>
      (select(moves)
            ..where(_isActive)
            ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<Move>> getActiveByContentHash(final String contentHash) =>
      (select(moves)
            ..where((final t) => _isActive(t) & t.contentHash.equals(contentHash))
            ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<Move>> getAllIncludingArchived() =>
      (select(moves)..orderBy([(final t) => OrderingTerm.desc(t.createdAt)])).get();

  /// Lightweight row count — returns a single integer without loading any
  /// Move objects into memory. Used as a DB smoke test during app launch.
  Future<int> count() => (selectOnly(
    moves,
  )..addColumns([countAll()])).map((final r) => r.read(countAll())!).getSingle();

  Future<Move> getById(final String id) =>
      (select(moves)..where((final t) => t.id.equals(id))).getSingle();

  Future<bool> nameExists(final String name, {final String? excludingId}) async {
    final normalized = _normalizeName(name);
    if (normalized.isEmpty) return false;

    final rows = await select(moves).get();
    return rows.any(
      (final move) =>
          move.id != excludingId && _normalizeName(move.name) == normalized,
    );
  }

  Future<void> insertMove(final MovesCompanion entry) =>
      into(moves).insert(_stampUpdatedAt(entry));

  Future<void> updateMove(final MovesCompanion entry) =>
      (update(moves)..where((final t) => t.id.equals(entry.id.value)))
          .write(_stampUpdatedAt(entry));

  /// Stamp [updatedAt] with the local mutation time for last-writer-wins sync,
  /// unless the caller already set it explicitly — the reconcile path passes a
  /// remote timestamp that must be preserved, not clobbered with `now()`.
  MovesCompanion _stampUpdatedAt(final MovesCompanion entry) =>
      entry.updatedAt.present
      ? entry
      : entry.copyWith(updatedAt: Value(DateTime.now().toUtc()));

  Future<void> deleteMove(final String id) {
    debugPrint('[MovesDao] deleteMove id=$id');
    return (delete(moves)..where((final t) => t.id.equals(id))).go();
  }

  Future<void> archiveMove(final String id, {required final String reason}) {
    debugPrint('[MovesDao] archiveMove id=$id reason=$reason');
    return (update(moves)..where((final t) => t.id.equals(id))).write(
      MovesCompanion(
        id: Value(id),
        archivedAt: Value(DateTime.now().toUtc()),
        archiveReason: Value(reason),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> restoreMove(final String id) {
    debugPrint('[MovesDao] restoreMove id=$id');
    return (update(moves)..where((final t) => t.id.equals(id))).write(
      MovesCompanion(
        id: Value(id),
        archivedAt: const Value(null),
        archiveReason: const Value(null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Stream<List<Move>> watchByCategory(final String category) =>
      (select(moves)
            ..where((final t) => t.category.equals(category) & _isActive(t))
            ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<Move>> watchByState(final String state) =>
      (select(moves)
            ..where((final t) => t.learningState.equals(state) & _isActive(t))
            ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<Move>> watchArchived() =>
      (select(moves)
            ..where(_isArchived)
            ..orderBy([(final t) => OrderingTerm.desc(t.archivedAt)]))
          .watch();

  Future<List<Move>> getArchived() =>
      (select(moves)
            ..where(_isArchived)
            ..orderBy([(final t) => OrderingTerm.desc(t.archivedAt)]))
          .get();

  Future<List<Move>> getTrackedManagedAlbumMoves() => (select(
    moves,
  )..where((final t) => _isActive(t) & t.managedAlbumAssetId.isNotNull())).get();

  Stream<List<Move>> watchTrackedManagedAlbumMoves() =>
      (select(moves)
            ..where((final t) => _isActive(t) & t.managedAlbumAssetId.isNotNull())
            ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<Move>> getExpiredArchived(final DateTime cutoff) =>
      (select(moves)..where(
            (final t) => _isArchived(t) & t.archivedAt.isSmallerThanValue(cutoff),
          ))
          .get();

  /// Batch-update all moves with [oldCategory] to [newCategory].
  /// Used by category rename to keep moves in sync with SharedPreferences.
  Future<int> updateCategory(final String oldCategory, final String newCategory) =>
      (update(moves)..where((final t) => t.category.equals(oldCategory))).write(
        MovesCompanion(category: Value(newCategory)),
      );
}
