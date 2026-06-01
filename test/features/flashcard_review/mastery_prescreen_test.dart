import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/flashcard_review/providers/review_providers.dart';
import 'package:breakdex/features/flashcard_review/widgets/mastery_prescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:breakdex/core/data/repositories.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';

class FakeMoveRepository implements MoveRepository {
  @override
  Stream<List<Move>> watchAll() => Stream.value([
        Move(id: '1', name: 'Move 1', category: 'default', learningState: 'NEW', count: 0, createdAt: DateTime.utc(2026)),
        Move(id: '2', name: 'Move 2', category: 'default', learningState: 'LEARNING', count: 0, createdAt: DateTime.utc(2026)),
        Move(id: '3', name: 'Move 3', category: 'default', learningState: 'MASTERY', count: 0, createdAt: DateTime.utc(2026)),
      ]);
  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeComboRepository implements ComboRepository {
  @override
  Stream<List<(Combo, int)>> watchAllWithMoveCounts() => Stream.value([]);
  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('state review launcher uses the quieter summary layout', (
    final tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moveRepositoryProvider.overrideWithValue(FakeMoveRepository()),
          comboRepositoryProvider.overrideWithValue(FakeComboRepository()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          totalReviewableCountProvider.overrideWith((final ref) async => 3),
          reviewStateMatrixProvider.overrideWith(
            (final ref) async => const ReviewStateMatrix(
              moveCounts: {
                LearningState.newState: 1,
                LearningState.learning: 1,
                LearningState.mastery: 1,
              },
              comboCounts: {
                LearningState.newState: 0,
                LearningState.learning: 0,
                LearningState.mastery: 0,
              },
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: MasteryPrescreen(source: ReviewSessionSource.stateBased),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('3 due now'), findsNothing);
    expect(find.text('Due move cards'), findsNothing);
    expect(find.text('First recall'), findsNothing);
    expect(find.text('Short intervals'), findsNothing);
    expect(find.text('Long intervals'), findsNothing);
    expect(find.text('Tap to start this state'), findsNothing);
    expect(find.text('Review all'), findsOneWidget);
  });
}
