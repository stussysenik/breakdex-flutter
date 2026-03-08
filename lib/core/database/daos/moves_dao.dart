import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/moves.dart';

part 'moves_dao.g.dart';

@DriftAccessor(tables: [Moves])
class MovesDao extends DatabaseAccessor<AppDatabase> with _$MovesDaoMixin {
  MovesDao(super.db);

  String _normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Stream<List<Move>> watchAll() =>
      (select(moves)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Stream<Move> watchById(String id) =>
      (select(moves)..where((t) => t.id.equals(id))).watchSingle();

  Future<List<Move>> getAll() =>
      (select(moves)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  /// Lightweight row count — returns a single integer without loading any
  /// Move objects into memory. Used as a DB smoke test during app launch.
  Future<int> count() =>
      (selectOnly(moves)..addColumns([countAll()]))
          .map((r) => r.read(countAll())!)
          .getSingle();

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
      (update(moves)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  Future<void> deleteMove(String id) =>
      (delete(moves)..where((t) => t.id.equals(id))).go();

  Stream<List<Move>> watchByCategory(String category) => (select(moves)
        ..where((t) => t.category.equals(category))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Stream<List<Move>> watchByState(String state) => (select(moves)
        ..where((t) => t.learningState.equals(state))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  /// Batch-update all moves with [oldCategory] to [newCategory].
  /// Used by category rename to keep moves in sync with SharedPreferences.
  Future<int> updateCategory(String oldCategory, String newCategory) =>
      (update(moves)..where((t) => t.category.equals(oldCategory)))
          .write(MovesCompanion(category: Value(newCategory)));
}
