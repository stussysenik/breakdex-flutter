import 'package:breakdex/core/config/appwrite_env.dart';
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart' show AuthUser;
import 'package:breakdex/core/services/settings_service.dart'
    show sharedPreferencesProvider;
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/features/dev/sync_cutover_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Render the panel tall enough that every entity card + the footer lays out
/// (the panel is a lazy ListView — off-screen children are never built).
void _tallViewport(final WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host(
  final SharedPreferences prefs, {
  final AuthUser? user,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      // Feed the footer a resolved identity directly — decouples the test from
      // the auth service's session-seeding plumbing.
      currentAppwriteUserProvider.overrideWith((final ref) => Stream.value(user)),
    ],
    child: const MaterialApp(home: SyncCutoverPanel()),
  );
}

void main() {
  const movesWrite = SyncService.movesDualWritePrefKey;
  const movesRead = SyncService.movesDualReadPrefKey;
  const combosWrite = SyncService.combosDualWritePrefKey;

  testWidgets('a toggle flips exactly its pref key and nothing else',
      (final tester) async {
    _tallViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_host(prefs));
    await tester.pumpAndSettle();

    expect(prefs.getBool(movesWrite) ?? false, isFalse);

    await tester.tap(find.byKey(const ValueKey(movesWrite)));
    await tester.pumpAndSettle();

    // Exactly the moves dual-write pref flipped on.
    expect(prefs.getBool(movesWrite), isTrue);
    // No neighbouring pref was touched.
    expect(prefs.getBool(movesRead), isNull);
    expect(prefs.getBool(combosWrite), isNull);
  });

  testWidgets('re-opening the panel reflects the persisted pref value',
      (final tester) async {
    _tallViewport(tester);
    SharedPreferences.setMockInitialValues({movesRead: true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_host(prefs));
    await tester.pumpAndSettle();

    final readSwitch =
        tester.widget<Switch>(find.byKey(const ValueKey(movesRead)));
    expect(readSwitch.value, isTrue, reason: 'persisted true should render on');
  });

  testWidgets('read-only entities (fsrs) expose no dual-write switch',
      (final tester) async {
    _tallViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_host(prefs));
    await tester.pumpAndSettle();

    // fsrsCards has a dual-read switch but no dual-write pref/switch.
    expect(
      find.byKey(const ValueKey(SyncService.fsrsCardsDualReadPrefKey)),
      findsOneWidget,
    );
  });

  testWidgets('identity footer names the signed-in user', (final tester) async {
    _tallViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      _host(prefs, user: const AuthUser(id: 'dev0', email: 'd@x.io')),
    );
    await tester.pumpAndSettle();

    final footer = tester.widget<Text>(
      find.byKey(const ValueKey('sync-cutover-identity')),
    );
    expect(footer.data, contains('dev0'));
    expect(footer.data, contains('d@x.io'));
  });

  test('kDevSyncPanelEnabled defaults OFF (byte-identical release guarantee)',
      () {
    // The settings entry is `if (kDevSyncPanelEnabled)`-guarded, so this default
    // is what keeps the panel and its tile out of a shipped binary (design D2).
    expect(kDevSyncPanelEnabled, isFalse);
  });
}
