import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('silent practice playback provider', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    Future<void> createContainer([
      final Map<String, Object> initialValues = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(initialValues);
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    }

    tearDown(() {
      container.dispose();
    });

    test('loads saved playback preference from shared preferences', () async {
      await createContainer({'silent_practice_playback': true});

      expect(container.read(silentPracticePlaybackProvider), isTrue);
    });

    test('persists toggle updates and reset restores default', () async {
      await createContainer();

      final notifier = container.read(silentPracticePlaybackProvider.notifier);

      await notifier.setEnabled(value: true);

      expect(container.read(silentPracticePlaybackProvider), isTrue);
      expect(prefs.getBool('silent_practice_playback'), isTrue);

      await notifier.reset();

      expect(container.read(silentPracticePlaybackProvider), isFalse);
      expect(prefs.getBool('silent_practice_playback'), isNull);
    });
  });
}
