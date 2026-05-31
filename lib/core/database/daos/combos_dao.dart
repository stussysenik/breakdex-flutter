import 'package:flutter/foundation.dart';
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

  /// Performance: each cell using [watchComboMoves] creates a per-combo stream
  /// subscription. With N combos in the grid this scales as O(N). Grid cells
  /// should share a single-widget subscription (see _ComboGridCell) and prefer
  /// combo.resolvedActiveVideoPath for thumbnail resolution where possible.
  Stream<List<ComboMoveWithDetail>> watchComboMoves(String comboId) {
    final query = select(comboMoves).join([
      innerJoin(moves, moves.id.equalsExp(comboMoves.moveId)),
    ])
      ..where(comboMoves.comboId.equals(comboId))
      ..orderBy([OrderingTerm.asc(comboMoves.sequenceIndex)]);

    return query.watch().map((rows) => rows
        .map((row) {
          final cm = row.readTable(comboMoves);
          final m = row.readTable(moves);
          return ComboMoveWithDetail(
            comboMove: cm,
            move: m.copyWith(count: cm.count),
          );
        })
        .toList());
  }

  Future<void> insertCombo(CombosCompanion entry) =>
      into(combos).insert(entry);

  Future<void> addMoveToCombo(ComboMovesCompanion entry) =>
      into(comboMoves).insert(entry);

  Future<void> updateCombo(CombosCompanion entry) =>
      (update(combos)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  Future<void> deleteCombo(String id) {
    debugPrint('[CombosDao] deleteCombo id=$id');
    return (delete(combos)..where((t) => t.id.equals(id))).go();
  }

  Future<void> removeComboMove(String id) =>
      (delete(comboMoves)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllMovesForCombo(String comboId) =>
      (delete(comboMoves)..where((t) => t.comboId.equals(comboId))).go();

  /// Loads all combo→moves relationships in a single join query.
  /// Returns a map keyed by comboId→list of [ComboMoveWithDetail].
  /// Avoids the N+1 query problem of calling [watchComboMoves] per combo.
  Future<Map<String, List<ComboMoveWithDetail>>> getAllComboMovesMap() async {
    final query = select(comboMoves).join([
      innerJoin(moves, moves.id.equalsExp(comboMoves.moveId)),
    ])
      ..orderBy([OrderingTerm.asc(comboMoves.sequenceIndex)]);

    final rows = await query.get();
    final map = <String, List<ComboMoveWithDetail>>{};
    for (final row in rows) {
      final cm = row.readTable(comboMoves);
      final m = row.readTable(moves);
      map.putIfAbsent(cm.comboId, () => []).add(
            ComboMoveWithDetail(comboMove: cm, move: m.copyWith(count: cm.count)),
          );
    }
    return map;
  }

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
        final sizeCmp = a.$2.compareTo(b.$2);
        if (sizeCmp != 0) return sizeCmp;
        return a.$1.name.compareTo(b.$1.name);
      });
      
      return list;
    });
  }

  /// Returns a deduplicated list of combos that reference the given [moveId].
  Future<List<Combo>> getCombosUsingMove(String moveId) async {
    final query = select(combos).join([
      innerJoin(comboMoves, comboMoves.comboId.equalsExp(combos.id)),
    ])..where(comboMoves.moveId.equals(moveId));

    final rows = await query.get();
    return rows.map((row) => row.readTable(combos)).toSet().toList();
  }
}
