import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/flashcard_review/providers/review_providers.dart';
import 'package:breakdex/features/flashcard_review/widgets/mastery_prescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('state review launcher uses the quieter summary layout', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          totalReviewableCountProvider.overrideWith((ref) async => 3),
          reviewStateMatrixProvider.overrideWith(
            (ref) async => const ReviewStateMatrix(
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
    expect(find.text('1 + 1 + 1 = 3'), findsOneWidget);
    expect(find.text('Review all'), findsOneWidget);
  });
}
