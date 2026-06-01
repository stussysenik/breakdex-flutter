part of '../providers.dart';

final reviewCardDisplaySettingsProvider = NotifierProvider<
  ReviewCardDisplaySettingsNotifier,
  ReviewCardDisplaySettings
>(ReviewCardDisplaySettingsNotifier.new);

class ReviewCardDisplaySettingsNotifier
    extends Notifier<ReviewCardDisplaySettings> {
  static const _showTitleKey = 'review_card_show_title';
  static const _showStateKey = 'review_card_show_state';
  static const _showCategoryKey = 'review_card_show_category';
  static const _showComboTimelineKey = 'review_card_show_combo_timeline';
  static const _showComboStepNameKey = 'review_card_show_combo_step_name';
  static const _showPlaybackControlsKey =
      'review_card_show_playback_controls';

  @override
  ReviewCardDisplaySettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ReviewCardDisplaySettings(
      showTitle: prefs.getBool(_showTitleKey) ?? true,
      showState: prefs.getBool(_showStateKey) ?? true,
      showCategory: prefs.getBool(_showCategoryKey) ?? true,
      showComboTimeline: prefs.getBool(_showComboTimelineKey) ?? true,
      showComboStepName: prefs.getBool(_showComboStepNameKey) ?? true,
      showPlaybackControls: prefs.getBool(_showPlaybackControlsKey) ?? true,
    );
  }

  Future<void> setShowTitle({required final bool value}) =>
      _setBool(_showTitleKey, value, (final settings) {
        return settings.copyWith(showTitle: value);
      });

  Future<void> setShowState({required final bool value}) =>
      _setBool(_showStateKey, value, (final settings) {
        return settings.copyWith(showState: value);
      });

  Future<void> setShowCategory({required final bool value}) =>
      _setBool(_showCategoryKey, value, (final settings) {
        return settings.copyWith(showCategory: value);
      });

  Future<void> setShowComboTimeline({required final bool value}) =>
      _setBool(_showComboTimelineKey, value, (final settings) {
        return settings.copyWith(showComboTimeline: value);
      });

  Future<void> setShowComboStepName({required final bool value}) =>
      _setBool(_showComboStepNameKey, value, (final settings) {
        return settings.copyWith(showComboStepName: value);
      });

  Future<void> setShowPlaybackControls({required final bool value}) =>
      _setBool(_showPlaybackControlsKey, value, (final settings) {
        return settings.copyWith(showPlaybackControls: value);
      });

  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    for (final key in [
      _showTitleKey,
      _showStateKey,
      _showCategoryKey,
      _showComboTimelineKey,
      _showComboStepNameKey,
      _showPlaybackControlsKey,
    ]) {
      await prefs.remove(key);
    }
    state = ReviewCardDisplaySettings.defaults;
  }

  Future<void> _setBool(
    final String key,
    final bool value,
    final ReviewCardDisplaySettings Function(ReviewCardDisplaySettings settings)
    update,
  ) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(key, value);
    state = update(state);
  }
}
