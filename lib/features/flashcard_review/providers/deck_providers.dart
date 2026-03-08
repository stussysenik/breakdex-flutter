import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';

/// Live stream of all saved decks.
final decksListProvider = StreamProvider<List<Deck>>((ref) {
  return ref.watch(decksDaoProvider).watchAll();
});

/// Currently selected deck for the next review session.
/// Null = no deck selected (use default category/state filters).
final selectedDeckProvider = StateProvider<Deck?>((ref) => null);

/// Resolves a deck to its matching moves using DeckService.
final deckMovesProvider = FutureProvider.family<List<Move>, String>((
  ref,
  deckId,
) async {
  final deck = await ref.watch(decksDaoProvider).getById(deckId);
  if (deck == null) return [];
  return ref.watch(deckServiceProvider).resolveDeck(deck);
});

class DeckSummary {
  const DeckSummary({
    required this.deck,
    required this.moves,
    required this.stateMap,
    required this.categories,
  });

  final Deck deck;
  final List<Move> moves;
  final Map<LearningState, List<Move>> stateMap;
  final Set<String> categories;

  int get totalMoves => moves.length;
  bool get isSmart => deck.deckType == 'smart';

  List<Move> movesForState(LearningState state) => stateMap[state] ?? const [];
}

final deckSummaryProvider = FutureProvider.family<DeckSummary, String>((
  ref,
  deckId,
) async {
  final deck = await ref.watch(decksDaoProvider).getById(deckId);
  if (deck == null) {
    throw StateError('Deck $deckId no longer exists');
  }

  final moves = await ref.watch(deckServiceProvider).resolveDeck(deck);
  final stateMap = {
    for (final state in LearningState.values)
      state: moves
          .where((move) => move.learningState == state.dbValue)
          .toList(),
  };
  final categories = moves.map((move) => move.category).toSet();

  return DeckSummary(
    deck: deck,
    moves: moves,
    stateMap: stateMap,
    categories: categories,
  );
});
