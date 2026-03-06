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

  @override
  Set<Column> get primaryKey => {deckId, moveId};
}
