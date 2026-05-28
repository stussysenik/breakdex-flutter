import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/combos.dart';
import '../tables/combo_moves.dart';
import '../tables/moves.dart';

part 'combos_dao.g.dart';

class ComboWithMoves {
  final Combo combo;
  final List<ComboMoveWithDetail> moves;

  ComboWithMoves({required this.combo, required this.moves});
}

class ComboMoveWithDetail {
  final ComboMove comboMove;
  final Move move;

  ComboMoveWithDetail({required this.comboMove, required this.move});
}

@DriftAccessor(tables: [Combos, ComboMoves, Moves])
class CombosDao extends DatabaseAccessor<AppDatabase> with _$CombosDaoMixin {
  CombosDao(super.db);

  String _normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Stream<List<Combo>> watchAll() => select(combos).watch();

  Future<List<Combo>> getAll() => select(combos).get();

  Future<Combo> getById(String id) =>
      (select(combos)..where((t) => t.id.equals(id))).getSingle();

  Future<bool> nameExists(String name, {String? excludingId}) async {
    final normalized = _normalizeName(name);
    if (normalized.isEmpty) return false;

    final rows = await select(combos).get();
    return rows.any(
      (combo) =>
          combo.id != excludingId && _normalizeName(combo.name) == normalized,
    );
  }

  Stream<Combo> watchById(String id) =>
      (select(combos)..where((t) => t.id.equals(id))).watchSingle();

  Stream<List<ComboMoveWithDetail>> watchComboMoves(String comboId) {
    final query = select(comboMoves).join([
      innerJoin(moves, moves.id.equalsExp(comboMoves.moveId)),
    ])
      ..where(comboMoves.comboId.equals(comboId))
      ..orderBy([OrderingTerm.asc(comboMoves.sequenceIndex)]);

    return query.watch().map((rows) => rows
        .map((row) => ComboMoveWithDetail(
              comboMove: row.readTable(comboMoves),
              move: row.readTable(moves),
            ))
        .toList());
  }

  Future<void> insertCombo(CombosCompanion entry) =>
      into(combos).insert(entry);

  Future<void> addMoveToCombo(ComboMovesCompanion entry) =>
      into(comboMoves).insert(entry);

  Future<void> updateCombo(CombosCompanion entry) =>
      (update(combos)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  Future<void> deleteCombo(String id) =>
      (delete(combos)..where((t) => t.id.equals(id))).go();

  Future<void> removeComboMove(String id) =>
      (delete(comboMoves)..where((t) => t.id.equals(id))).go();

  /// Watches all combos paired with their move count via a LEFT JOIN on
  /// combo_moves grouped by comboId. Returns (Combo, int) tuples so the
  /// UI can render move-count dots without extra queries.
  Stream<List<(Combo, int)>> watchAllWithMoveCounts() {
    final countExpr = comboMoves.id.count();
    final query = select(combos).join([
      leftOuterJoin(comboMoves, comboMoves.comboId.equalsExp(combos.id)),
    ])
      ..addColumns([countExpr])
      ..groupBy([combos.id]);

    return query.watch().map((rows) {
      final list = rows
          .map((row) => (
                row.readTable(combos),
                row.read(countExpr) ?? 0,
              ))
          .toList();
      
      list.sort((a, b) {
        // Size up (ascending by count)
        final sizeCmp = a.$2.compareTo(b.$2);
        if (sizeCmp != 0) return sizeCmp;
        // Fallback to name
        return a.$1.name.compareTo(b.$1.name);
      });
      
      return list;
    });
  }
}
