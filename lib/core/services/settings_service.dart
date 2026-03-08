import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSetting { system, dark, light }

enum ViewingMode { standard, monoOutline }

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

final viewingModeProvider = NotifierProvider<ViewingModeNotifier, ViewingMode>(
  ViewingModeNotifier.new,
);

class ViewingModeNotifier extends Notifier<ViewingMode> {
  static const _key = 'viewing_mode';

  @override
  ViewingMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = prefs.getString(_key) ?? ViewingMode.standard.name;
    return ViewingMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ViewingMode.standard,
    );
  }

  Future<void> set(ViewingMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
    state = mode;
  }
}

extension ViewingModeX on ViewingMode {
  String get displayName => switch (this) {
    ViewingMode.standard => 'Blue',
    ViewingMode.monoOutline => 'Marker',
  };
}
