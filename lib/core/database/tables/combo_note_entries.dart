import 'package:drift/drift.dart';

import 'combos.dart';

class ComboNoteEntries extends Table {
  TextColumn get id => text()();
  TextColumn get comboId =>
      text().references(Combos, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text()();

  /// 'jot', 'status', 'plan', or 'duplicate'.
  TextColumn get kind => text().withDefault(const Constant('jot'))();

  /// Relative reference into Documents/Moves/… — never a per-combo copy.
  TextColumn get videoPath => text().nullable()();

  /// Content hash into the content-addressable master, when known.
  TextColumn get videoHash => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
