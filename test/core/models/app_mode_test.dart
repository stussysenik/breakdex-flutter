import 'package:breakdex/core/models/app_mode.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppMode.fromString', () {
    test('a fresh install (absent key) defaults to party', () {
      expect(AppMode.fromString(null), AppMode.party);
      expect(AppMode.fromString('garbage'), AppMode.party);
    });

    test('a persisted choice is honoured — anki never flips to party', () {
      expect(AppMode.fromString('anki'), AppMode.anki);
      expect(AppMode.fromString('party'), AppMode.party);
    });
  });

  group('appModeProvider', () {
    test('fresh install resolves to party', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(appModeProvider), AppMode.party);
    });

    test('an existing user\'s stored anki survives the update (data-safety)',
        () async {
      // Simulates an upgrade: the key was written before party became default.
      SharedPreferences.setMockInitialValues({'app_mode': 'anki'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(appModeProvider), AppMode.anki);
    });
  });
}
