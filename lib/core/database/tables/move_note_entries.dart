import 'package:drift/drift.dart';

import 'moves.dart';

class MoveNoteEntries extends Table {
  TextColumn get id => text()();
  TextColumn get moveId =>
      text().references(Moves, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last-writer-wins clock for Appwrite sync (task 4.9). Nullable + backfilled
  /// from [createdAt] in the v27 migration; stamped on every write by the DAO.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Reversible soft-hide for an inbound sync tombstone (task 4.9). NULL = live;
  /// a remote delete stamps it instead of hard-deleting (never orphan state).
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
