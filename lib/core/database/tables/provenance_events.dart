import 'package:drift/drift.dart';

class ProvenanceEvents extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // 'move', 'combo', 'set'
  TextColumn get entityId => text()();
  TextColumn get eventType => text()(); // 'reviewed', 'edited', 'tagged', 'milestone_reached', 'created'
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
