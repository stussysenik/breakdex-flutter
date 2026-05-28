import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/settings/widgets/review_states_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'review states section combines custom labels and color metadata',
    (tester) async {
      const customLearning = Color(0xFF4A8F6A);

      SharedPreferences.setMockInitialValues({
        'learning_state_labels':
            '{"NEW":"New","LEARNING":"In Rotation","MASTERY":"Mastery"}',
        'learning_state_color_learning': customLearning.toARGB32(),
      });
      final prefs = await SharedPreferences.getInstance();

      LearningState? tappedState;
      String? tappedLabel;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: Consumer(
            builder: (context, ref, _) {
              final stateColors = ref.watch(learningStateColorsProvider);
              return MaterialApp(
                theme: AppTheme.light(stateColors: stateColors),
                home: Scaffold(
                  body: ReviewStatesSection(
                    onRename: (state, currentLabel) {
                      tappedState = state;
                      tappedLabel = currentLabel;
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('In Rotation'), findsOneWidget);
      expect(find.text('Default: Practicing'), findsOneWidget);
      expect(find.text('#FF4A8F6A'), findsOneWidget);

      await tester.tap(find.text('In Rotation'));
      await tester.pumpAndSettle();

      expect(tappedState, LearningState.learning);
      expect(tappedLabel, 'In Rotation');
    },
  );
}
