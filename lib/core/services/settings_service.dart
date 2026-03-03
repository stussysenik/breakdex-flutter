import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSetting { system, dark, light }

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main');
});

final themeSettingProvider =
    NotifierProvider<ThemeSettingNotifier, ThemeSetting>(
  ThemeSettingNotifier.new,
);

class ThemeSettingNotifier extends Notifier<ThemeSetting> {
  static const _key = 'theme_setting';

  @override
  ThemeSetting build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = prefs.getString(_key) ?? 'system';
    return ThemeSetting.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeSetting.system,
    );
  }

  Future<void> set(ThemeSetting setting) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, setting.name);
    state = setting;
  }
}

extension ThemeSettingX on ThemeSetting {
  ThemeMode get themeMode => switch (this) {
        ThemeSetting.system => ThemeMode.system,
        ThemeSetting.dark => ThemeMode.dark,
        ThemeSetting.light => ThemeMode.light,
      };

  String get displayName => switch (this) {
        ThemeSetting.system => 'System',
        ThemeSetting.dark => 'Dark',
        ThemeSetting.light => 'Light',
      };
}
