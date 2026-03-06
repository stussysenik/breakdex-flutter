import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/main.dart';

import '../test/helpers/test_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Breakdex integration tests', () {
    late SharedPreferences prefs;
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    Widget buildApp() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
        ],
        child: const BreakdexApp(),
      );
    }

    Future<void> seedMove({
      required String id,
      required String name,
      String learningState = 'NEW',
    }) async {
      await db
          .into(db.moves)
          .insert(
            MovesCompanion.insert(
              id: id,
              name: name,
              learningState: Value(learningState),
            ),
          );
    }

    testWidgets('Arsenal renders a seeded move', (tester) async {
      await seedMove(id: 'move-1', name: 'Windmill');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Windmill'), findsOneWidget);
    });

    testWidgets('Navigate to all tabs', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Arsenal'), findsWidgets);

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.text('Session'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);

      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.text('Stats'), findsWidgets);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('Review tab starts a state-based session', (tester) async {
      await seedMove(id: 'move-1', name: 'Windmill');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      expect(find.text('New'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('Mastery'), findsOneWidget);

      await tester.tap(find.text('Start').first);
      await tester.pumpAndSettle();

      expect(find.text('1/1'), findsOneWidget);
      expect(find.text('tap to reveal'), findsOneWidget);
    });

    testWidgets('Settings adds a custom category', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Integration Category');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Integration Category'), findsWidgets);
    });

    testWidgets('Review tab starts a deck session', (tester) async {
      await seedMove(id: 'move-1', name: 'Headspin');
      await db
          .into(db.decks)
          .insert(
            DecksCompanion.insert(
              id: 'deck-1',
              name: 'Battle Set',
              deckType: const Value('manual'),
              sessionSize: const Value(10),
            ),
          );
      await db
          .into(db.deckMoves)
          .insert(
            DeckMovesCompanion.insert(deckId: 'deck-1', moveId: 'move-1'),
          );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deck'));
      await tester.pumpAndSettle();

      expect(find.text('Battle Set'), findsOneWidget);

      await tester.tap(find.text('Battle Set'));
      await tester.pumpAndSettle();

      expect(find.text('1/1'), findsOneWidget);
      expect(find.text('tap to reveal'), findsOneWidget);
    });
  });
}
