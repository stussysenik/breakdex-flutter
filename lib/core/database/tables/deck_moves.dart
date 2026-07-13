import 'package:drift/drift.dart';
import 'decks.dart';
import 'moves.dart';

/// Join table for manual decks — maps specific moves to a deck.
///
/// Only used when the parent Deck has deckType = 'manual'.
/// Smart decks resolve moves dynamically via filter criteria.
class DeckMoves extends Table {
  TextColumn get deckId =>
      text().references(Decks, #id, onDelete: KeyAction.cascade)();
  TextColumn get moveId =>
      text().references(Moves, #id, onDelete: KeyAction.cascade)();

  /// Last-writer-wins clock for backend sync (task 4.7). Nullable so the additive
  /// v25 migration can backfill it (this table has no `createdAt`, so existing
  /// rows are seeded from the parent deck's `updatedAt`); the DAO stamps it on
  /// every insert, so new rows always carry a real clock.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {deckId, moveId};
}
