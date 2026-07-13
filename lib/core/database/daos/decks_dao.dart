import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/decks.dart';
import '../tables/deck_moves.dart';
import '../tables/moves.dart';
import '../../sync/codecs/deck_codec.dart' show deckMoveWireId;
import 'sync_dao.dart';

part 'decks_dao.g.dart';

@DriftAccessor(tables: [Decks, DeckMoves, Moves])
class DecksDao extends DatabaseAccessor<AppDatabase> with _$DecksDaoMixin {
  DecksDao(super.db);

  /// Dirty-tracking sink (task 4.7). Decks bypass the `SyncAware*` repository
  /// layer, so the sync-log hook lives here — every user-initiated mutation logs
  /// to `sync_log` so the Appwrite dual-write can shadow it (D11: Appwrite-only,
  /// no Firestore leg). Remote-origin merges write straight to Drift (not via
  /// this DAO), so a pulled row is never re-enqueued.
  SyncDao get _sync => attachedDatabase.syncDao;

  /// Stamp a deck's LWW clock on write unless the caller already set one
  /// (mirrors `CombosDao._stampCombo`).
  DecksCompanion _stampDeck(final DecksCompanion entry) => entry.updatedAt.present
      ? entry
      : entry.copyWith(updatedAt: Value(DateTime.now().toUtc()));

  /// As [_stampDeck], for `deck_moves`. This table has no `createdAt`, so
  /// stamping on insert is what guarantees every join row carries a clock.
  DeckMovesCompanion _stampDeckMove(final DeckMovesCompanion entry) =>
      entry.updatedAt.present
          ? entry
          : entry.copyWith(updatedAt: Value(DateTime.now().toUtc()));

  /// Watch all decks ordered by creation date. Excludes rows hidden by an
  /// inbound sync tombstone (task 4.8).
  Stream<List<Deck>> watchAll() => (select(decks)
        ..where((final t) => t.deletedAt.isNull())
        ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Future<List<Deck>> getAll() =>
      (select(decks)..where((final t) => t.deletedAt.isNull())).get();

  /// Every deck-move join row — read-only, for the non-destructive backfill.
  Future<List<DeckMove>> getAllDeckMoves() => select(deckMoves).get();

  Future<Deck?> getById(final String id) =>
      (select(decks)..where((final t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertDeck(final DecksCompanion entry) async {
    await into(decks).insert(_stampDeck(entry));
    await _sync.logChange(
        entityId: entry.id.value, table: 'decks', action: 'create');
  }

  Future<void> updateDeck(final DecksCompanion entry) async {
    await (update(decks)..where((final t) => t.id.equals(entry.id.value)))
        .write(_stampDeck(entry));
    await _sync.logChange(
        entityId: entry.id.value, table: 'decks', action: 'update');
  }

  Future<void> deleteDeck(final String id) async {
    // DeckMoves cascade-deletes automatically via FK. As with combos, only the
    // parent tombstone is logged; the backend join rows are inert once the deck
    // is gone.
    await (delete(decks)..where((final t) => t.id.equals(id))).go();
    await _sync.logChange(entityId: id, table: 'decks', action: 'delete');
  }

  // -- DeckMoves (manual decks) -----------------------------------------------

  /// Get all move IDs in a manual deck.
  Future<List<String>> getMoveIdsForDeck(final String deckId) async {
    final rows = await (select(deckMoves)
          ..where((final t) => t.deckId.equals(deckId) & t.deletedAt.isNull()))
        .get();
    return rows.map((final r) => r.moveId).toList();
  }

  /// Add a move to a manual deck.
  Future<void> addMoveToDeck(final String deckId, final String moveId) async {
    await into(deckMoves).insert(
      _stampDeckMove(
          DeckMovesCompanion.insert(deckId: deckId, moveId: moveId)),
      mode: InsertMode.insertOrIgnore,
    );
    await _sync.logChange(
        entityId: deckMoveWireId(deckId, moveId),
        table: 'deck_moves',
        action: 'create');
  }

  /// Remove a move from a manual deck.
  Future<void> removeMoveFromDeck(
      final String deckId, final String moveId) async {
    await (delete(deckMoves)
          ..where(
              (final t) => t.deckId.equals(deckId) & t.moveId.equals(moveId)))
        .go();
    await _sync.logChange(
        entityId: deckMoveWireId(deckId, moveId),
        table: 'deck_moves',
        action: 'delete');
  }

  /// Clear all moves from a manual deck. Mirrors `CombosDao.clearMoves` — the
  /// bulk clear is not per-row sync-logged (the same parity choice as combos).
  Future<void> clearDeckMoves(final String deckId) =>
      (delete(deckMoves)..where((final t) => t.deckId.equals(deckId))).go();

  /// Get full Move objects for a manual deck.
  Future<List<Move>> getMovesForDeck(final String deckId) async {
    final query = select(moves).join([
      innerJoin(deckMoves, deckMoves.moveId.equalsExp(moves.id)),
    ])
      ..where(deckMoves.deckId.equals(deckId) & deckMoves.deletedAt.isNull());

    final rows = await query.get();
    return rows.map((final r) => r.readTable(moves)).toList();
  }
}
