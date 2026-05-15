import 'package:drift/drift.dart';

import 'moves.dart';

class MoveNoteEntries extends Table {
  TextColumn get id => text()();
  TextColumn get moveId =>
      text().references(Moves, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
