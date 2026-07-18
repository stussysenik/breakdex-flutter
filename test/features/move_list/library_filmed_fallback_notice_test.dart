import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/move_list/move_list_screen.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// Pumps the disclosure on its own — the screen around it reads live Drift
/// streams, which flake widget tests. Sort and segment are parameters rather
/// than provider reads precisely so this can be a pure pump.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(
    final WidgetTester tester, {
    required final LibrarySort sort,
    required final ArsenalSegment segment,
  }) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: LibraryFilmedFallbackNotice(sort: sort, segment: segment),
            ),
          ),
        ),
      );

  final notice = find.textContaining('have no filmed date');

  testWidgets('discloses the fallback on the combo tab under a filmed sort', (
    final tester,
  ) async {
    await pump(
      tester,
      sort: LibrarySort.recentlyFilmed,
      segment: ArsenalSegment.combos,
    );

    expect(notice, findsOneWidget);
    // The disclosure names the fallback, not just the absence — a user who
    // arrived here via the global sort needs to know what order they're seeing.
    expect(find.textContaining('most recently added'), findsOneWidget);
  });

  testWidgets('stays silent on the moves tab, where filmed dates are real', (
    final tester,
  ) async {
    await pump(
      tester,
      sort: LibrarySort.recentlyFilmed,
      segment: ArsenalSegment.moves,
    );

    expect(notice, findsNothing);
  });

  testWidgets('stays silent for every sort a combo can honestly answer', (
    final tester,
  ) async {
    for (final sort in LibrarySort.values.where(
      (final s) => s != LibrarySort.recentlyFilmed,
    )) {
      await pump(tester, sort: sort, segment: ArsenalSegment.combos);
      expect(notice, findsNothing, reason: 'unexpected notice under $sort');
    }
  });

  testWidgets('uses the configured combo noun, not a hardcoded "Combos"', (
    final tester,
  ) async {
    await pump(
      tester,
      sort: LibrarySort.recentlyFilmed,
      segment: ArsenalSegment.combos,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryFilmedFallbackNotice)),
    );
    await container
        .read(entityNamesProvider.notifier)
        .rename(EntityNameField.comboPlural, 'Sequences');
    await tester.pump();

    expect(find.textContaining('Sequences have no filmed date'), findsOneWidget);
  });
}
