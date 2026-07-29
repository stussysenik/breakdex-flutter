import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/add/add_screen.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// Any text node longer than this reads as a helper/instructional sentence
/// rather than an interface label. The Add surface is chrome — its choices
/// must be visual anchors + single short labels (visual-first-surfaces spec).
const _paragraphThreshold = 24;

Future<void> _pumpAddScreen(final WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'content band starts at the same y regardless of viewport width',
    (final tester) async {
      // The stacked-viewport invariant: bands 1/2/4 never move, so the first
      // content pixel is always headerHeight + contentTopGap below the safe
      // area. A screen whose content shifts with width has left the frame.
      double firstContentTop() =>
          tester.getTopLeft(find.byKey(const Key('add-choices'))).dy;

      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      const expected = AppLayout.headerHeight + AppLayout.contentTopGap;

      tester.view.physicalSize = const Size(390, 844);
      await _pumpAddScreen(tester);
      expect(firstContentTop(), expected);

      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpAndSettle();
      expect(firstContentTop(), expected);
    },
  );

  testWidgets('content column is clamped to a readable measure', (
    final tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1600, 900);

    await _pumpAddScreen(tester);

    final width = tester.getSize(find.byKey(const Key('add-choices'))).width;
    expect(width, AppLayout.maxContentWidth - (AppLayout.gutter * 2));
  });

  testWidgets('choice rows land on the block grid', (final tester) async {
    await _pumpAddScreen(tester);

    final cards = find.descendant(
      of: find.byKey(const Key('add-choices')),
      matching: find.byType(InkWell),
    );
    expect(cards, findsNWidgets(2));

    for (var i = 0; i < 2; i++) {
      final height = tester.getSize(cards.at(i)).height;
      expect(
        height % AppLayout.blockGrid,
        0,
        reason: 'choice card $i is off the block grid at ${height}px',
      );
    }
  });

  testWidgets(
    'Add tab presents visual anchors with no paragraph-style helper text',
    (final tester) async {
      await _pumpAddScreen(tester);

      // Each create choice is reachable by a single short label + anchor.
      expect(find.text('Move'), findsOneWidget);
      expect(find.text('Combo'), findsOneWidget);

      // No paragraph-style helper text renders on the Add surface: every
      // Text node is a short label/anchor, never an instructional sentence.
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final data = text.data ?? '';
        expect(
          data.length,
          lessThanOrEqualTo(_paragraphThreshold),
          reason: 'Paragraph-style text on the Add surface: "$data"',
        );
      }
    },
  );
}
