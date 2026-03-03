import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/main.dart';
import 'package:breakdex/core/services/settings_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Breakdex integration tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget buildApp() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const BreakdexApp(),
      );
    }

    testWidgets('Add move without video', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap the FAB (+)
      final fab = find.byIcon(Icons.add);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Enter move name
      final nameField = find.byType(TextField).last;
      await tester.enterText(nameField, 'Windmill');
      await tester.pumpAndSettle();

      // Tap Save
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify move appears in list
      expect(find.text('Windmill'), findsOneWidget);
    });

    testWidgets('Navigate to all tabs', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Arsenal tab (default)
      expect(find.text('Moves'), findsOneWidget);

      // Create tab
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(find.text('Create Combo'), findsOneWidget);

      // Review tab
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      // The review screen should render
      expect(find.byType(Scaffold), findsWidgets);

      // Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('Settings — add category', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Tap "Add Category"
      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      // Enter category name in dialog
      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Power Moves');
      await tester.pumpAndSettle();

      // Tap "Add"
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify category appears
      expect(find.text('Power Moves'), findsOneWidget);
    });

    testWidgets('Move detail screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Create a move first
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Headspin');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Tap the move to go to detail
      await tester.tap(find.text('Headspin'));
      await tester.pumpAndSettle();

      // Verify detail screen shows name and state pill
      expect(find.text('Headspin'), findsWidgets);
      expect(find.text('NEW'), findsOneWidget);
    });
  });
}
