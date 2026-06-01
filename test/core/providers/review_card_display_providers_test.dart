import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('review card display settings provider', () {
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

    test('loads saved visibility toggles from shared preferences', () async {
      await createContainer({
        'review_card_show_title': false,
        'review_card_show_state': true,
        'review_card_show_category': false,
        'review_card_show_combo_timeline': true,
        'review_card_show_combo_step_name': false,
        'review_card_show_playback_controls': false,
      });

      final settings = container.read(reviewCardDisplaySettingsProvider);

      expect(settings.showTitle, isFalse);
      expect(settings.showState, isTrue);
      expect(settings.showCategory, isFalse);
      expect(settings.showComboTimeline, isTrue);
      expect(settings.showComboStepName, isFalse);
      expect(settings.showPlaybackControls, isFalse);
    });

    test('persists toggle updates and reset restores defaults', () async {
      await createContainer();

      final notifier = container.read(
        reviewCardDisplaySettingsProvider.notifier,
      );

      await notifier.setShowTitle(value: false);
      await notifier.setShowPlaybackControls(value: false);

      var settings = container.read(reviewCardDisplaySettingsProvider);
      expect(settings.showTitle, isFalse);
      expect(settings.showPlaybackControls, isFalse);
      expect(prefs.getBool('review_card_show_title'), isFalse);
      expect(prefs.getBool('review_card_show_playback_controls'), isFalse);

      await notifier.reset();

      settings = container.read(reviewCardDisplaySettingsProvider);
      expect(settings.showTitle, isTrue);
      expect(settings.showPlaybackControls, isTrue);
      expect(prefs.getBool('review_card_show_title'), isNull);
      expect(prefs.getBool('review_card_show_playback_controls'), isNull);
    });
  });
}
