part of '../providers.dart';

// ---------------------------------------------------------------------------
// Font family — persisted in SharedPreferences
// ---------------------------------------------------------------------------

final fontFamilyProvider = NotifierProvider<FontFamilyNotifier, AppFontFamily>(
  FontFamilyNotifier.new,
);

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

final accentColorProvider = NotifierProvider<AccentColorNotifier, Color>(
  AccentColorNotifier.new,
);

/// Persists custom accent color in SharedPreferences as an ARGB int.
/// The theme watches this provider so changing it updates the entire UI.
class AccentColorNotifier extends Notifier<Color> {
  static const _key = 'accent_color';

  @override
  Color build() {
    return _readColor(ref, _key, AppColors.accent);
  }

  Future<void> set(Color color) async {
    await _writeColor(ref, _key, color);
    state = color;
  }

  Future<void> reset() async {
    await _removeColor(ref, _key);
    state = AppColors.accent;
  }
}

// ---------------------------------------------------------------------------
// Learning state colors — configurable per-state semantic color
// ---------------------------------------------------------------------------

final learningStateColorsProvider =
    NotifierProvider<LearningStateColorsNotifier, LearningStateColors>(
      LearningStateColorsNotifier.new,
    );

class LearningStateColorsNotifier extends Notifier<LearningStateColors> {
  static const _prefix = 'learning_state_color_';

  @override
  LearningStateColors build() {
    return LearningStateColors(
      newState: _readColor(ref, '${_prefix}new', AppColors.stateNew),
      learning: _readColor(ref, '${_prefix}learning', AppColors.stateLearning),
      mastery: _readColor(ref, '${_prefix}mastery', AppColors.stateMastery),
    );
  }

  Future<void> setColor(LearningState stateKey, Color color) async {
    final key = switch (stateKey) {
      LearningState.newState => 'new',
      LearningState.learning => 'learning',
      LearningState.mastery => 'mastery',
    };
    await _writeColor(ref, _prefix + key, color);
    state = switch (stateKey) {
      LearningState.newState => state.copyWith(newState: color),
      LearningState.learning => state.copyWith(learning: color),
      LearningState.mastery => state.copyWith(mastery: color),
    };
  }

  Future<void> resetAll() async {
    for (final key in ['new', 'learning', 'mastery']) {
      await _removeColor(ref, _prefix + key);
    }
    state = LearningStateColors.defaults;
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

  RatingColors copyWith({Color? again, Color? hard, Color? good, Color? easy}) {
    return RatingColors(
      again: again ?? this.again,
      hard: hard ?? this.hard,
      good: good ?? this.good,
      easy: easy ?? this.easy,
    );
  }
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
    return RatingColors(
      again: _readColor(ref, '${_prefix}again', AppColors.actionAgain),
      hard: _readColor(ref, '${_prefix}hard', AppColors.actionHard),
      good: _readColor(ref, '${_prefix}good', AppColors.actionGood),
      easy: _readColor(ref, '${_prefix}easy', AppColors.actionEasy),
    );
  }

  Future<void> setColor(String key, Color color) async {
    final prefKey = _prefix + key;
    await _writeColor(ref, prefKey, color);
    state = switch (key) {
      'again' => state.copyWith(again: color),
      'hard' => state.copyWith(hard: color),
      'good' => state.copyWith(good: color),
      'easy' => state.copyWith(easy: color),
      _ => state,
    };
  }

  Future<void> resetAll() async {
    for (final key in ['again', 'hard', 'good', 'easy']) {
      await _removeColor(ref, _prefix + key);
    }
    state = RatingColors.defaults;
  }
}

Color _readColor(Ref ref, String key, Color fallback) {
  final prefs = ref.read(sharedPreferencesProvider);
  final value = prefs.getInt(key);
  return value != null ? Color(value) : fallback;
}

Future<void> _writeColor(Ref ref, String key, Color color) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setInt(key, color.toARGB32());
}

Future<void> _removeColor(Ref ref, String key) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.remove(key);
}
