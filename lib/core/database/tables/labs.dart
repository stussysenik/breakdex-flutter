import 'package:drift/drift.dart';

class Labs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1)();

  /// 'project' or 'set'
  TextColumn get labType => text().withDefault(const Constant('project'))();

  /// 'idea', 'attempting', 'landed', or 'clean'
  TextColumn get status => text().withDefault(const Constant('idea'))();

  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
