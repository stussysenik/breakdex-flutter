import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers.dart';

/// Live stream of all saved decks.
final decksListProvider = StreamProvider<List<Deck>>((ref) {
  return ref.watch(decksDaoProvider).watchAll();
});

/// Currently selected deck for the next review session.
/// Null = no deck selected (use default category/state filters).
final selectedDeckProvider = StateProvider<Deck?>((ref) => null);

/// Resolves a deck to its matching moves using DeckService.
final deckMovesProvider =
    FutureProvider.family<List<Move>, String>((ref, deckId) async {
  final deck = await ref.watch(decksDaoProvider).getById(deckId);
  if (deck == null) return [];
  return ref.watch(deckServiceProvider).resolveDeck(deck);
});
