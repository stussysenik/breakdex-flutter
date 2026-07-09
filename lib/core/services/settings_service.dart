import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/add_flow_order.dart';
import '../models/app_mode.dart';

enum ThemeSetting { system, dark, light }

enum ViewingMode { standard, monoOutline }

final sharedPreferencesProvider = Provider<SharedPreferences>((final ref) {
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
    final value = prefs.getString(_key) ?? 'light';
    return ThemeSetting.values.firstWhere(
      (final e) => e.name == value,
      orElse: () => ThemeSetting.light,
    );
  }

  Future<void> set(final ThemeSetting setting) async {
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
      (final e) => e.name == value,
      orElse: () => ViewingMode.standard,
    );
  }

  Future<void> set(final ViewingMode mode) async {
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

final appModeProvider = NotifierProvider<AppModeNotifier, AppMode>(
  AppModeNotifier.new,
);

class AppModeNotifier extends Notifier<AppMode> {
  static const _key = 'app_mode';

  @override
  AppMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppMode.fromString(prefs.getString(_key));
  }

  Future<void> set(final AppMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
    state = mode;
  }
}

final addFlowOrderProvider =
    NotifierProvider<AddFlowOrderNotifier, AddFlowOrder>(
      AddFlowOrderNotifier.new,
    );

class AddFlowOrderNotifier extends Notifier<AddFlowOrder> {
  static const _key = 'add_flow_order';

  @override
  AddFlowOrder build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AddFlowOrder.fromString(prefs.getString(_key));
  }

  Future<void> set(final AddFlowOrder order) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, order.name);
    state = order;
  }
}

final partyCycleDurationMsProvider =
    NotifierProvider<PartyCycleDurationMsNotifier, int>(
      PartyCycleDurationMsNotifier.new,
    );

class PartyCycleDurationMsNotifier extends Notifier<int> {
  static const _key = 'party_cycle_duration_ms';
  static const _defaultMs = 2000;

  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt(_key) ?? _defaultMs;
  }

  Future<void> set(final int ms) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_key, ms);
    state = ms;
  }
}

final partyComboModeProvider =
    NotifierProvider<PartyComboModeNotifier, bool>(
      PartyComboModeNotifier.new,
    );

class PartyComboModeNotifier extends Notifier<bool> {
  static const _key = 'party_combo_mode';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final next = !state;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, next);
    state = next;
  }
}

final useSimplifiedVideoEditorProvider =
    NotifierProvider<UseSimplifiedVideoEditorNotifier, bool>(
      UseSimplifiedVideoEditorNotifier.new,
    );

class UseSimplifiedVideoEditorNotifier extends Notifier<bool> {
  static const _key = 'use_simplified_video_editor';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final next = !state;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, next);
    state = next;
  }
}

final fsrsEnabledProvider = NotifierProvider<FsrsEnabledNotifier, bool>(
  FsrsEnabledNotifier.new,
);

class FsrsEnabledNotifier extends Notifier<bool> {
  static const _key = 'fsrs_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? true;
  }

  Future<void> set({required final bool enabled}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, enabled);
    state = enabled;
  }
}

final quietModeEnabledProvider = NotifierProvider<QuietModeEnabledNotifier, bool>(
  QuietModeEnabledNotifier.new,
);

class QuietModeEnabledNotifier extends Notifier<bool> {
  static const _key = 'quiet_mode_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> set({required final bool enabled}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, enabled);
    state = enabled;
  }
}

final showStatsTabProvider = NotifierProvider<ShowStatsTabNotifier, bool>(
  ShowStatsTabNotifier.new,
);

class ShowStatsTabNotifier extends Notifier<bool> {
  static const _key = 'show_stats_tab';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final next = !state;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, next);
    state = next;
  }
}

