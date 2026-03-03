import 'package:drift/drift.dart';
import 'combos.dart';
import 'moves.dart';

class ComboMoves extends Table {
  TextColumn get id => text()();
  IntColumn get sequenceIndex => integer()();
  TextColumn get comboId =>
      text().references(Combos, #id, onDelete: KeyAction.cascade)();
  TextColumn get moveId =>
      text().references(Moves, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {id};
}
