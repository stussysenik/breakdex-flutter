import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/add/add_screen.dart';

/// Any text node longer than this reads as a helper/instructional sentence
/// rather than an interface label. The Add surface is chrome — its choices
/// must be visual anchors + single short labels (visual-first-surfaces spec).
const _paragraphThreshold = 24;

void main() {
  testWidgets(
    'Add tab presents visual anchors with no paragraph-style helper text',
    (final tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: AddScreen()),
        ),
      );

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
