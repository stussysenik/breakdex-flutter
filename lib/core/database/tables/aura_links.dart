import 'package:drift/drift.dart';
import 'moves.dart';

@ReferenceName('auraLinksFromRefs')
@ReferenceName('auraLinksToRefs')
class AuraLinks extends Table {
  @ReferenceName('auraLinksFromRefs')
  TextColumn get fromMoveId =>
      text().references(Moves, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('auraLinksToRefs')
  TextColumn get toMoveId =>
      text().references(Moves, #id, onDelete: KeyAction.cascade)();

  /// 'natural', 'possible', or 'stretch'
  TextColumn get affinity => text().withLength(min: 1)();

  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {fromMoveId, toMoveId};
}
