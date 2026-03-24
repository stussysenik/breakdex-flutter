import 'package:drift/drift.dart';
import 'labs.dart';

class LabEntries extends Table {
  TextColumn get id => text()();
  TextColumn get labId =>
      text().nullable().references(Labs, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text().withLength(min: 1)();
  TextColumn get videoPath => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
