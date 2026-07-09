import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/flashcard_review/widgets/srs_parameters_card.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  Future<ProviderContainer> pumpCard(final WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(child: SrsParametersCard()),
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('starts at the default 85% retention', (final tester) async {
    final container = await pumpCard(tester);
    addTearDown(container.dispose);

    expect(find.text('85%'), findsOneWidget);
    expect(container.read(fsrsSettingsProvider).desiredRetention, 0.85);
  });

  testWidgets('dragging the retention slider updates the notifier and display',
      (final tester) async {
    final container = await pumpCard(tester);
    addTearDown(container.dispose);

    final slider = tester.widget<Slider>(find.byType(Slider));

    // Drag in progress: display tracks the draft, notifier not yet committed.
    slider.onChanged!(0.95);
    await tester.pump();
    expect(find.text('95%'), findsOneWidget);
    expect(container.read(fsrsSettingsProvider).desiredRetention, 0.85,
        reason: 'not committed until release');

    // Release: commits to the notifier (and persists).
    slider.onChangeEnd!(0.95);
    await tester.pumpAndSettle();
    expect(container.read(fsrsSettingsProvider).desiredRetention, 0.95);
    expect(find.text('95%'), findsOneWidget);
    expect(prefs.getDouble('fsrs.desiredRetention'), 0.95);
  });

  testWidgets('reset returns retention to the 85% default',
      (final tester) async {
    final container = await pumpCard(tester);
    addTearDown(container.dispose);

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeEnd!(0.95);
    await tester.pumpAndSettle();
    expect(container.read(fsrsSettingsProvider).desiredRetention, 0.95);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(container.read(fsrsSettingsProvider).desiredRetention, 0.85);
    expect(find.text('85%'), findsOneWidget);
  });

  testWidgets('toggling fuzzing flows through to the notifier',
      (final tester) async {
    final container = await pumpCard(tester);
    addTearDown(container.dispose);

    expect(container.read(fsrsSettingsProvider).enableFuzzing, true);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(container.read(fsrsSettingsProvider).enableFuzzing, false);
  });
}
