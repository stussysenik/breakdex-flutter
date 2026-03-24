import 'package:drift/drift.dart';

class AuraPresets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1)();

  /// 1 = active aura preset, 0 = inactive
  IntColumn get isDefault => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
