import 'package:drift/drift.dart';

import 'sets.dart';

class SetItems extends Table {
  TextColumn get id => text()();
  TextColumn get setId => text().references(Sets, #id)();
  TextColumn get itemType => text()(); // 'move', 'combo', 'set'
  TextColumn get itemId => text()();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
