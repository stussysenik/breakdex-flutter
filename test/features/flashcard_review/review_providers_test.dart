import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/flashcard_review/providers/deck_providers.dart';
import 'package:breakdex/features/flashcard_review/providers/review_providers.dart';

import '../../helpers/test_data.dart';
import '../../helpers/test_database.dart';

void main() {
  group('filteredReviewMovesProvider', () {
    late AppDatabase db;
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = createTestDatabase();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          fsrsCardsRefreshProvider.overrideWith(
            (final ref) => Stream.value(<FsrsCard>[]),
          ),
          moveStateCountsProvider.overrideWith(
            (final ref) => Stream.value(
              {for (final state in LearningState.values) state: 0},
            ),
          ),
          comboRefreshProvider.overrideWith((final ref) => Stream.value(0)),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('state-based mode filters to the selected learning state', () async {
      await db
          .into(db.moves)
          .insert(
            MovesCompanion.insert(
              id: 'new-1',
              name: 'Baby Freeze',
              learningState: const Value('NEW'),
            ),
          );
      await db
          .into(db.moves)
          .insert(
            MovesCompanion.insert(
              id: 'learn-1',
              name: 'Windmill',
              learningState: const Value('LEARNING'),
            ),
          );
      await db
          .into(db.moves)
          .insert(
            MovesCompanion.insert(
              id: 'master-1',
              name: 'Halo',
              learningState: const Value('MASTERY'),
            ),
          );

      await container
          .read(reviewSessionSourceProvider.notifier)
          .set(ReviewSessionSource.stateBased);
      container.read(reviewStateFilterProvider.notifier).state =
          LearningState.learning;

      final moves = await container.read(filteredReviewMovesProvider.future);

      expect(moves.map((final move) => move.id), ['learn-1']);
    });

    test('deck mode resolves only moves in the selected manual deck', () async {
      await seedMove(db, id: 'move-1', name: 'Windmill');
      await seedMove(db, id: 'move-2', name: 'Headspin');
      await seedDeck(db, id: 'deck-1', name: 'Battle Set');
      await db.decksDao.addMoveToDeck('deck-1', 'move-2');
      final deck = await db.decksDao.getById('deck-1');

      await container
          .read(reviewSessionSourceProvider.notifier)
          .set(ReviewSessionSource.deck);
      container.read(selectedDeckProvider.notifier).state = deck;

      final moves = await container.read(filteredReviewMovesProvider.future);

      expect(moves.map((final move) => move.id), ['move-2']);
    });

    test('targeted move IDs override deck and state filters', () async {
      await seedMove(db, id: 'move-1', name: 'Windmill');
      await seedMove(db, id: 'move-2', name: 'Headspin');
      await seedDeck(db, id: 'deck-1', name: 'Battle Set');
      await db.decksDao.addMoveToDeck('deck-1', 'move-2');
      final deck = await db.decksDao.getById('deck-1');

      await container
          .read(reviewSessionSourceProvider.notifier)
          .set(ReviewSessionSource.deck);
      container.read(selectedDeckProvider.notifier).state = deck;
      container.read(reviewStateFilterProvider.notifier).state =
          LearningState.mastery;
      container.read(reviewSessionTargetMoveIdsProvider.notifier).state = {
        'move-1',
      };

      final moves = await container.read(filteredReviewMovesProvider.future);

      expect(moves.map((final move) => move.id), ['move-1']);
    });
  });
}
