import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/decks.dart';
import '../tables/deck_moves.dart';
import '../tables/moves.dart';

part 'decks_dao.g.dart';

@DriftAccessor(tables: [Decks, DeckMoves, Moves])
class DecksDao extends DatabaseAccessor<AppDatabase> with _$DecksDaoMixin {
  DecksDao(super.db);

  /// Watch all decks ordered by creation date.
  Stream<List<Deck>> watchAll() =>
      (select(decks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<Deck>> getAll() => select(decks).get();

  Future<Deck?> getById(String id) =>
      (select(decks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertDeck(DecksCompanion entry) =>
      into(decks).insert(entry);

  Future<void> updateDeck(DecksCompanion entry) =>
      (update(decks)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  Future<void> deleteDeck(String id) async {
    // DeckMoves cascade-deletes automatically via FK
    await (delete(decks)..where((t) => t.id.equals(id))).go();
  }

  // -- DeckMoves (manual decks) -----------------------------------------------

  /// Get all move IDs in a manual deck.
  Future<List<String>> getMoveIdsForDeck(String deckId) async {
    final rows = await (select(deckMoves)
          ..where((t) => t.deckId.equals(deckId)))
        .get();
    return rows.map((r) => r.moveId).toList();
  }

  /// Add a move to a manual deck.
  Future<void> addMoveToDeck(String deckId, String moveId) =>
      into(deckMoves).insert(
        DeckMovesCompanion.insert(deckId: deckId, moveId: moveId),
        mode: InsertMode.insertOrIgnore,
      );

  /// Remove a move from a manual deck.
  Future<void> removeMoveFromDeck(String deckId, String moveId) =>
      (delete(deckMoves)
            ..where(
                (t) => t.deckId.equals(deckId) & t.moveId.equals(moveId)))
          .go();

  /// Get full Move objects for a manual deck.
  Future<List<Move>> getMovesForDeck(String deckId) async {
    final query = select(moves).join([
      innerJoin(deckMoves, deckMoves.moveId.equalsExp(moves.id)),
    ])
      ..where(deckMoves.deckId.equals(deckId));

    final rows = await query.get();
    return rows.map((r) => r.readTable(moves)).toList();
  }
}
