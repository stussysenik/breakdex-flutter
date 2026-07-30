/// The closed color vocabulary a pack must resolve.
///
/// Every entry is **a thing a screen means**, not a hex. That distinction is the
/// whole mechanism: `AppColors` holds 39 constants, but a screen never wants
/// "0xFF1F5EFF" — it wants "the one colored mark on this surface". Naming the
/// meanings and closing the set is what lets a pack be swapped without any
/// screen changing, and what lets `flutter analyze` prove a pack is complete
/// (an exhaustive `switch` over a closed enum needs no `default`, so a missing
/// role is a compile error rather than a fallback color at runtime).
///
/// The set is derived from what `AppTheme._build` actually renders, not from
/// what `colors.dart` declares. The 39 constants collapse to 17 roles because
/// most of them are the same role under a different mode: `lightBg`, `darkBg`,
/// `monoLightBg`, and `monoDarkBg` are four values of [background], resolved by
/// brightness and by the accessibility overlay rather than by four names.
library;

/// Which axis owns a role, per the precedence rule `pack → brightness →
/// accessibility overlay`.
///
/// The overlay is applied last and wins, but it does not own everything: on
/// `deuteranopia` it replaces exactly the [signal] roles and leaves surfaces and
/// accent to the pack. Recording the kind on the role is what makes that
/// selective override checkable instead of a convention — a test can assert
/// "no [signal] survives the deuteranopia overlay" and "every [surface] does".
enum AppColorRoleKind {
  /// Chrome a pixel sits on. Pack-supplied in every mode except `monochrome`,
  /// which takes the grayscale ramp.
  surface,

  /// Text, glyphs, and the single accent mark. Pack-supplied; `monochrome` tones
  /// the accent to ink so no color survives.
  ink,

  /// Meaning carried by color — learning states and review ratings. These are
  /// what an accessibility overlay exists to replace.
  signal,
}

/// Every color role the app renders.
enum AppColorRole {
  /// Behind everything — `scaffoldBackgroundColor`, not a card.
  background(AppColorRoleKind.surface),

  /// A contained surface: cards, sheets, the nav bar, menus.
  card(AppColorRoleKind.surface),

  /// A recessed well: input fields, muted panels, `surfaceContainerHighest`.
  fill(AppColorRoleKind.surface),

  /// A 1px hairline — dividers, borders, `outline`.
  separator(AppColorRoleKind.surface),

  /// Primary reading ink.
  text(AppColorRoleKind.ink),

  /// Supporting ink: captions, hints, unselected nav labels.
  secondaryText(AppColorRoleKind.ink),

  /// The one colored mark — selection, focus, the primary action.
  accent(AppColorRoleKind.ink),

  /// Ink legible on top of [accent]. Not always white: in a grayscale mode the
  /// accent tones to ink, where a hardcoded white vanishes on a near-white fill.
  onAccent(AppColorRoleKind.ink),

  /// A destructive or failed condition. Distinct from [actionAgain] as a
  /// *meaning* even where a pack happens to give both the same value — the old
  /// hardwire of `ColorScheme.error` to the "again" rating was precisely the
  /// kind of untracked coincidence this vocabulary exists to make explicit, and
  /// naming it is what surfaced that it followed no overlay at all (2.4).
  error(AppColorRoleKind.signal),

  /// Ink legible on top of [error].
  onError(AppColorRoleKind.ink),

  /// Learning state: not yet studied.
  stateNew(AppColorRoleKind.signal),

  /// Learning state: in progress.
  stateLearning(AppColorRoleKind.signal),

  /// Learning state: retained.
  stateMastery(AppColorRoleKind.signal),

  /// Review rating: failed.
  actionAgain(AppColorRoleKind.signal),

  /// Review rating: recalled with difficulty.
  actionHard(AppColorRoleKind.signal),

  /// Review rating: recalled.
  actionGood(AppColorRoleKind.signal),

  /// Review rating: recalled immediately.
  actionEasy(AppColorRoleKind.signal);

  const AppColorRole(this.kind);

  final AppColorRoleKind kind;

  /// Roles an accessibility overlay may replace.
  static Iterable<AppColorRole> get signals =>
      values.where((final role) => role.kind == AppColorRoleKind.signal);

  /// Roles a pack owns in every mode but `monochrome`.
  static Iterable<AppColorRole> get surfaces =>
      values.where((final role) => role.kind == AppColorRoleKind.surface);
}
