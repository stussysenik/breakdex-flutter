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

  Stream<List<Combo>> watchAll() => select(combos).watch();

  Future<List<Combo>> getAll() => select(combos).get();

  Future<Combo> getById(String id) =>
      (select(combos)..where((t) => t.id.equals(id))).getSingle();

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

  Future<void> deleteCombo(String id) =>
      (delete(combos)..where((t) => t.id.equals(id))).go();

  Future<void> removeComboMove(String id) =>
      (delete(comboMoves)..where((t) => t.id.equals(id))).go();
}
