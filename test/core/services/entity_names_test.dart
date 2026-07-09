import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('entity names provider', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() => container.dispose());

    test('defaults to the product nouns when unset', () {
      final names = container.read(entityNamesProvider);
      expect(names.moveSingular, 'Move');
      expect(names.movePlural, 'Moves');
      expect(names.comboSingular, 'Combo');
      expect(names.comboPlural, 'Combos');
    });

    test('a rename renders app-wide and survives a restart', () async {
      final notifier = container.read(entityNamesProvider.notifier);
      await notifier.rename(EntityNameField.movePlural, 'Tricks');
      await notifier.rename(EntityNameField.moveSingular, 'Trick');

      final names = container.read(entityNamesProvider);
      expect(names.movePlural, 'Tricks');
      expect(names.moveSingular, 'Trick');
      // Untouched forms keep their defaults.
      expect(names.comboPlural, 'Combos');

      // A fresh container reading the same prefs = the restart case.
      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);
      expect(restarted.read(entityNamesProvider).movePlural, 'Tricks');
    });

    test('a blank value clears an override back to default', () async {
      final notifier = container.read(entityNamesProvider.notifier);
      await notifier.rename(EntityNameField.comboPlural, 'Lines');
      expect(container.read(entityNamesProvider).comboPlural, 'Lines');

      await notifier.rename(EntityNameField.comboPlural, '   ');
      expect(container.read(entityNamesProvider).comboPlural, 'Combos');
    });

    test('renaming to the default value stores no override', () async {
      final notifier = container.read(entityNamesProvider.notifier);
      await notifier.rename(EntityNameField.movePlural, 'Moves');
      // No override written when the value equals the default.
      expect(prefs.getString('entity_names'), isNull);
    });

    test('reset restores every noun and clears storage', () async {
      final notifier = container.read(entityNamesProvider.notifier);
      await notifier.rename(EntityNameField.movePlural, 'Tricks');
      await notifier.rename(EntityNameField.comboPlural, 'Lines');

      await notifier.reset();

      final names = container.read(entityNamesProvider);
      expect(names.movePlural, 'Moves');
      expect(names.comboPlural, 'Combos');
      expect(prefs.getString('entity_names'), isNull);
    });

    test('renaming a noun never mutates unrelated stored keys', () async {
      await prefs.setString('some_other_setting', 'keep-me');
      await container
          .read(entityNamesProvider.notifier)
          .rename(EntityNameField.movePlural, 'Tricks');

      expect(prefs.getString('some_other_setting'), 'keep-me');
    });
  });
}
