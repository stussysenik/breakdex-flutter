part of '../providers.dart';

// ---------------------------------------------------------------------------
// Font family — persisted in SharedPreferences
// ---------------------------------------------------------------------------

final fontFamilyProvider =
    NotifierProvider<FontFamilyNotifier, AppFontFamily>(FontFamilyNotifier.new);

class FontFamilyNotifier extends Notifier<AppFontFamily> {
  static const _key = 'font_family';

  @override
  AppFontFamily build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppFontFamily.fromKey(prefs.getString(_key));
  }

  Future<void> set(AppFontFamily family) async {
    state = family;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, family.key);
  }
}

// ---------------------------------------------------------------------------
// Accent color — user-configurable global accent (defaults to AppColors.accent)
// ---------------------------------------------------------------------------

final accentColorProvider =
    NotifierProvider<AccentColorNotifier, Color>(AccentColorNotifier.new);

/// Persists custom accent color in SharedPreferences as an ARGB int.
/// The theme watches this provider so changing it updates the entire UI.
class AccentColorNotifier extends Notifier<Color> {
  static const _key = 'accent_color';

  @override
  Color build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final v = prefs.getInt(_key);
    return v != null ? Color(v) : AppColors.accent;
  }

  Future<void> set(Color color) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_key, color.toARGB32());
    state = color;
  }

  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_key);
    state = AppColors.accent;
  }
}

// ---------------------------------------------------------------------------
// Rating colors — configurable per-rating button colors
// ---------------------------------------------------------------------------

/// Immutable snapshot of the four rating colors.
class RatingColors {
  final Color again;
  final Color hard;
  final Color good;
  final Color easy;

  const RatingColors({
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });

  static const defaults = RatingColors(
    again: AppColors.actionAgain,
    hard: AppColors.actionHard,
    good: AppColors.actionGood,
    easy: AppColors.actionEasy,
  );

  /// Look up the color for a given rating name (AGAIN, HARD, GOOD, EASY).
  Color forName(String name) => switch (name) {
        'AGAIN' => again,
        'HARD' => hard,
        'GOOD' => good,
        'EASY' => easy,
        _ => again,
      };
}

final ratingColorsProvider =
    NotifierProvider<RatingColorsNotifier, RatingColors>(
  RatingColorsNotifier.new,
);

/// Persists custom rating colors in SharedPreferences as ARGB hex ints.
class RatingColorsNotifier extends Notifier<RatingColors> {
  static const _prefix = 'rating_color_';

  @override
  RatingColors build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return RatingColors(
      again: _read(prefs, 'again', AppColors.actionAgain),
      hard: _read(prefs, 'hard', AppColors.actionHard),
      good: _read(prefs, 'good', AppColors.actionGood),
      easy: _read(prefs, 'easy', AppColors.actionEasy),
    );
  }

  Color _read(SharedPreferences prefs, String key, Color fallback) {
    final v = prefs.getInt('$_prefix$key');
    return v != null ? Color(v) : fallback;
  }

  Future<void> setColor(String key, Color color) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('$_prefix$key', color.toARGB32());
    state = RatingColors(
      again: key == 'again' ? color : state.again,
      hard: key == 'hard' ? color : state.hard,
      good: key == 'good' ? color : state.good,
      easy: key == 'easy' ? color : state.easy,
    );
  }

  Future<void> resetAll() async {
    final prefs = ref.read(sharedPreferencesProvider);
    for (final key in ['again', 'hard', 'good', 'easy']) {
      await prefs.remove('$_prefix$key');
    }
    state = RatingColors.defaults;
  }
}
