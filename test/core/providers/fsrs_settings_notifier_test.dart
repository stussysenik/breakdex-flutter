import 'package:breakdex/core/models/fsrs_settings.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FsrsSettingsNotifier', () {
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

    test('seeds from defaults when prefs are empty', () {
      expect(container.read(fsrsSettingsProvider), FsrsSettings.defaults);
    });

    test('setDesiredRetention persists and updates state', () async {
      await container
          .read(fsrsSettingsProvider.notifier)
          .setDesiredRetention(0.90);

      expect(container.read(fsrsSettingsProvider).desiredRetention, 0.90);
      expect(prefs.getDouble('fsrs.desiredRetention'), 0.90);

      // A fresh container backed by the same prefs reloads the edit.
      final reloaded = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(reloaded.dispose);
      expect(reloaded.read(fsrsSettingsProvider).desiredRetention, 0.90);
    });

    test('setDesiredRetention clamps out-of-range input before persisting',
        () async {
      await container
          .read(fsrsSettingsProvider.notifier)
          .setDesiredRetention(0.50); // below the 0.70 floor

      expect(container.read(fsrsSettingsProvider).desiredRetention, 0.70);
      expect(prefs.getDouble('fsrs.desiredRetention'), 0.70);
    });

    test('setMaximumInterval floors at 1', () async {
      await container
          .read(fsrsSettingsProvider.notifier)
          .setMaximumInterval(0);

      expect(container.read(fsrsSettingsProvider).maximumInterval, 1);
    });

    test('setFuzzing toggles and persists', () async {
      await container
          .read(fsrsSettingsProvider.notifier)
          .setFuzzing(enabled: false);

      expect(container.read(fsrsSettingsProvider).enableFuzzing, false);
      expect(prefs.getBool('fsrs.enableFuzzing'), false);
    });

    test('step setters sanitize negatives and persist as minutes', () async {
      await container.read(fsrsSettingsProvider.notifier).setLearningSteps(
        const [Duration(minutes: -1), Duration(minutes: 1), Duration(minutes: 10)],
      );

      expect(
        container.read(fsrsSettingsProvider).learningSteps,
        const [Duration(minutes: 1), Duration(minutes: 10)],
      );
      expect(prefs.getStringList('fsrs.learningSteps'), ['1', '10']);
    });

    test('resetToDefaults restores the constants and persists them', () async {
      final notifier = container.read(fsrsSettingsProvider.notifier);
      await notifier.setDesiredRetention(0.95);
      await notifier.setFuzzing(enabled: false);

      await notifier.resetToDefaults();

      expect(container.read(fsrsSettingsProvider), FsrsSettings.defaults);
      expect(prefs.getDouble('fsrs.desiredRetention'), 0.85);
      expect(prefs.getBool('fsrs.enableFuzzing'), true);
    });
  });
}
