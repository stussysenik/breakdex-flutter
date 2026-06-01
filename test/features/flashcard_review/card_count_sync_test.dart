import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/flashcard_review/providers/review_providers.dart';

import '../../helpers/test_data.dart';
import '../../helpers/test_database.dart';

/// Tests that reviewStateMatrixProvider counts match
/// filteredReviewSessionItemsProvider results for moves and combos,
/// ensuring the prescreen badges reflect reality.
void main() {
  group('Card count sync — matrix vs session items', () {
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
          // Override stream providers watched by the FutureProviders for
          // cache invalidation. The full repository chain (moveRepository →
          // watchAll) doesn't resolve in the test environment.
          fsrsCardsRefreshProvider.overrideWith(
            (final ref) => Stream.value(<FsrsCard>[]),
          ),
          moveStateCountsProvider.overrideWith(
            (final ref) => Stream.value(<LearningState, int>{
              for (final s in LearningState.values) s: 0,
            }),
          ),
          comboRefreshProvider.overrideWith((final ref) => Stream.value(0)),
          // Added these to fix timeouts in tests
          reviewEntityKindProvider.overrideWith((final ref) => ReviewEntityKind.moves),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    /// Riverpod FutureProviders wait for watched StreamProvider dependencies
    /// to leave AsyncLoading state before executing their body. Force-resolve
    /// the overridden streams so the FutureProviders can proceed.
    Future<void> settleStreams() async {
      await container.read(fsrsCardsRefreshProvider.future);
      await container.read(moveStateCountsProvider.future);
      await container.read(comboRefreshProvider.future);
      await container.read(reactiveMovesProvider.future);
      await container.read(reactiveCombosProvider.future);
    }

    test(
      'Learning count matches filtered session items with state=Learning',
      () async {
        // Seed: 1 new, 2 learning, 1 mastery
        await seedMove(db, id: 'new-1', name: 'Baby Freeze');
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
                id: 'learn-2',
                name: 'Swipe',
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
        await seedFsrsCard(
          db,
          entityId: 'learn-1',
          entityType: 'move',
          fsrsState: 1,
        );
        await seedFsrsCard(
          db,
          entityId: 'learn-2',
          entityType: 'move',
          fsrsState: 1,
        );
        await seedFsrsCard(
          db,
          entityId: 'master-1',
          entityType: 'move',
          fsrsState: 2,
        );

        await settleStreams();

        // Query matrix
        final matrix = await container.read(reviewStateMatrixProvider.future);
        final learningCount = matrix.moveCounts[LearningState.learning] ?? 0;

        // Query session items filtered to learning
        container.read(reviewStateFilterProvider.notifier).state =
            LearningState.learning;
        container.read(reviewEntityKindProvider.notifier).state =
            ReviewEntityKind.moves;
        final sessionItems = await container.read(
          filteredReviewSessionItemsProvider.future,
        );

        expect(learningCount, 2);
        expect(sessionItems.length, learningCount);
      },
    );

    test('After adding a new move, both providers include it', () async {
      await seedMove(db, id: 'move-1', name: 'Windmill');
      await settleStreams();

      // Get baseline
      final matrixBefore = await container.read(
        reviewStateMatrixProvider.future,
      );
      final totalBefore = matrixBefore.totalFor(ReviewEntityKind.moves);

      // Add a move
      await db
          .into(db.moves)
          .insert(MovesCompanion.insert(id: 'move-2', name: 'Halo'));

      // Invalidate both providers to force re-fetch
      container.invalidate(reviewStateMatrixProvider);
      container.invalidate(filteredReviewSessionItemsProvider);

      final matrixAfter = await container.read(
        reviewStateMatrixProvider.future,
      );
      final totalAfter = matrixAfter.totalFor(ReviewEntityKind.moves);

      container.read(reviewStateFilterProvider.notifier).state = null;
      container.read(reviewEntityKindProvider.notifier).state =
          ReviewEntityKind.moves;
      final sessionItems = await container.read(
        filteredReviewSessionItemsProvider.future,
      );

      expect(totalAfter, totalBefore + 1);
      expect(sessionItems.length, totalAfter);
    });

    test('After deleting a move, both providers exclude it', () async {
      await seedMove(db, id: 'move-1', name: 'Windmill');
      await seedMove(db, id: 'move-2', name: 'Halo');
      await settleStreams();

      // Delete one
      await (db.delete(db.moves)..where((final m) => m.id.equals('move-2'))).go();

      container.invalidate(reviewStateMatrixProvider);
      container.invalidate(filteredReviewSessionItemsProvider);

      final matrix = await container.read(reviewStateMatrixProvider.future);
      final total = matrix.totalFor(ReviewEntityKind.moves);

      container.read(reviewStateFilterProvider.notifier).state = null;
      container.read(reviewEntityKindProvider.notifier).state =
          ReviewEntityKind.moves;
      final sessionItems = await container.read(
        filteredReviewSessionItemsProvider.future,
      );

      expect(total, 1);
      expect(sessionItems.length, total);
    });

    test('FSRS card state change reflected in both providers', () async {
      await seedMove(db, id: 'move-1', name: 'Windmill');
      // Seed FSRS card as "learning" (fsrsState=1)
      await seedFsrsCard(
        db,
        entityId: 'move-1',
        entityType: 'move',
        fsrsState: 1,
      );
      await settleStreams();

      container.invalidate(reviewStateMatrixProvider);
      container.invalidate(filteredReviewSessionItemsProvider);

      final matrix = await container.read(reviewStateMatrixProvider.future);
      final learningCount = matrix.moveCounts[LearningState.learning] ?? 0;

      container.read(reviewStateFilterProvider.notifier).state =
          LearningState.learning;
      container.read(reviewEntityKindProvider.notifier).state =
          ReviewEntityKind.moves;
      final sessionItems = await container.read(
        filteredReviewSessionItemsProvider.future,
      );

      expect(learningCount, 1);
      expect(sessionItems.length, learningCount);
      expect(sessionItems.first.state, LearningState.learning);
    });

    test(
      'Manual move reset updates review launcher counts immediately',
      () async {
        await seedMove(db, id: 'move-new', name: 'Swipe');
        await seedMove(db, id: 'move-learning', name: 'Six-Step');
        await seedMove(db, id: 'move-mastery', name: 'Freeze');
        await (db.update(db.moves)..where((final t) => t.id.equals('move-learning')))
            .write(const MovesCompanion(learningState: Value('LEARNING')));
        await (db.update(db.moves)..where((final t) => t.id.equals('move-mastery')))
            .write(const MovesCompanion(learningState: Value('MASTERY')));
        await seedFsrsCard(
          db,
          entityId: 'move-learning',
          entityType: 'move',
          fsrsState: 1,
        );
        await seedFsrsCard(
          db,
          entityId: 'move-mastery',
          entityType: 'move',
          fsrsState: 2,
        );
        await settleStreams();

        final move = await db.movesDao.getById('move-mastery');
        await container
            .read(manualReviewStateServiceProvider)
            .setMoveState(move, LearningState.newState);

        container.invalidate(reviewStateMatrixProvider);
        container.invalidate(filteredReviewSessionItemsProvider);

        final matrix = await container.read(reviewStateMatrixProvider.future);

        expect(matrix.moveCounts[LearningState.newState], 2);
        expect(matrix.moveCounts[LearningState.learning], 1);
        expect(matrix.moveCounts[LearningState.mastery], 0);

        container.read(reviewStateFilterProvider.notifier).state =
            LearningState.newState;
        container.read(reviewEntityKindProvider.notifier).state =
            ReviewEntityKind.moves;
        final newItems = await container.read(
          filteredReviewSessionItemsProvider.future,
        );

        expect(newItems.length, 2);
        expect(newItems.map((final item) => item.entityId).toSet(), {
          'move-new',
          'move-mastery',
        });
      },
    );

    test('Future-due learning cards are excluded from launch counts', () async {
      await seedMove(db, id: 'due-now', name: 'Windmill');
      await seedMove(db, id: 'due-later', name: 'Headspin');
      await seedFsrsCard(
        db,
        entityId: 'due-now',
        entityType: 'move',
        fsrsState: 1,
        due: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      await seedFsrsCard(
        db,
        entityId: 'due-later',
        entityType: 'move',
        fsrsState: 1,
        due: DateTime.now().toUtc().add(const Duration(days: 1)),
      );
      await settleStreams();

      container.invalidate(reviewStateMatrixProvider);
      container.invalidate(filteredReviewSessionItemsProvider);

      final matrix = await container.read(reviewStateMatrixProvider.future);
      final learningCount = matrix.moveCounts[LearningState.learning] ?? 0;

      container.read(reviewStateFilterProvider.notifier).state =
          LearningState.learning;
      container.read(reviewEntityKindProvider.notifier).state =
          ReviewEntityKind.moves;
      final sessionItems = await container.read(
        filteredReviewSessionItemsProvider.future,
      );

      expect(learningCount, 1);
      expect(sessionItems.map((final item) => item.entityId), ['due-now']);
    });

    test('Combo counts match between matrix and session items', () async {
      await seedCombo(db, id: 'combo-1', name: 'Power Combo');
      await seedCombo(db, id: 'combo-2', name: 'Flow Combo');
      await settleStreams();

      final matrix = await container.read(reviewStateMatrixProvider.future);
      final comboTotal = matrix.totalFor(ReviewEntityKind.combos);

      container.read(reviewStateFilterProvider.notifier).state = null;
      container.read(reviewEntityKindProvider.notifier).state =
          ReviewEntityKind.combos;
      final sessionItems = await container.read(
        filteredReviewSessionItemsProvider.future,
      );

      expect(comboTotal, 2);
      expect(sessionItems.length, comboTotal);
    });
  });
}
