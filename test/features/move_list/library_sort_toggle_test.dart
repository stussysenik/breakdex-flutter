import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/move_list/move_list_screen.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// Pumps the sort control on its own. The screen it lives in reads live Drift
/// streams, which flake widget tests; this control touches only preferences.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(final WidgetTester tester) => tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: LibrarySortToggle()),
          ),
        ),
      );

  /// The control's own semantics, which carry the selected state.
  bool isSelected(final WidgetTester tester, final String label) {
    final node = tester.getSemantics(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(Semantics),
      ).first,
    );
    return node.flagsCollection.isSelected == Tristate.isTrue;
  }

  testWidgets('renders one pill per sort dimension', (final tester) async {
    await pump(tester);

    expect(find.text('Added'), findsOneWidget);
    expect(find.text('Filmed'), findsOneWidget);
    expect(find.text('Practiced'), findsOneWidget);
    expect(find.text('A–Z'), findsOneWidget);
  });

  testWidgets('defaults to recently added, marked selected', (
    final tester,
  ) async {
    await pump(tester);

    expect(isSelected(tester, 'Added'), isTrue);
    expect(isSelected(tester, 'Practiced'), isFalse);
  });

  testWidgets('tapping a pill moves the selection and persists it', (
    final tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Practiced'));
    await tester.pumpAndSettle();

    expect(isSelected(tester, 'Practiced'), isTrue);
    expect(isSelected(tester, 'Added'), isFalse);
    expect(prefs.getString('library_sort'), LibrarySort.recentlyPracticed.name);
  });

  testWidgets('opens on the stored sort, not the default', (
    final tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'library_sort': LibrarySort.alphabetical.name,
    });
    prefs = await SharedPreferences.getInstance();

    await pump(tester);

    expect(isSelected(tester, 'A–Z'), isTrue);
    expect(isSelected(tester, 'Added'), isFalse);
  });

  testWidgets('four pills fit a narrow screen without overflowing', (
    final tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pump(tester);

    expect(tester.takeException(), isNull);
  });
}
