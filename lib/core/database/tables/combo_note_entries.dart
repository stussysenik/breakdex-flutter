import 'package:drift/drift.dart';

import 'combos.dart';

class ComboNoteEntries extends Table {
  TextColumn get id => text()();
  TextColumn get comboId =>
      text().references(Combos, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
