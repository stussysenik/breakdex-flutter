part of '../providers.dart';

final silentPracticePlaybackProvider =
    NotifierProvider<SilentPracticePlaybackNotifier, bool>(
      SilentPracticePlaybackNotifier.new,
    );

class SilentPracticePlaybackNotifier extends Notifier<bool> {
  static const _key = 'silent_practice_playback';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled({required final bool value}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, value);
    state = value;
  }

  Future<void> toggle() => setEnabled(value: !state);

  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_key);
    state = false;
  }
}
