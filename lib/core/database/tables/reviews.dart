import 'package:drift/drift.dart';
import 'moves.dart';

class Reviews extends Table {
  TextColumn get id => text()();
  TextColumn get rating => text()();
  TextColumn get reviewType => text()();
  DateTimeColumn get reviewedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get moveId =>
      text().nullable().references(Moves, #id, onDelete: KeyAction.setNull)();

  @override
  Set<Column> get primaryKey => {id};
}
