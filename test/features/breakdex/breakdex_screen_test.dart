import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/breakdex/breakdex_screen.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';

Future<void> _pumpBreakdexScreen(final WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BreakdexScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('home is built from the frame, not its own chrome', (
    final tester,
  ) async {
    // The conformance rule is mechanical: a screen carrying its own `AppBar`
    // has opted out of the stacked viewport, which is how five screens ended
    // up with three different header mechanisms.
    await _pumpBreakdexScreen(tester);

    expect(find.byType(AppScreen), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(SliverAppBar), findsNothing);
  });

  testWidgets('hero tiles stay optically centred in the content band', (
    final tester,
  ) async {
    // The frame fixes where the band starts; it does not flatten a screen's
    // internal composition. These two tiles are the app's signature surface —
    // migrating to the frame must not top-anchor them.
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);

    await _pumpBreakdexScreen(tester);

    final moves = find.byWidgetPredicate(
      (final w) => w is Semantics && w.properties.identifier == 'moves-tile',
    );
    final combos = find.byWidgetPredicate(
      (final w) => w is Semantics && w.properties.identifier == 'combos-tile',
    );
    expect(moves, findsOneWidget);
    expect(combos, findsOneWidget);

    // Band 3 runs from the header's bottom edge to the viewport bottom.
    const bandTop = AppLayout.headerHeight;
    final bandBottom = tester.view.physicalSize.height;
    final pairCentre =
        (tester.getTopLeft(moves).dy + tester.getBottomLeft(combos).dy) / 2;

    expect(
      pairCentre,
      closeTo((bandTop + bandBottom) / 2, AppLayout.scrollBottomInset),
      reason: 'hero pair drifted out of the content band centre',
    );
  });
}
