import 'package:breakdex/core/config/appwrite_env.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart' show fullBackfillServiceProvider;
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart' show AuthUser;
import 'package:breakdex/core/services/settings_service.dart'
    show sharedPreferencesProvider;
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/backfill/sync_backfill_service.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:breakdex/features/dev/sync_cutover_panel.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Render the panel tall enough that every entity card, the backfill section,
/// and the footer lay out (the panel is a lazy ListView — off-screen children
/// are never built).
void _tallViewport(final WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 4200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Records every push; never touches a real backend.
class _FakeBackend implements SyncBackend {
  int pushes = 0;

  @override
  String get providerType => 'fake';

  @override
  Future<void> push(
    final SyncEntityType type, {
    final List<SyncRecord> upserts = const [],
    final List<SyncTombstone> deletes = const [],
  }) async {
    pushes++;
  }

  @override
  Future<SyncDelta> pull(final SyncEntityType type, {final DateTime? since}) async =>
      const SyncDelta(upserts: [], deletes: []);

  @override
  Stream<SyncDelta> subscribe(final SyncEntityType type) => const Stream.empty();
}

Widget _host(
  final SharedPreferences prefs, {
  final AuthUser? user,
  final SyncBackfillService? backfill,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      // Feed the footer a resolved identity directly — decouples the test from
      // the auth service's session-seeding plumbing.
      currentAppwriteUserProvider.overrideWith((final ref) => Stream.value(user)),
      if (backfill != null)
        fullBackfillServiceProvider.overrideWithValue(backfill),
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

  testWidgets('backfill is disabled while signed out', (final tester) async {
    _tallViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_host(prefs));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('backfill-now')),
    );
    expect(button.onPressed, isNull, reason: 'no session ⇒ no takeover target');
  });

  testWidgets('backfill now runs every entity backfill and reports counts',
      (final tester) async {
    _tallViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final backend = _FakeBackend();
    await tester.pumpWidget(
      _host(
        prefs,
        user: const AuthUser(id: 'dev0', email: 'd@x.io'),
        backfill: SyncBackfillService(
          backend,
          db.movesDao,
          combosDao: db.combosDao,
          reviewsDao: db.reviewsDao,
          decksDao: db.decksDao,
          moveNoteEntriesDao: db.moveNoteEntriesDao,
          comboNoteEntriesDao: db.comboNoteEntriesDao,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('backfill-now')));
    await tester.pumpAndSettle();

    // One report line per backfill step (8: moves, combos, comboMoves,
    // reviews/reviewEvents, decks, deckMoves, both note-entry tables) — an
    // empty DB reports 0 rows everywhere, and 0 rows means 0 pushes reach the
    // backend (nothing fabricated).
    expect(
      find.byWidgetPredicate(
        (final w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('backfill-report-'),
      ),
      findsNWidgets(8),
    );
    expect(find.byKey(const ValueKey('backfill-error')), findsNothing);
    expect(backend.pushes, 0, reason: 'empty DB ⇒ no push calls');
  });

  test('kDevSyncPanelEnabled defaults OFF (byte-identical release guarantee)',
      () {
    // The settings entry is `if (kDevSyncPanelEnabled)`-guarded, so this default
    // is what keeps the panel and its tile out of a shipped binary (design D2).
    expect(kDevSyncPanelEnabled, isFalse);
  });
}
