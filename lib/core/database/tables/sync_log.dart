import 'package:drift/drift.dart';

class SyncLog extends Table {
  TextColumn get entityId => text()();
  TextColumn get entityTable => text()();
  TextColumn get action => text()(); // create, update, delete
  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  BoolColumn get videoSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {entityId, entityTable, action};
}
