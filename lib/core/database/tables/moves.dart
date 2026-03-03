import 'package:drift/drift.dart';

class Moves extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get learningState => text().withDefault(const Constant('NEW'))();
  TextColumn get category => text().withDefault(const Constant('default'))();
  TextColumn get videoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
