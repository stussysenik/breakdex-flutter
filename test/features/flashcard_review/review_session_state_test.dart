import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/features/flashcard_review/providers/review_providers.dart';
import 'package:breakdex/features/flashcard_review/review_session_state.dart';
import 'package:flutter_test/flutter_test.dart';

ReviewSessionItem makeItem(final String id) => ReviewSessionItem(
  entityId: id,
  entityType: 'move',
  displayName: 'Move $id',
  state: LearningState.learning,
);

void main() {
  group('reconcileReviewSession', () {
    test('preserves the current item when it still exists', () {
      final previous = [makeItem('a'), makeItem('b'), makeItem('c')];
      final next = [makeItem('a'), makeItem('b'), makeItem('c')];

      final result = reconcileReviewSession(
        previousItems: previous,
        nextItems: next,
        currentIndex: 1,
        completed: false,
        assessmentStageVisible: true,
      );

      expect(result.currentIndex, 1);
      expect(reviewSessionItemKey(result.items[result.currentIndex]), 'move:b');
      expect(result.assessmentStageVisible, isTrue);
    });

    test(
      'clamps to the next valid position when the current item disappears',
      () {
        final previous = [makeItem('a'), makeItem('b'), makeItem('c')];
        final next = [makeItem('a'), makeItem('c')];

        final result = reconcileReviewSession(
          previousItems: previous,
          nextItems: next,
          currentIndex: 1,
          completed: false,
          assessmentStageVisible: true,
        );

        expect(result.currentIndex, 1);
        expect(
          reviewSessionItemKey(result.items[result.currentIndex]),
          'move:c',
        );
        expect(result.assessmentStageVisible, isFalse);
        expect(result.removedCount, 1);
        expect(result.currentItemRemoved, isTrue);
      },
    );

    test('preserves queue order from the active session', () {
      final previous = [makeItem('a'), makeItem('b'), makeItem('c')];
      final next = [makeItem('x'), makeItem('a'), makeItem('c')];

      final result = reconcileReviewSession(
        previousItems: previous,
        nextItems: next,
        currentIndex: 2,
        completed: false,
        assessmentStageVisible: false,
      );

      expect(result.items.map(reviewSessionItemKey), ['move:a', 'move:c']);
      expect(result.currentIndex, 1);
      expect(result.currentItemRemoved, isFalse);
    });
  });
}
