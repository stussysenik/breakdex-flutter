import 'package:drift/drift.dart';

/// A named study deck with filter criteria or manually selected moves.
///
/// Two modes:
/// - **Smart deck** (deckType = 'smart'): Filter-based using [filterCriteria]
///   JSON. Dynamic — new moves auto-included when matching.
/// - **Manual deck** (deckType = 'manual'): Hand-picked moves via the
///   DeckMoves join table. Static — user explicitly adds/removes moves.
class Decks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// 'smart' or 'manual'
  TextColumn get deckType => text().withDefault(const Constant('smart'))();

  /// JSON-encoded filter criteria for smart decks.
  /// Format: {"categories": [...], "fsrsStates": [...], "dueOnly": bool}
  /// Null for manual decks.
  TextColumn get filterCriteria => text().nullable()();

  /// Optional session size override. Null = all matching moves.
  IntColumn get sessionSize => integer().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Reversible soft-hide set when an inbound sync tombstone applies a remote
  /// deck delete on a secondary device (task 4.8). Pull-side only — a local
  /// delete still hard-deletes on its origin device. Read paths filter
  /// `deletedAt IS NULL`.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
