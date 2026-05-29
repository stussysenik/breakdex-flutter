import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/party/bloc/party_bloc.dart';
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
  Widget buildPartyScreenActive({PartyBloc? bloc}) {
    final effectiveBloc = bloc ?? PartyBloc();
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentTabIndexProvider.overrideWith((_) => 2),
      ],
      child: MaterialApp(
        home: BlocProvider<PartyBloc>.value(
          value: effectiveBloc,
          child: const PartyScreen(),
        ),
      ),
    );
  }

  /// Sends an accelerometer event through the platform channel directly.
  Future<void> sendShake(WidgetTester tester) async {
    final codec = const StandardMethodCodec();
    final now = DateTime.now().microsecondsSinceEpoch;
    for (int i = 0; i < 10; i++) {
      final data = codec.encodeSuccessEnvelope([
        30.0, 0.0, 0.0,
        (now + (i * 100000)).toDouble(), // Add 100ms per event
      ]);
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'dev.fluttercommunity.plus/sensors/user_accel',
        data,
        (ByteData? reply) {},
      );
    }
    // We need to pump enough to let the detector and then the bloc process it
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> cleanupWidget(WidgetTester tester) async {
    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('shows empty state when no moves exist', (tester) async {
    await tester.pumpWidget(buildPartyScreenActive());
    await tester.pumpAndSettle();

    expect(find.text('Party'), findsAtLeast(1));
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
    await tester.pumpAndSettle();

    expect(find.text('Party'), findsAtLeast(1));
    expect(find.text('2 moves ready'), findsOneWidget);
    expect(find.text('Shake to discover\na random move'), findsOneWidget);

    await cleanupWidget(tester);
  });

  testWidgets('shake starts cycling phase with moves in database', (
    tester,
  ) async {
    print('DEBUG: Seeding moves...');
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');
    await seedMove(db, id: 'move-2', name: 'Headspin', category: 'power');

    final bloc = PartyBloc();
    print('DEBUG: Pumping widget...');
    await tester.pumpWidget(buildPartyScreenActive(bloc: bloc));
    await tester.pumpAndSettle();

    print('DEBUG: Sending shake...');
    await sendShake(tester);
    print('DEBUG: Pump 1...');
    await tester.pump(); 
    print('DEBUG: Pump 2...');
    await tester.pump(const Duration(milliseconds: 100));

    print('DEBUG: Checking expectations...');
    expect(find.text('Shuffling...'), findsOneWidget);
    expect(find.text('Discovering your move...'), findsOneWidget);

    print('DEBUG: Cleaning up...');
    await cleanupWidget(tester);
    print('DEBUG: Closing bloc...');
    bloc.close();
    print('DEBUG: Test finished!');
  });

  testWidgets('shake reveals a move after full cycle', (tester) async {
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');

    final bloc = PartyBloc();
    await tester.pumpWidget(buildPartyScreenActive(bloc: bloc));
    await tester.pumpAndSettle();

    await sendShake(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    
    // Cycle duration is 5.5s by default. Fast forward.
    for(int i = 0; i < 20; i++) {
       await tester.pump(const Duration(milliseconds: 300));
    }
    
    await tester.pumpAndSettle(); // Animation of reveal

    expect(find.text('Windmill'), findsOneWidget);
    expect(find.text('Shake again for another move'), findsOneWidget);

    await cleanupWidget(tester);
    await bloc.close();
  });
}
