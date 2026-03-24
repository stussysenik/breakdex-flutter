import 'package:drift/drift.dart';
import 'labs.dart';

class Milestones extends Table {
  TextColumn get id => text()();
  TextColumn get labId =>
      text().references(Labs, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
