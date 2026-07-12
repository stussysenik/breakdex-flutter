import 'package:drift/drift.dart';

class Combos extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get notes => text().nullable()();
  TextColumn get activeVideoPath => text().nullable()();
  TextColumn get contentHash => text().nullable()();

  /// 'idea', 'attempting', 'landed', or 'clean' — same vocabulary as labs.
  TextColumn get status => text().withDefault(const Constant('idea'))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Last-writer-wins clock for backend sync (task 4.4). Nullable so the
  /// additive v24 migration can backfill it from [createdAt]; the DAO stamps it
  /// on every local mutation, mirroring `moves.updatedAt`.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
