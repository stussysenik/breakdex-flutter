import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/moves.dart';

part 'moves_dao.g.dart';

@DriftAccessor(tables: [Moves])
class MovesDao extends DatabaseAccessor<AppDatabase> with _$MovesDaoMixin {
  MovesDao(super.db);

  Expression<bool> _isActive($MovesTable t) => t.archivedAt.isNull();
  Expression<bool> _isArchived($MovesTable t) => t.archivedAt.isNotNull();

  String _normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Stream<List<Move>> watchAll() =>
      (select(moves)
            ..where(_isActive)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<Move> watchById(String id) =>
      (select(moves)..where((t) => t.id.equals(id))).watchSingle();

  Future<List<Move>> getAll() =>
      (select(moves)
            ..where(_isActive)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<Move>> getActiveByContentHash(String contentHash) =>
      (select(moves)
            ..where((t) => _isActive(t) & t.contentHash.equals(contentHash))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<Move>> getAllIncludingArchived() =>
      (select(moves)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  /// Lightweight row count — returns a single integer without loading any
  /// Move objects into memory. Used as a DB smoke test during app launch.
  Future<int> count() => (selectOnly(
    moves,
  )..addColumns([countAll()])).map((r) => r.read(countAll())!).getSingle();

  Future<Move> getById(String id) =>
      (select(moves)..where((t) => t.id.equals(id))).getSingle();

  Future<bool> nameExists(String name, {String? excludingId}) async {
    final normalized = _normalizeName(name);
    if (normalized.isEmpty) return false;

    final rows = await select(moves).get();
    return rows.any(
      (move) =>
          move.id != excludingId && _normalizeName(move.name) == normalized,
    );
  }

  Future<void> insertMove(MovesCompanion entry) => into(moves).insert(entry);

  Future<void> updateMove(MovesCompanion entry) =>
      (update(moves)..where((t) => t.id.equals(entry.id.value))).write(entry);

  Future<void> deleteMove(String id) =>
      (delete(moves)..where((t) => t.id.equals(id))).go();

  Future<void> archiveMove(String id, {required String reason}) =>
      (update(moves)..where((t) => t.id.equals(id))).write(
        MovesCompanion(
          id: Value(id),
          archivedAt: Value(DateTime.now().toUtc()),
          archiveReason: Value(reason),
        ),
      );

  Future<void> restoreMove(String id) =>
      (update(moves)..where((t) => t.id.equals(id))).write(
        MovesCompanion(
          id: Value(id),
          archivedAt: const Value(null),
          archiveReason: const Value(null),
        ),
      );

  Stream<List<Move>> watchByCategory(String category) =>
      (select(moves)
            ..where((t) => t.category.equals(category) & _isActive(t))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<Move>> watchByState(String state) =>
      (select(moves)
            ..where((t) => t.learningState.equals(state) & _isActive(t))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<Move>> watchArchived() =>
      (select(moves)
            ..where(_isArchived)
            ..orderBy([(t) => OrderingTerm.desc(t.archivedAt)]))
          .watch();

  Future<List<Move>> getArchived() =>
      (select(moves)
            ..where(_isArchived)
            ..orderBy([(t) => OrderingTerm.desc(t.archivedAt)]))
          .get();

  Future<List<Move>> getTrackedManagedAlbumMoves() => (select(
    moves,
  )..where((t) => _isActive(t) & t.managedAlbumAssetId.isNotNull())).get();

  Stream<List<Move>> watchTrackedManagedAlbumMoves() =>
      (select(moves)
            ..where((t) => _isActive(t) & t.managedAlbumAssetId.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<Move>> getExpiredArchived(DateTime cutoff) =>
      (select(moves)..where(
            (t) => _isArchived(t) & t.archivedAt.isSmallerThanValue(cutoff),
          ))
          .get();

  /// Batch-update all moves with [oldCategory] to [newCategory].
  /// Used by category rename to keep moves in sync with SharedPreferences.
  Future<int> updateCategory(String oldCategory, String newCategory) =>
      (update(moves)..where((t) => t.category.equals(oldCategory))).write(
        MovesCompanion(category: Value(newCategory)),
      );
}
