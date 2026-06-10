import 'package:drift/drift.dart';

import 'combos.dart';

/// Practice plans: intentions, not history. Deletable and reorderable;
/// never written into the journal ledger.
class ComboPlans extends Table {
  TextColumn get id => text()();
  TextColumn get comboId =>
      text().references(Combos, #id, onDelete: KeyAction.cascade)();

  /// The day it's planned for (date-only semantics).
  DateTimeColumn get planDate => dateTime()();

  /// The dancer's sequence within a day/queue.
  IntColumn get position => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Stamped by evidence (a jot on planDate), never required.
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
