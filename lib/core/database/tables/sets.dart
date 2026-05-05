import 'package:drift/drift.dart';

@DataClassName('BreakdexSet')
class Sets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get description => text().nullable()();
  IntColumn get learningState => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
