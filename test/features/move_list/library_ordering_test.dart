import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/move_list/move_list_screen.dart';

/// Drives the library's derivation providers against a real in-memory database
/// — the same path the screen reads — without pumping a widget, since live
/// Drift streams flake widget tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  DateTime day(final int d) => DateTime.utc(2026, 3, d);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      // Local-only: keeps the repository off the sync-aware decorator, whose
      // Appwrite client needs platform channels no unit test has.
      isLoggedInProvider.overrideWithValue(false),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Reads a derivation provider once its stream has delivered [expected] rows.
  Future<List<T>> settled<T>(
    final ProviderListenable<AsyncValue<List<T>>> provider,
    final int expected,
  ) async {
    final sub = container.listen(provider, (final _, final _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 50; i++) {
      final value = sub.read().valueOrNull;
      if (value != null && value.length == expected) return value;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('provider never settled on $expected rows');
  }

  Future<void> setSort(final LibrarySort sort) =>
      container.read(librarySortProvider.notifier).set(sort);

  group('libraryMovesProvider', () {
    setUp(() async {
      // Dates are chosen so all four sorts produce four *different* orders,
      // none of them the feed's own `createdAt DESC`. A sort that silently
      // did nothing — or read the wrong dimension — cannot pass by accident.
      for (final (id, name, created, filmed, updated) in [
        ('a', 'Alpha', day(1), day(9), day(2)),
        ('b', 'Charlie', day(5), day(3), day(1)),
        ('c', 'Bravo', day(3), day(1), day(9)),
      ]) {
        await db.into(db.moves).insert(MovesCompanion.insert(
              id: id,
              name: name,
              createdAt: Value(created),
              videoCreationDate: Value(filmed),
              updatedAt: Value(updated),
            ));
      }
    });

    test('defaults to recently added — newest first', () async {
      final moves = await settled(libraryMovesProvider, 3);
      expect(moves.map((final m) => m.id), ['b', 'c', 'a']);
    });

    test('recently filmed reorders by capture date, not added date', () async {
      await setSort(LibrarySort.recentlyFilmed);
      final moves = await settled(libraryMovesProvider, 3);
      expect(moves.map((final m) => m.id), ['a', 'b', 'c']);
    });

    test('recently practiced reorders by last edit', () async {
      await setSort(LibrarySort.recentlyPracticed);
      final moves = await settled(libraryMovesProvider, 3);
      expect(moves.map((final m) => m.id), ['c', 'a', 'b']);
    });

    test('alphabetical ignores every date', () async {
      await setSort(LibrarySort.alphabetical);
      final moves = await settled(libraryMovesProvider, 3);
      expect(moves.map((final m) => m.name), ['Alpha', 'Bravo', 'Charlie']);
    });
  });

  group('libraryCombosProvider', () {
    setUp(() async {
      // The edited combo is the *oldest* by added date, so it can only outrank
      // the untouched one if its edit is actually read — which is the whole
      // point of hydrating `updatedAt`.
      for (final (id, name, created) in [
        ('c-jotted', 'Jotted', day(1)),
        ('c-edited', 'Edited', day(1)),
        ('c-untouched', 'Untouched', day(3)),
      ]) {
        await db.into(db.combos).insert(CombosCompanion.insert(
              id: id,
              name: name,
              createdAt: Value(created),
            ));
      }
      await (db.update(db.combos)..where((final t) => t.id.equals('c-edited')))
          .write(CombosCompanion(updatedAt: Value(day(5))));
      await db.comboNoteEntriesDao.addEntry(
        id: 'e1',
        comboId: 'c-jotted',
        body: 'landed it',
      );
    });

    test('defaults to recently added — equal dates break by name', () async {
      final combos = await settled(libraryCombosProvider, 3);
      expect(combos.map((final c) => c.combo.name),
          ['Untouched', 'Edited', 'Jotted']);
    });

    test(
        'recently practiced ranks jotted over edited over untouched — the '
        'edited combo is only distinguishable because watchLibraryRows now '
        'hydrates updatedAt', () async {
      await setSort(LibrarySort.recentlyPracticed);
      final combos = await settled(libraryCombosProvider, 3);
      expect(combos.map((final c) => c.combo.id),
          ['c-jotted', 'c-edited', 'c-untouched']);
    });

    test(
        'recently filmed falls back to added order — a combo has no capture '
        'date and does not borrow one from its edits or jots', () async {
      await setSort(LibrarySort.recentlyFilmed);
      final combos = await settled(libraryCombosProvider, 3);
      // Identical to the added order, and deliberately *not* the practiced
      // order — a fallback that leaked to updatedAt/lastEntryAt reds here.
      expect(combos.map((final c) => c.combo.name),
          ['Untouched', 'Edited', 'Jotted']);
    });

    test('watchLibraryRows carries updatedAt for edited combos', () async {
      final combos = await settled(libraryCombosProvider, 3);
      final edited =
          combos.firstWhere((final c) => c.combo.id == 'c-edited').combo;
      expect(edited.updatedAt?.toUtc(), day(5));
    });
  });
}
