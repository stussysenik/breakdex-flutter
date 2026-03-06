import 'package:drift/drift.dart';

/// FSRS scheduling data for moves and combos (polymorphic 1:1 relationship).
///
/// FSRS (Free Spaced Repetition Scheduler) models memory as two variables:
/// - **Stability**: how long a memory lasts (in days) before retrievability
///   drops to the desired retention threshold (e.g. 85%).
/// - **Difficulty**: how hard the item is to learn (0–10 scale), updated
///   after each review based on the rating given.
///
/// Uses a polymorphic pattern (entityId + entityType) so the same scheduling
/// table works for both moves and combos — similar to how SyncLog references
/// multiple entity types without foreign keys.
class FsrsCards extends Table {
  /// ID of the move or combo this card belongs to.
  TextColumn get entityId => text()();

  /// Entity type: 'move' or 'combo'. Defaults to 'move' for backward compat.
  TextColumn get entityType =>
      text().withDefault(const Constant('move'))();

  /// Memory stability in days — higher means longer retention.
  RealColumn get stability => real().withDefault(const Constant(0.0))();

  /// Item difficulty on a 0–10 scale — higher means harder to remember.
  RealColumn get difficulty => real().withDefault(const Constant(0.0))();

  /// When this card is next due for review (UTC).
  DateTimeColumn get due => dateTime().withDefault(currentDateAndTime)();

  /// When this card was last reviewed (UTC). Null if never reviewed.
  DateTimeColumn get lastReview => dateTime().nullable()();

  /// Consecutive successful reviews (resets on lapse).
  IntColumn get reps => integer().withDefault(const Constant(0))();

  /// Number of times the card lapsed (was forgotten after graduating).
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  /// FSRS state: 0=New, 1=Learning, 2=Review, 3=Relearning.
  IntColumn get fsrsState => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {entityId, entityType};
}
