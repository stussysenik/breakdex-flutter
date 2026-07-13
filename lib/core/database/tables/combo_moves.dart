import 'package:drift/drift.dart';
import 'combos.dart';
import 'moves.dart';

class ComboMoves extends Table {
  TextColumn get id => text()();
  IntColumn get sequenceIndex => integer()();
  TextColumn get comboId =>
      text().references(Combos, #id, onDelete: KeyAction.cascade)();
  TextColumn get moveId =>
      text().references(Moves, #id, onDelete: KeyAction.cascade)();
  IntColumn get count => integer().withDefault(const Constant(1))();

  /// Last-writer-wins clock for backend sync (task 4.4). Nullable so the
  /// additive v24 migration can backfill it (this table has no `createdAt`, so
  /// existing rows are seeded from the parent combo's `createdAt`); the DAO
  /// stamps it on every insert/update, so new rows always carry a real clock.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Reversible soft-hide for an inbound tombstone on a secondary device (task
  /// 4.8) — e.g. a step removed on another device. Pull-side only; read paths
  /// filter `deletedAt IS NULL`.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
