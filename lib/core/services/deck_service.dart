import 'dart:convert';
import '../database/database.dart';
import '../database/daos/decks_dao.dart';
import '../database/daos/fsrs_cards_dao.dart';
import '../database/daos/moves_dao.dart';

/// Filter criteria for smart decks, serialized as JSON in the database.
class DeckFilter {
  final List<String> categories;
  final List<int> fsrsStates;
  final bool dueOnly;

  const DeckFilter({
    this.categories = const [],
    this.fsrsStates = const [],
    this.dueOnly = false,
  });

  factory DeckFilter.fromJson(final String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return DeckFilter(
      categories: (map['categories'] as List?)?.cast<String>() ?? [],
      fsrsStates: (map['fsrsStates'] as List?)?.cast<int>() ?? [],
      dueOnly: map['dueOnly'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode({
    'categories': categories,
    'fsrsStates': fsrsStates,
    'dueOnly': dueOnly,
  });

  bool get isEmpty => categories.isEmpty && fsrsStates.isEmpty && !dueOnly;
}

/// Resolves a deck to a concrete list of moves based on its type and criteria.
///
/// Smart decks evaluate filters against live move + FSRS card data.
/// Manual decks look up the DeckMoves join table.
class DeckService {
  final DecksDao _decksDao;
  final MovesDao _movesDao;
  final FsrsCardsDao _fsrsCardsDao;

  DeckService(this._decksDao, this._movesDao, this._fsrsCardsDao);

  /// Resolve a deck to its matching moves.
  Future<List<Move>> resolveDeck(final Deck deck) async {
    if (deck.deckType == 'manual') {
      return _decksDao.getMovesForDeck(deck.id);
    }

    // Smart deck: apply filter criteria
    final filter = deck.filterCriteria != null
        ? DeckFilter.fromJson(deck.filterCriteria!)
        : const DeckFilter();

    var moves = await _movesDao.getAll();
    final now = DateTime.now().toUtc();

    // Filter by categories
    if (filter.categories.isNotEmpty) {
      moves = moves
          .where((final m) => filter.categories.contains(m.category))
          .toList();
    }

    // Filter by FSRS states
    if (filter.fsrsStates.isNotEmpty) {
      final cards = await _fsrsCardsDao.getAll();
      final stateByMoveId = {for (final c in cards) c.entityId: c.fsrsState};
      moves = moves.where((final m) {
        final state = stateByMoveId[m.id] ?? 0; // 0 = new
        return filter.fsrsStates.contains(state);
      }).toList();
    }

    // Filter by due-only
    if (filter.dueOnly) {
      final cards = await _fsrsCardsDao.getAll();
      final dueIds = cards
          .where((final c) => !c.due.isAfter(now))
          .map((final c) => c.entityId)
          .toSet();
      moves = moves.where((final m) => dueIds.contains(m.id)).toList();
    }

    return moves;
  }
}
