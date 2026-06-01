import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/shared/widgets/state_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('state pill uses the configured semantic color and label', (
    final tester,
  ) async {
    const customLearning = Color(0xFF4A8F6A);

    SharedPreferences.setMockInitialValues({
      'learning_state_color_learning': customLearning.toARGB32(),
      'learning_state_labels':
          '{"NEW":"New","LEARNING":"In Rotation","MASTERY":"Mastery"}',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: Consumer(
          builder: (final context, final ref, _) {
            final stateColors = ref.watch(learningStateColorsProvider);
            return MaterialApp(
              theme: AppTheme.light(stateColors: stateColors),
              home: const Scaffold(
                body: Center(child: StatePill(state: LearningState.learning)),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    final label = tester.widget<Text>(find.text('In Rotation'));
    expect(label.style?.color, customLearning);
  });

  testWidgets('state pill can act as a quick edit control', (final tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var tapped = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: Consumer(
          builder: (final context, final ref, _) {
            final stateColors = ref.watch(learningStateColorsProvider);
            return MaterialApp(
              theme: AppTheme.light(stateColors: stateColors),
              home: Scaffold(
                body: Center(
                  child: StatePill(
                    state: LearningState.learning,
                    onTap: () => tapped = true,
                    showDisclosure: true,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(StatePill));
    await tester.pump();

    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(tapped, isTrue);
  });
}
