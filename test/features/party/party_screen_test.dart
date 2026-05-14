import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/features/party/party_screen.dart';

import '../../helpers/test_database.dart';
import '../../helpers/test_data.dart';

void main() {
  late AppDatabase db;

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
    db = createTestDatabase();
  });

  // Provide tab index=3 so the shake listener starts (party tab active).
  Widget buildPartyScreenActive() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        currentTabIndexProvider.overrideWith((_) => 3),
      ],
      child: const MaterialApp(home: PartyScreen()),
    );
  }

  /// Sends an accelerometer event through the platform channel directly.
  Future<void> sendShake(WidgetTester tester) async {
    final codec = const StandardMethodCodec();
    final data = codec.encodeSuccessEnvelope([
      25.0, 0.0, 0.0,
      DateTime.now().microsecondsSinceEpoch.toDouble(),
    ]);
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'dev.fluttercommunity.plus/sensors/accelerometer',
      data,
      (ByteData? reply) {},
    );
    await tester.pump(const Duration(milliseconds: 50));
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

  testWidgets('settings gear button is present', (tester) async {
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');

    await tester.pumpWidget(buildPartyScreenActive());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

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
