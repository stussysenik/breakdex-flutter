import 'package:drift/drift.dart';
import 'combos.dart';
import 'moves.dart';

class Reviews extends Table {
  TextColumn get id => text()();
  TextColumn get rating => text()();
  TextColumn get reviewType => text()();
  DateTimeColumn get reviewedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get moveId =>
      text().nullable().references(Moves, #id, onDelete: KeyAction.setNull)();

  /// FK to combos — set when reviewing a combo. Nullable because most
  /// reviews are move reviews. Added in schema v8 alongside FSRS combo support.
  TextColumn get comboId =>
      text().nullable().references(Combos, #id, onDelete: KeyAction.setNull)();

  /// FSRS card state *before* this review was processed.
  /// Null for legacy reviews recorded before the streaks redesign.
  /// Values: 0=New, 1=Learning, 2=Review, 3=Relearning.
  IntColumn get fsrsPreState => integer().nullable()();

  /// FSRS card state *after* this review was processed.
  /// When fsrsPreState != 2 && fsrsPostState == 2, the card "graduated"
  /// (transitioned to Review state), meaning the learner demonstrated recall.
  IntColumn get fsrsPostState => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
