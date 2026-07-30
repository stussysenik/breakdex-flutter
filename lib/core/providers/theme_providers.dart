part of '../providers.dart';

// ---------------------------------------------------------------------------
// Icon pack — persisted in SharedPreferences
// ---------------------------------------------------------------------------

final iconPackProvider = NotifierProvider<IconPackNotifier, IconPackId>(
  IconPackNotifier.new,
);

class IconPackNotifier extends Notifier<IconPackId> {
  static const _key = 'icon_pack';

  @override
  IconPackId build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return IconPackId.fromKey(prefs.getString(_key));
  }

  Future<void> set(final IconPackId pack) async {
    state = pack;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, pack.key);
  }
}

// ---------------------------------------------------------------------------
// Color pack — persisted in SharedPreferences
// ---------------------------------------------------------------------------

final colorPackProvider = NotifierProvider<ColorPackNotifier, ColorPackId>(
  ColorPackNotifier.new,
);

class ColorPackNotifier extends Notifier<ColorPackId> {
  static const _key = 'color_pack';

  @override
  ColorPackId build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ColorPackId.fromKey(prefs.getString(_key));
  }

  Future<void> set(final ColorPackId pack) async {
    state = pack;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, pack.key);
  }
}

// ---------------------------------------------------------------------------
// Per-role color overrides — the user's adjustments on top of the pack
// ---------------------------------------------------------------------------

/// The roles the user has actually adjusted — **unset roles are absent**, not
/// defaulted.
///
/// That distinction is the whole reason this provider exists beside the older
/// `accentColorProvider` / `learningStateColorsProvider` / `ratingColorsProvider`.
/// Those three bake the `AppColors` fallback into their own state, so they cannot
/// express "unset": every read returns a color, and feeding that into a theme
/// would override whichever pack is selected with the classic values on every
/// build. Selecting `mono` would leave the state pills pink.
///
/// It reads the **same preference keys** those three write, so there is one
/// stored truth per role and no migration: a user who set an accent before packs
/// existed keeps it. New roles get `color_role_<name>`.
final colorRoleOverridesProvider =
    NotifierProvider<ColorRoleOverridesNotifier, Map<AppColorRole, Color>>(
      ColorRoleOverridesNotifier.new,
    );

class ColorRoleOverridesNotifier
    extends Notifier<Map<AppColorRole, Color>> {
  /// Preference key for a role.
  ///
  /// The eight roles that were user-adjustable before packs keep their original
  /// key. Renaming them would orphan live user state on a brownfield install,
  /// which is never worth a tidier naming scheme.
  static String keyFor(final AppColorRole role) => switch (role) {
    AppColorRole.accent => 'accent_color',
    AppColorRole.stateNew => 'learning_state_color_new',
    AppColorRole.stateLearning => 'learning_state_color_learning',
    AppColorRole.stateMastery => 'learning_state_color_mastery',
    AppColorRole.actionAgain => 'rating_color_again',
    AppColorRole.actionHard => 'rating_color_hard',
    AppColorRole.actionGood => 'rating_color_good',
    AppColorRole.actionEasy => 'rating_color_easy',
    AppColorRole.background ||
    AppColorRole.card ||
    AppColorRole.fill ||
    AppColorRole.separator ||
    AppColorRole.text ||
    AppColorRole.secondaryText ||
    AppColorRole.onAccent ||
    AppColorRole.error ||
    AppColorRole.onError => 'color_role_${role.name}',
  };

  @override
  Map<AppColorRole, Color> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return {
      for (final role in AppColorRole.values)
        if (prefs.getInt(keyFor(role)) case final int argb) role: Color(argb),
    };
  }

  Future<void> set(final AppColorRole role, final Color color) async {
    await _writeColor(ref, keyFor(role), color);
    state = {...state, role: color};
    _invalidateLegacyReaders(role);
  }

  /// Clears one role, returning it to whatever the selected pack says.
  Future<void> clear(final AppColorRole role) async {
    await _removeColor(ref, keyFor(role));
    state = {...state}..remove(role);
    _invalidateLegacyReaders(role);
  }

  Future<void> clearAll() async {
    for (final role in state.keys.toList()) {
      await _removeColor(ref, keyFor(role));
    }
    state = const {};
    for (final role in AppColorRole.values) {
      _invalidateLegacyReaders(role);
    }
  }

  /// Keeps the pre-pack providers from serving a stale cache.
  ///
  /// They read the same keys, so the *stored* value can never diverge — but their
  /// in-memory state is built once. Without this, adjusting a color here would
  /// leave the Settings rows that still watch them showing the old swatch.
  void _invalidateLegacyReaders(final AppColorRole role) {
    switch (role) {
      case AppColorRole.accent:
        ref.invalidate(accentColorProvider);
      case AppColorRole.stateNew ||
          AppColorRole.stateLearning ||
          AppColorRole.stateMastery:
        ref.invalidate(learningStateColorsProvider);
      case AppColorRole.actionAgain ||
          AppColorRole.actionHard ||
          AppColorRole.actionGood ||
          AppColorRole.actionEasy:
        ref.invalidate(ratingColorsProvider);
      case _:
        break;
    }
  }
}

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

  Future<void> set(final AppFontFamily family) async {
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

  Future<void> set(final Color color) async {
    await _writeColor(ref, _key, color);
    state = color;
    ref.invalidate(colorRoleOverridesProvider);
  }

  Future<void> reset() async {
    await _removeColor(ref, _key);
    state = AppColors.accent;
    ref.invalidate(colorRoleOverridesProvider);
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

  Future<void> setColor(final LearningState stateKey, final Color color) async {
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
    ref.invalidate(colorRoleOverridesProvider);
  }

  Future<void> resetAll() async {
    for (final key in ['new', 'learning', 'mastery']) {
      await _removeColor(ref, _prefix + key);
    }
    state = LearningStateColors.defaults;
    ref.invalidate(colorRoleOverridesProvider);
  }
}

// ---------------------------------------------------------------------------
// Rating colors — configurable per-rating button colors
// ---------------------------------------------------------------------------

// `RatingColors` itself lives in `lib/core/models/rating_colors.dart` — the
// design layer accepts it as a per-role theme override, and a `part of` file
// cannot be imported.

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

  Future<void> setColor(final String key, final Color color) async {
    final prefKey = _prefix + key;
    await _writeColor(ref, prefKey, color);
    state = switch (key) {
      'again' => state.copyWith(again: color),
      'hard' => state.copyWith(hard: color),
      'good' => state.copyWith(good: color),
      'easy' => state.copyWith(easy: color),
      _ => state,
    };
    ref.invalidate(colorRoleOverridesProvider);
  }

  Future<void> resetAll() async {
    for (final key in ['again', 'hard', 'good', 'easy']) {
      await _removeColor(ref, _prefix + key);
    }
    state = RatingColors.defaults;
    ref.invalidate(colorRoleOverridesProvider);
  }
}

// ---------------------------------------------------------------------------
// Review card fill — user-customizable Instax-frame color for the review card.
// Nullable: null means "use the default frame" (classic white). Persisted as an
// ARGB int under `review_fill_color`; the review card watches it so a change in
// Settings applies live without a restart.
// ---------------------------------------------------------------------------

final reviewFillColorProvider =
    NotifierProvider<ReviewFillColorNotifier, Color?>(
      ReviewFillColorNotifier.new,
    );

class ReviewFillColorNotifier extends Notifier<Color?> {
  static const _key = 'review_fill_color';

  @override
  Color? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = prefs.getInt(_key);
    return value != null ? Color(value) : null;
  }

  Future<void> set(final Color color) async {
    await _writeColor(ref, _key, color);
    state = color;
  }

  Future<void> reset() async {
    await _removeColor(ref, _key);
    state = null;
  }
}

Color _readColor(final Ref ref, final String key, final Color fallback) {
  final prefs = ref.read(sharedPreferencesProvider);
  final value = prefs.getInt(key);
  return value != null ? Color(value) : fallback;
}

Future<void> _writeColor(final Ref ref, final String key, final Color color) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setInt(key, color.toARGB32());
}

Future<void> _removeColor(final Ref ref, final String key) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.remove(key);
}
