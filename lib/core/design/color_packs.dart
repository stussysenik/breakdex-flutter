import 'package:breakdex/core/design/color_roles.dart';
import 'package:breakdex/core/design/colors.dart';
import 'package:flutter/material.dart';

/// A swappable answer to "what color is each role".
///
/// A pack resolves the closed [AppColorRole] vocabulary — every role, at both
/// brightnesses. Resolution is a `switch` with **no `default`**: a pack that
/// forgets a role fails `flutter analyze` instead of rendering a fallback color
/// at runtime, which is the same guarantee `IconPack` gets from `AppIcon` and
/// for the same reason. A `default` case would convert a compile error into a
/// wrong pixel nobody notices.
///
/// A pack owns colors, not modes. It does not know about `ViewingMode` or
/// `AccessiblePalette`: those are the later axes in `pack → brightness →
/// overlay`, applied by `AppTheme` after the pack has spoken. So a pack's
/// `onAccent` is what sits on *its* accent — the grayscale modes' substitution
/// of the background color is the overlay's business, not the pack's.
abstract class ColorPack {
  const ColorPack();

  /// Stable identifier persisted in preferences. Never derive it from the
  /// display name — a rename would silently reset every user's selection.
  String get key;

  Color resolve(final AppColorRole role, final Brightness brightness);
}

/// The packs available to a user.
///
/// Both shipped packs are re-expressions of already-shipped data, which is the
/// point at this stage: they prove the vocabulary is adequate to describe what
/// the app already renders before any new palette is designed against it.
enum ColorPackId {
  /// Today's palette — white/black foundation, blue accent.
  classic(_ClassicColorPack()),

  /// The grayscale ramp, selectable as a pack rather than only reachable
  /// through a viewing mode or the monochrome accessibility overlay.
  mono(_MonoColorPack());

  const ColorPackId(this.pack);

  final ColorPack pack;

  String get key => pack.key;

  /// Tolerates an unknown or absent stored value.
  ///
  /// A pack removed in a later release must not brick the app for whoever had
  /// it selected — an unrecognised key resolves to [classic] rather than
  /// throwing. Same contract as `IconPackId.fromKey` and `AppFontFamily.fromKey`.
  static ColorPackId fromKey(final String? key) => values.firstWhere(
    (final id) => id.key == key,
    orElse: () => classic,
  );
}

/// Today's shipped palette, expressed in the role vocabulary.
///
/// Every value here is the `AppColors` constant the theme already used, so
/// selecting `classic` renders byte-identically to the pre-pack build —
/// asserted role by role in `color_packs_test.dart`, not by inspection.
class _ClassicColorPack extends ColorPack {
  const _ClassicColorPack();

  @override
  String get key => 'classic';

  @override
  Color resolve(final AppColorRole role, final Brightness brightness) {
    final light = brightness == Brightness.light;
    return switch (role) {
      AppColorRole.background => light ? AppColors.lightBg : AppColors.darkBg,
      AppColorRole.card => light ? AppColors.lightCard : AppColors.darkCard,
      AppColorRole.fill => light ? AppColors.lightFill : AppColors.darkFill,
      AppColorRole.separator =>
        light ? AppColors.lightSeparator : AppColors.darkSeparator,
      AppColorRole.text => light ? AppColors.lightText : AppColors.darkText,
      AppColorRole.secondaryText =>
        light ? AppColors.lightSecondary : AppColors.darkSecondary,
      AppColorRole.accent => AppColors.accent,
      // White on both brightnesses, matching the shipped `onPrimary`. The
      // grayscale modes swap it for the background; that is the overlay's job.
      AppColorRole.onAccent => Colors.white,
      // Hardwired to the "again" value in the shipped theme. Tracked as
      // add-color-packs 2.4: as a signal it should follow the accessibility
      // overlay, and today it does not. Kept identical here because 3.2
      // requires byte-identity — the fix is an overlay change, not a pack one.
      AppColorRole.error => AppColors.actionAgain,
      AppColorRole.onError => Colors.white,
      AppColorRole.stateNew => AppColors.stateNew,
      AppColorRole.stateLearning => AppColors.stateLearning,
      AppColorRole.stateMastery => AppColors.stateMastery,
      AppColorRole.actionAgain => AppColors.actionAgain,
      AppColorRole.actionHard => AppColors.actionHard,
      AppColorRole.actionGood => AppColors.actionGood,
      AppColorRole.actionEasy => AppColors.actionEasy,
    };
  }
}

/// The grayscale ramp: surfaces from `monoLight*`/`monoDark*`, every signal ink.
///
/// Distinct from the `monochrome` accessibility overlay even though they land in
/// the same place. The overlay is a guarantee the user asked for and the app
/// must honor; this is a pack the user picked because they like it. Keeping them
/// separate is what lets the overlay stay authoritative — a pack is a
/// preference, and preferences do not override guarantees.
class _MonoColorPack extends ColorPack {
  const _MonoColorPack();

  @override
  String get key => 'mono';

  @override
  Color resolve(final AppColorRole role, final Brightness brightness) {
    final light = brightness == Brightness.light;
    final ink = light ? AppColors.monoLightText : AppColors.monoDarkText;
    return switch (role) {
      AppColorRole.background =>
        light ? AppColors.monoLightBg : AppColors.monoDarkBg,
      AppColorRole.card =>
        light ? AppColors.monoLightCard : AppColors.monoDarkCard,
      AppColorRole.fill =>
        light ? AppColors.monoLightFill : AppColors.monoDarkFill,
      AppColorRole.separator =>
        light ? AppColors.monoLightSeparator : AppColors.monoDarkSeparator,
      AppColorRole.text => ink,
      AppColorRole.secondaryText =>
        light ? AppColors.monoLightSecondary : AppColors.monoDarkSecondary,
      // No color survives: the accent is ink, and what sits on ink is the
      // background — a hardcoded white would vanish on a near-white fill in
      // dark mode, which is the bug the shipped grayscale branch already fixed.
      AppColorRole.accent => ink,
      AppColorRole.onAccent =>
        light ? AppColors.monoLightBg : AppColors.monoDarkBg,
      AppColorRole.error => ink,
      AppColorRole.onError =>
        light ? AppColors.monoLightBg : AppColors.monoDarkBg,
      AppColorRole.stateNew => ink,
      AppColorRole.stateLearning => ink,
      AppColorRole.stateMastery => ink,
      AppColorRole.actionAgain => ink,
      AppColorRole.actionHard => ink,
      AppColorRole.actionGood => ink,
      AppColorRole.actionEasy => ink,
    };
  }
}

/// One pack's colors at one brightness, with per-role user overrides applied.
///
/// This is the boundary between "what the pack says" and "what the theme
/// builds": [ResolvedColors] is the last point at which a color is addressed by
/// *role*. `AppTheme` then applies the accessibility overlay and maps roles onto
/// Material's `ColorScheme` slots, where the role names disappear.
@immutable
class ResolvedColors {
  const ResolvedColors._(this._colors);

  /// Resolves [pack] at [brightness], then lets [overrides] win per role.
  ///
  /// Overrides sit *inside* the pack axis rather than after the overlay: a user
  /// who adjusted one color and then selected `deuteranopia` still gets the
  /// Okabe–Ito guarantee for the signals, because the overlay is applied later
  /// and unconditionally. Their adjustment is not erased — it returns when the
  /// palette goes back to `standard`.
  factory ResolvedColors.of(
    final ColorPack pack,
    final Brightness brightness, {
    final Map<AppColorRole, Color> overrides = const {},
  }) => ResolvedColors._({
    for (final role in AppColorRole.values)
      role: overrides[role] ?? pack.resolve(role, brightness),
  });

  final Map<AppColorRole, Color> _colors;

  /// Every role resolves, so this is total by construction — the map is built
  /// from `AppColorRole.values`, not accumulated by callers.
  Color operator [](final AppColorRole role) => _colors[role]!;

  ResolvedColors copyWith(final Map<AppColorRole, Color> replacements) =>
      ResolvedColors._({..._colors, ...replacements});
}
