import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/party/party_screen.dart';

import '../../helpers/test_database.dart';
import '../../helpers/test_data.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    final messenger = TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
      (call) async => null,
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = createTestDatabase();
  });

  // Provide tab index=2 so the shake listener starts (review tab active).
  Widget buildPartyScreenActive() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentTabIndexProvider.overrideWith((_) => 2),
      ],
      child: const MaterialApp(home: PartyScreen()),
    );
  }

  /// Sends an accelerometer event through the platform channel directly.
  Future<void> sendShake(WidgetTester tester) async {
    final codec = const StandardMethodCodec();
    final now = DateTime.now().microsecondsSinceEpoch;
    for (int i = 0; i < 5; i++) {
      final data = codec.encodeSuccessEnvelope([
        25.0, 0.0, 0.0,
        (now + (i * 100000)).toDouble(), // Add 100ms per event
      ]);
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'dev.fluttercommunity.plus/sensors/user_accel',
        data,
        (ByteData? reply) {},
      );
    }
    await tester.pump(const Duration(milliseconds: 550));
  }

  Future<void> cleanupWidget(WidgetTester tester) async {
    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state when no moves exist', (tester) async {
    await tester.pumpWidget(buildPartyScreenActive());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Party'), findsOneWidget);
    expect(
      find.textContaining('Add moves to get the party started'),
      findsOneWidget,
    );

    await cleanupWidget(tester);
  });

  testWidgets('shows idle phase with move count and shake prompt', (
    tester,
  ) async {
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');
    await seedMove(db, id: 'move-2', name: 'Headspin', category: 'power');

    await tester.pumpWidget(buildPartyScreenActive());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Party'), findsOneWidget);
    expect(find.text('2 moves ready'), findsOneWidget);
    expect(find.text('Shake to discover\na random move'), findsOneWidget);

    await cleanupWidget(tester);
  });

  testWidgets('single move shows singular label', (tester) async {
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');

    await tester.pumpWidget(buildPartyScreenActive());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('1 move ready'), findsOneWidget);

    await cleanupWidget(tester);
  });

  testWidgets('shake does nothing when tab is not party (index != 3)', (
    tester,
  ) async {
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentTabIndexProvider.overrideWith((_) => 0),
        ],
        child: const MaterialApp(home: PartyScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Shake to discover\na random move'), findsOneWidget);

    await sendShake(tester);

    // Should still show idle prompt — shake was ignored
    expect(find.text('Shake to discover\na random move'), findsOneWidget);
    expect(find.text('Shuffling...'), findsNothing);

    await cleanupWidget(tester);
  });

  testWidgets('shake starts cycling phase with moves in database', (
    tester,
  ) async {
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');
    await seedMove(db, id: 'move-2', name: 'Headspin', category: 'power');
    await seedMove(db, id: 'move-3', name: 'Flare', category: 'power');

    await tester.pumpWidget(buildPartyScreenActive());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('3 moves ready'), findsOneWidget);

    await sendShake(tester);

    expect(find.text('Shake to discover\na random move'), findsNothing);
    expect(find.text('Discovering your move...'), findsOneWidget);
    expect(find.text('Shuffling...'), findsOneWidget);

    await cleanupWidget(tester);
  });

  testWidgets('shake reveals a move after full cycle', (tester) async {
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');
    await seedMove(db, id: 'move-2', name: 'Headspin', category: 'power');

    await tester.pumpWidget(buildPartyScreenActive());
    await tester.pump(const Duration(milliseconds: 500));

    await sendShake(tester);
    expect(find.text('Shuffling...'), findsOneWidget);

    // Fast-forward past cycle + reveal + lockout
    await tester.pump(const Duration(seconds: 10));

    // A seeded move name should appear in the revealed card
    final moveName = find.text('Windmill');
    final otherName = find.text('Headspin');
    expect(
      moveName.evaluate().isNotEmpty || otherName.evaluate().isNotEmpty,
      isTrue,
    );

    await cleanupWidget(tester);
  });

  testWidgets('shake does nothing when no moves exist', (tester) async {
    await tester.pumpWidget(buildPartyScreenActive());
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.textContaining('Add moves to get the party started'),
      findsOneWidget,
    );

    await sendShake(tester);

    expect(
      find.textContaining('Add moves to get the party started'),
      findsOneWidget,
    );
    expect(find.text('Shuffling...'), findsNothing);

    await cleanupWidget(tester);
  });

  testWidgets('second shake during cycle is ignored (shakeLocked)', (
    tester,
  ) async {
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');
    await seedMove(db, id: 'move-2', name: 'Headspin', category: 'power');

    await tester.pumpWidget(buildPartyScreenActive());
    await tester.pump(const Duration(milliseconds: 500));

    await sendShake(tester);
    expect(find.text('Shuffling...'), findsOneWidget);

    // Second shake within cooldown — should be ignored
    await sendShake(tester);
    expect(find.text('Shuffling...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));

    final moveName = find.text('Windmill');
    final otherName = find.text('Headspin');
    expect(
      moveName.evaluate().isNotEmpty || otherName.evaluate().isNotEmpty,
      isTrue,
    );

    await cleanupWidget(tester);
  });
}
