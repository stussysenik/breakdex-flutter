import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/models/review_card_display_settings.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/flashcard_review/widgets/review_card.dart';
import 'package:breakdex/shared/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpReviewCard(
    WidgetTester tester, {
    required bool showMetadataPanel,
    required ReviewCardDisplaySettings displaySettings,
    Map<String, Object> initialPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              height: 640,
              child: ReviewCard(
                title: 'Fixture Swipe',
                state: LearningState.learning,
                displaySettings: displaySettings,
                showMetadataPanel: showMetadataPanel,
                onStatePillTap: () {},
                currentIndex: 0,
                totalItems: 3,
                category: 'Footwork',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('ReviewCard', () {
    testWidgets('shows the first-look video surface with learning info', (
      tester,
    ) async {
      await pumpReviewCard(
        tester,
        showMetadataPanel: true,
        displaySettings: const ReviewCardDisplaySettings(),
      );

      expect(find.byType(VideoPlaceholder), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text('Fixture Swipe'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('FOOTWORK'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);
    });

    testWidgets('hides first-look metadata during the assessment stage', (
      tester,
    ) async {
      await pumpReviewCard(
        tester,
        showMetadataPanel: false,
        displaySettings: const ReviewCardDisplaySettings(),
      );

      expect(find.byType(VideoPlaceholder), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text('Fixture Swipe'), findsNothing);
      expect(find.text('Learning'), findsNothing);
      expect(find.text('FOOTWORK'), findsNothing);
      expect(find.text('1x'), findsNothing);
    });

    testWidgets('respects configurable first-look card visibility settings', (
      tester,
    ) async {
      await pumpReviewCard(
        tester,
        showMetadataPanel: true,
        displaySettings: const ReviewCardDisplaySettings(
          showTitle: false,
          showState: true,
          showCategory: false,
          showPlaybackControls: false,
        ),
      );

      expect(find.byType(VideoPlaceholder), findsOneWidget);
      expect(find.text('Fixture Swipe'), findsNothing);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('FOOTWORK'), findsNothing);
      expect(find.text('1x'), findsNothing);
    });

    testWidgets('uses custom learning state labels from settings', (
      tester,
    ) async {
      await pumpReviewCard(
        tester,
        showMetadataPanel: true,
        displaySettings: const ReviewCardDisplaySettings(),
        initialPrefs: const {
          'learning_state_labels':
              '{"NEW":"Fresh","LEARNING":"In Rotation","MASTERY":"Locked"}',
        },
      );

      expect(find.text('In Rotation'), findsOneWidget);
      expect(find.text('Learning'), findsNothing);
    });
  });
}
