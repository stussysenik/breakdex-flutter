import 'package:drift/drift.dart';
import 'package:breakdex/core/database/tables/labs.dart';
import 'package:breakdex/core/database/tables/moves.dart';

class LabMoves extends Table {
  TextColumn get labId =>
      text().references(Labs, #id, onDelete: KeyAction.cascade)();
  TextColumn get moveId =>
      text().references(Moves, #id, onDelete: KeyAction.cascade)();
  IntColumn get sequenceIndex => integer()();
  DateTimeColumn get addedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {labId, moveId};
}
