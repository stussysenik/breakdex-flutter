import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/models/review_card_display_settings.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/flashcard_review/widgets/review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs([final Map<String, Object> seed = const {}]) {
  SharedPreferences.setMockInitialValues(seed);
  return SharedPreferences.getInstance();
}

Widget _host(final SharedPreferences prefs, final Size size) => ProviderScope(
  overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  child: MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: ReviewCard(
            title: 'Flare',
            state: LearningState.learning,
            displaySettings: ReviewCardDisplaySettings.defaults,
            showMetadataPanel: true,
            onStatePillTap: () {},
            currentIndex: 0,
            totalItems: 5,
            category: 'POWER',
          ),
        ),
      ),
    ),
  ),
);

void main() {
  // Reference form factors: a small phone content area and a tablet.
  const smallPhone = Size(360, 600);
  const tablet = Size(760, 1000);

  testWidgets('review card renders without a scroll view on a small phone', (
    final tester,
  ) async {
    final prefs = await _prefs();
    await tester.pumpWidget(_host(prefs, smallPhone));
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('review card renders without a scroll view on a tablet', (
    final tester,
  ) async {
    final prefs = await _prefs();
    await tester.pumpWidget(_host(prefs, tablet));
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('custom fill applies live from the persisted setting', (
    final tester,
  ) async {
    const fill = Color(0xFFEE3355);
    final prefs = await _prefs({'review_fill_color': fill.toARGB32()});
    await tester.pumpWidget(_host(prefs, tablet));

    final framePainted = tester.widgetList<Container>(find.byType(Container)).any(
      (final c) => c.decoration is BoxDecoration &&
          (c.decoration! as BoxDecoration).color == fill,
    );
    expect(framePainted, isTrue);
  });
}
