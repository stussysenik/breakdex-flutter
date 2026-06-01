import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/settings/widgets/review_card_display_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'review card display section uses compact rows and toggles settings',
    (final tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: ReviewCardDisplaySection()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Speed + loop controls'), findsOneWidget);
      expect(find.text('Keep music playing'), findsOneWidget);
      expect(
        find.text('Show the move or combo name on the card.'),
        findsNothing,
      );

      await tester.tap(find.text('Title'));
      await tester.pumpAndSettle();

      expect(
        container.read(reviewCardDisplaySettingsProvider).showTitle,
        isFalse,
      );

      await tester.tap(find.text('Keep music playing'));
      await tester.pumpAndSettle();

      expect(container.read(silentPracticePlaybackProvider), isTrue);
    },
  );
}
