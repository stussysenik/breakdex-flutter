import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/navigation/morph_page.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/add/add_screen.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/app_morph.dart';
import 'package:breakdex/shared/widgets/app_row.dart';

/// The Add row that opens `/create-combo` does not hand off to the screen — it
/// *becomes* it. This proves the shape actually travels: mid-flight there is one
/// surface, at neither end's size.
///
/// The destination here is a stub, not `CreateComboScreen`: what is under test
/// is the seam (source end on the row, destination end in [morphPage]), and the
/// real screen would drag the whole data graph into a motion test.
///
/// The source lives inside a nested `Navigator` and the route is pushed on the
/// root one, because that is the production topology — Add is a shell branch,
/// `/create-combo` is a root route. A flight that only works in a flat navigator
/// would pass a simpler test and do nothing in the app.

final _rootKey = GlobalKey<NavigatorState>();

Widget _stubComboScreen() => const ColoredBox(
  color: Color(0xFF101010),
  child: Center(child: Text('stub', textDirection: TextDirection.ltr)),
);

Future<void> _pumpApp(final WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/add',
    routes: [
      ShellRoute(
        builder: (final context, final state, final child) => child,
        routes: [
          GoRoute(
            path: '/add',
            builder: (final context, final state) => const AddScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/create-combo',
        parentNavigatorKey: _rootKey,
        pageBuilder: (final context, final state) => morphPage<Object?>(
          key: state.pageKey,
          identifier: createComboMorphId,
          child: _stubComboScreen(),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Rows are addressed by their driver identifier, not by text — labels are
/// entity-name-configurable.
final _comboRow = find.byWidgetPredicate(
  (final w) => w is AppRow && w.identifier == 'add-combo-card',
);

void main() {
  final surface = find.byKey(AppMorph.surfaceKey(createComboMorphId));

  testWidgets('the combo row carries the source end of the flight', (
    final tester,
  ) async {
    await _pumpApp(tester);
    // At rest the surface sits behind the row and is exactly its size — the
    // row is what travels, not some decoration next to it.
    expect(surface, findsOneWidget);
    expect(
      tester.getRect(surface),
      tester.getRect(_comboRow),
    );
  });

  testWidgets('tapping it morphs the row into the page', (
    final tester,
  ) async {
    await _pumpApp(tester);
    final from = tester.getRect(surface);
    final page = tester.getRect(find.byType(MaterialApp));

    await tester.tap(_comboRow);
    await tester.pump();
    await tester.pump(AppMotion.moderate02 ~/ 6);

    // One surface, not two: both route ends render a placeholder while the
    // shuttle flies, so a second hit here means nothing was handed over.
    expect(surface, findsOneWidget);
    final mid = tester.getRect(surface);
    expect(
      mid.height,
      greaterThan(from.height),
      reason: 'the shape never left the row',
    );
    expect(
      mid.height,
      lessThan(page.height),
      reason: 'the shape did not travel — it was already the page',
    );

    await tester.pumpAndSettle();
    expect(tester.getRect(surface), page);
  });
}
