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

class _EmptyMockStreamHandler extends MockStreamHandler {
  const _EmptyMockStreamHandler();

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    events.success(null);
  }

  @override
  void onCancel(Object? arguments) {}
}

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

    messenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/sensors/accelerometer'),
      const _EmptyMockStreamHandler(),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = createTestDatabase();
  });

  Widget buildPartyScreen() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(home: PartyScreen()),
    );
  }

  /// Close database first, then dispose widget tree to prevent Drift
  /// stream cleanup timer from being detected as a pending timer.
  Future<void> cleanupWidget(WidgetTester tester) async {
    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state when no moves exist', (tester) async {
    await tester.pumpWidget(buildPartyScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Party'), findsOneWidget);
    expect(find.textContaining('Add moves to get the party started'), findsOneWidget);

    await cleanupWidget(tester);
  });

  testWidgets('shows idle phase with move count and shake prompt', (tester) async {
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');
    await seedMove(db, id: 'move-2', name: 'Headspin', category: 'power');

    await tester.pumpWidget(buildPartyScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Party'), findsOneWidget);
    expect(find.text('2 moves ready'), findsOneWidget);
    expect(find.text('Shake to discover\na random move'), findsOneWidget);

    await cleanupWidget(tester);
  });

  testWidgets('settings gear button is present', (tester) async {
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');

    await tester.pumpWidget(buildPartyScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await cleanupWidget(tester);
  });

  testWidgets('single move shows singular label', (tester) async {
    await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');

    await tester.pumpWidget(buildPartyScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('1 move ready'), findsOneWidget);

    await cleanupWidget(tester);
  });
}
