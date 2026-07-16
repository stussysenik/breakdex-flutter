import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    'choice cards stack vertically on phone widths, horizontally when wide',
    (final tester) async {
      Axis choiceAxis() => tester
          .widget<Flex>(find.ancestor(
            of: find.text('Move'),
            matching: find.byType(Flex),
          ).first)
          .direction;

      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;

      tester.view.physicalSize = const Size(390, 844);
      await _pumpAddScreen(tester);
      expect(choiceAxis(), Axis.vertical);

      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpAndSettle();
      expect(choiceAxis(), Axis.horizontal);
    },
  );

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
