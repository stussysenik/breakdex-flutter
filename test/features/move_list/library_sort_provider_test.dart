import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/move_list/move_list_screen.dart';

/// Builds a container whose SharedPreferences start from [stored], mirroring a
/// launch against an existing preferences file.
Future<ProviderContainer> _containerWith(final Map<String, Object> stored) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('librarySortFromStored', () {
    test('absent value defaults to recentlyAdded (today\'s behavior)', () {
      expect(librarySortFromStored(null), LibrarySort.recentlyAdded);
    });

    test('unknown value falls back rather than throwing', () {
      expect(librarySortFromStored('byVibes'), LibrarySort.recentlyAdded);
    });

    test('every sort resolves from its own persisted name', () {
      for (final sort in LibrarySort.values) {
        expect(librarySortFromStored(sort.name), sort);
      }
    });
  });

  group('librarySortProvider', () {
    test('starts at recentlyAdded when nothing is stored', () async {
      final container = await _containerWith({});
      addTearDown(container.dispose);

      expect(container.read(librarySortProvider), LibrarySort.recentlyAdded);
    });

    test('a stored preference is never overridden by the default', () async {
      final container = await _containerWith({
        'library_sort': LibrarySort.alphabetical.name,
      });
      addTearDown(container.dispose);

      expect(container.read(librarySortProvider), LibrarySort.alphabetical);
    });

    test('an unknown stored value degrades to the default, not a crash', () async {
      final container = await _containerWith({'library_sort': 'byVibes'});
      addTearDown(container.dispose);

      expect(container.read(librarySortProvider), LibrarySort.recentlyAdded);
    });

    test('every sort round-trips through a simulated restart', () async {
      for (final sort in LibrarySort.values) {
        final first = await _containerWith({});
        await first.read(librarySortProvider.notifier).set(sort);
        expect(first.read(librarySortProvider), sort);
        first.dispose();

        // Same backing preferences, fresh container: the next launch.
        final prefs = await SharedPreferences.getInstance();
        final second = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(second.dispose);
        expect(
          second.read(librarySortProvider),
          sort,
          reason: '${sort.name} did not survive restart',
        );
      }
    });
  });
}
