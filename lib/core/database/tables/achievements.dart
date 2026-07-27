import 'package:drift/drift.dart';
import 'package:breakdex/core/database/tables/moves.dart';

class Achievements extends Table {
  TextColumn get id => text()();
  TextColumn get moveId =>
      text().references(Moves, #id, onDelete: KeyAction.cascade)();

  /// 'seed', 'sprouting', 'growing', or 'mastered'
  TextColumn get tier => text().withLength(min: 1)();

  DateTimeColumn get unlockedAt => dateTime()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
