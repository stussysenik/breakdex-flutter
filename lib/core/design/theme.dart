import 'package:flutter/material.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/models/learning_state_colors.dart';
import 'package:breakdex/core/models/rating_colors.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/core/design/color_packs.dart';
import 'package:breakdex/core/design/color_roles.dart';
import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/contrast.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';

abstract final class AppShadows {
  static List<BoxShadow> soft(final Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.light
          ? const Color(0x140F0B08)
          : const Color(0x42000000),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> raised(final Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.light
          ? const Color(0x1A0F0B08)
          : const Color(0x52000000),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> focus(final Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.light
          ? const Color(0x260F0B08)
          : const Color(0x66000000),
      blurRadius: 34,
      offset: const Offset(0, 16),
    ),
  ];

  /// Two-shadow stack simulating real lighting: an ambient fill (soft, centered)
  /// plus a key-light shadow (directional, offset). Produces depth that a
  /// single shadow cannot match — closer to cinematic lighting than Material
  /// elevation. Use on hero cards, floating panels, and bottom nav.
  static List<BoxShadow> layered(final Brightness brightness) => [
    // Ambient — soft, centered, simulates scattered room light
    BoxShadow(
      color: brightness == Brightness.light
          ? const Color(0x0A0F0B08)
          : const Color(0x1A000000),
      blurRadius: 20,
      spreadRadius: 1,
    ),
    // Key light — directional, overhead, simulates primary light source
    BoxShadow(
      color: brightness == Brightness.light
          ? const Color(0x1A0F0B08)
          : const Color(0x40000000),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

enum AppSurfaceTone { base, muted, emphasis }

/// Tileable noise grain overlay — opt-in via `AppSurfaces.panel(withGrain: true)`.
///
/// Renders a 256x256 tileable noise PNG at 0.04 opacity on top of the surface.
/// Adds tactile materiality to flat cards without hurting scroll performance
/// (the image is decoded once and cached by the framework's ImageCache).
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({super.key, this.opacity = 0.04});

  final double opacity;

  @override
  Widget build(final BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            'assets/textures/grain.png',
            repeat: ImageRepeat.repeat,
            filterQuality: FilterQuality.none,
          ),
        ),
      ),
    );
  }
}

abstract final class AppSurfaces {
  static BoxDecoration panel(
    final BuildContext context, {
    final AppSurfaceTone tone = AppSurfaceTone.base,
    final bool raised = false,
    final bool focused = false,
    final double radius = AppRadius.md,
    final Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = AppSemanticTheme.of(context);

    final fill = switch (tone) {
      AppSurfaceTone.base => colorScheme.surface,
      AppSurfaceTone.muted =>
        semantic.isMonoOutline
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest,
      AppSurfaceTone.emphasis =>
        semantic.isMonoOutline
            ? colorScheme.surface
            : Color.lerp(colorScheme.surface, colorScheme.primary, 0.08)!,
    };

    final outline =
        borderColor ??
        switch ((semantic.isMonoOutline, tone, focused)) {
          (true, _, true) => colorScheme.primary,
          (true, _, false) => colorScheme.outline,
          (false, AppSurfaceTone.emphasis, _) => colorScheme.primary.withValues(
            alpha: focused ? 0.34 : 0.18,
          ),
          (false, _, true) => colorScheme.primary.withValues(alpha: 0.24),
          (false, _, false) => colorScheme.outline.withValues(alpha: 0.24),
        };

    final boxShadow = focused
        ? AppShadows.focus(theme.brightness)
        : raised
        ? AppShadows.raised(theme.brightness)
        : AppShadows.soft(theme.brightness);

    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: outline,
        width: semantic.isMonoOutline ? 1.2 : 1,
      ),
      boxShadow: boxShadow,
    );
  }
}

/// Chrome for surfaces that are dark **on purpose** — video players, the trim
/// timeline, the instax viewer — regardless of the app's brightness.
///
/// These surfaces used to name `AppColors.darkBg` / `darkCard` / `darkFill`
/// directly, which is the 2.5 bypass in its least obvious form: the intent
/// ("stay dark under a bright photo") is legitimate, so the constants read as
/// correct, but they still pinned the pixels outside the theme and a pack could
/// never restyle them. Resolving the *active pack at [Brightness.dark]* keeps
/// the intent and returns the pixels: a pack owns its own dark side, so media
/// chrome follows the pack without ever following the app's light mode.
@immutable
class AppMediaChrome extends ThemeExtension<AppMediaChrome> {
  const AppMediaChrome({
    required this.background,
    required this.card,
    required this.fill,
    required this.separator,
    required this.ink,
  });

  /// The full-bleed backdrop behind media.
  final Color background;

  /// A contained panel over that backdrop.
  final Color card;

  /// A recessed well — scrub tracks, placeholder tiles.
  final Color fill;

  /// A hairline on dark chrome.
  final Color separator;

  /// Reading ink on dark chrome.
  final Color ink;

  static AppMediaChrome of(final BuildContext context) =>
      Theme.of(context).extension<AppMediaChrome>() ?? _fallback;

  /// Used only when a widget is mounted under a bare `ThemeData` (previews,
  /// tests). Matches the `classic` pack's dark side.
  static const _fallback = AppMediaChrome(
    background: AppColors.darkBg,
    card: AppColors.darkCard,
    fill: AppColors.darkFill,
    separator: AppColors.darkSeparator,
    ink: AppColors.darkText,
  );

  @override
  AppMediaChrome copyWith({
    final Color? background,
    final Color? card,
    final Color? fill,
    final Color? separator,
    final Color? ink,
  }) => AppMediaChrome(
    background: background ?? this.background,
    card: card ?? this.card,
    fill: fill ?? this.fill,
    separator: separator ?? this.separator,
    ink: ink ?? this.ink,
  );

  @override
  AppMediaChrome lerp(
    final ThemeExtension<AppMediaChrome>? other,
    final double t,
  ) {
    if (other is! AppMediaChrome) return this;
    return AppMediaChrome(
      background: Color.lerp(background, other.background, t) ?? background,
      card: Color.lerp(card, other.card, t) ?? card,
      fill: Color.lerp(fill, other.fill, t) ?? fill,
      separator: Color.lerp(separator, other.separator, t) ?? separator,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
    );
  }
}

@immutable
class AppSemanticTheme extends ThemeExtension<AppSemanticTheme> {
  const AppSemanticTheme({
    required this.isMonoOutline,
    required this.stateNew,
    required this.stateLearning,
    required this.stateMastery,
    required this.actionAgain,
    required this.actionHard,
    required this.actionGood,
    required this.actionEasy,
  });

  final bool isMonoOutline;
  final Color stateNew;
  final Color stateLearning;
  final Color stateMastery;
  final Color actionAgain;
  final Color actionHard;
  final Color actionGood;
  final Color actionEasy;

  Color colorForState(final LearningState state) => switch (state) {
    LearningState.newState => stateNew,
    LearningState.learning => stateLearning,
    LearningState.mastery => stateMastery,
  };

  Color colorForRating(final ReviewRating rating) => switch (rating) {
    ReviewRating.again => actionAgain,
    ReviewRating.hard => actionHard,
    ReviewRating.good => actionGood,
    ReviewRating.easy => actionEasy,
  };

  static AppSemanticTheme of(final BuildContext context) {
    final extension = Theme.of(context).extension<AppSemanticTheme>();
    if (extension != null) return extension;
    return defaults;
  }

  /// The standard semantic ramp (default states + review actions).
  static const defaults = AppSemanticTheme(
    isMonoOutline: false,
    stateNew: AppColors.stateNew,
    stateLearning: AppColors.stateLearning,
    stateMastery: AppColors.stateMastery,
    actionAgain: AppColors.actionAgain,
    actionHard: AppColors.actionHard,
    actionGood: AppColors.actionGood,
    actionEasy: AppColors.actionEasy,
  );

  /// The Okabe–Ito deuteranopia-safe ramp (AccessiblePalette.deuteranopia).
  static const deuteranopia = AppSemanticTheme(
    isMonoOutline: false,
    stateNew: AppColors.deuterStateNew,
    stateLearning: AppColors.deuterStateLearning,
    stateMastery: AppColors.deuterStateMastery,
    actionAgain: AppColors.deuterActionAgain,
    actionHard: AppColors.deuterActionHard,
    actionGood: AppColors.deuterActionGood,
    actionEasy: AppColors.deuterActionEasy,
  );

  /// A single-ink ramp — every semantic signal collapses to [ink]. Used for the
  /// monoOutline "marker" style and the monochrome accessible palette;
  /// distinguishability is carried by the paired icons/labels, not color.
  factory AppSemanticTheme.ink(
    final Color ink, {
    final bool isMonoOutline = false,
  }) => AppSemanticTheme(
    isMonoOutline: isMonoOutline,
    stateNew: ink,
    stateLearning: ink,
    stateMastery: ink,
    actionAgain: ink,
    actionHard: ink,
    actionGood: ink,
    actionEasy: ink,
  );

  @override
  AppSemanticTheme copyWith({
    final bool? isMonoOutline,
    final Color? stateNew,
    final Color? stateLearning,
    final Color? stateMastery,
    final Color? actionAgain,
    final Color? actionHard,
    final Color? actionGood,
    final Color? actionEasy,
  }) {
    return AppSemanticTheme(
      isMonoOutline: isMonoOutline ?? this.isMonoOutline,
      stateNew: stateNew ?? this.stateNew,
      stateLearning: stateLearning ?? this.stateLearning,
      stateMastery: stateMastery ?? this.stateMastery,
      actionAgain: actionAgain ?? this.actionAgain,
      actionHard: actionHard ?? this.actionHard,
      actionGood: actionGood ?? this.actionGood,
      actionEasy: actionEasy ?? this.actionEasy,
    );
  }

  @override
  AppSemanticTheme lerp(
    final ThemeExtension<AppSemanticTheme>? other,
    final double t,
  ) {
    if (other is! AppSemanticTheme) return this;
    return AppSemanticTheme(
      isMonoOutline: t < 0.5 ? isMonoOutline : other.isMonoOutline,
      stateNew: Color.lerp(stateNew, other.stateNew, t) ?? stateNew,
      stateLearning:
          Color.lerp(stateLearning, other.stateLearning, t) ?? stateLearning,
      stateMastery:
          Color.lerp(stateMastery, other.stateMastery, t) ?? stateMastery,
      actionAgain: Color.lerp(actionAgain, other.actionAgain, t) ?? actionAgain,
      actionHard: Color.lerp(actionHard, other.actionHard, t) ?? actionHard,
      actionGood: Color.lerp(actionGood, other.actionGood, t) ?? actionGood,
      actionEasy: Color.lerp(actionEasy, other.actionEasy, t) ?? actionEasy,
    );
  }
}

extension AppSemanticThemeContext on BuildContext {
  AppSemanticTheme get semanticTheme => AppSemanticTheme.of(this);

  Color stateColor(final LearningState state) =>
      semanticTheme.colorForState(state);
}

abstract final class AppTheme {
  static ThemeData light({
    final AppFontFamily family = AppFontFamily.inter,
    final ColorPackId pack = ColorPackId.classic,
    final Map<AppColorRole, Color> overrides = const {},
    final Color? accent,
    final LearningStateColors? stateColors,
    final RatingColors? ratingColors,
    final ViewingMode viewingMode = ViewingMode.standard,
    final AccessiblePalette palette = AccessiblePalette.standard,
    final IconPackId iconPack = IconPackId.material,
  }) => _build(
    brightness: Brightness.light,
    pack: pack,
    overrides: _mergeOverrides(
      overrides,
      accent: accent,
      stateColors: stateColors,
      ratingColors: ratingColors,
    ),
    family: family,
    viewingMode: viewingMode,
    palette: palette,
    iconPack: iconPack,
  );

  static ThemeData dark({
    final AppFontFamily family = AppFontFamily.inter,
    final ColorPackId pack = ColorPackId.classic,
    final Map<AppColorRole, Color> overrides = const {},
    final Color? accent,
    final LearningStateColors? stateColors,
    final RatingColors? ratingColors,
    final ViewingMode viewingMode = ViewingMode.standard,
    final AccessiblePalette palette = AccessiblePalette.standard,
    final IconPackId iconPack = IconPackId.material,
  }) => _build(
    brightness: Brightness.dark,
    pack: pack,
    overrides: _mergeOverrides(
      overrides,
      accent: accent,
      stateColors: stateColors,
      ratingColors: ratingColors,
    ),
    family: family,
    viewingMode: viewingMode,
    palette: palette,
    iconPack: iconPack,
  );

  /// Folds the typed convenience parameters into the role-keyed override map.
  ///
  /// The typed parameters exist because most call sites want one color, not a
  /// map — `AppTheme.light(stateColors: custom)` reads better in a widget test
  /// than an `AppColorRole` literal. They are **nullable on purpose**: with a
  /// pack axis, "unset" has to mean *use the pack*, and a non-null default would
  /// make every build silently override the pack with the classic values. That is
  /// exactly the trap `learningStateColorsProvider` falls into — it bakes the
  /// `AppColors` fallback into its own state, so a consumer cannot tell "the user
  /// chose #E45D7A" from "the user chose nothing". Read overrides through
  /// `colorRoleOverridesProvider`, which omits unset roles instead.
  static Map<AppColorRole, Color> _mergeOverrides(
    final Map<AppColorRole, Color> overrides, {
    final Color? accent,
    final LearningStateColors? stateColors,
    final RatingColors? ratingColors,
  }) {
    if (accent == null && stateColors == null && ratingColors == null) {
      return overrides;
    }
    return {
      ...overrides,
      AppColorRole.accent: ?accent,
      if (stateColors != null) ...{
        AppColorRole.stateNew: stateColors.newState,
        AppColorRole.stateLearning: stateColors.learning,
        AppColorRole.stateMastery: stateColors.mastery,
      },
      if (ratingColors != null) ...{
        AppColorRole.actionAgain: ratingColors.again,
        AppColorRole.actionHard: ratingColors.hard,
        AppColorRole.actionGood: ratingColors.good,
        AppColorRole.actionEasy: ratingColors.easy,
      },
    };
  }

  /// Whichever of [ink] and [bg] reads better on [color].
  ///
  /// Used only where the overlay chose [color] and the pack's paired ink no
  /// longer applies. Measured rather than assumed: white is the reflex answer
  /// and it is wrong on Okabe–Ito vermillion in light mode, where the reading
  /// ink clears 4.5:1 and white does not.
  static Color _legibleInkOn(
    final Color color, {
    required final Color ink,
    required final Color bg,
  }) => contrastRatio(ink, color) >= contrastRatio(bg, color) ? ink : bg;

  static AppMediaChrome _mediaChrome(
    final ColorPack pack, {
    required final Map<AppColorRole, Color> overrides,
  }) {
    final dark = ResolvedColors.of(
      pack,
      Brightness.dark,
      overrides: overrides,
    );
    return AppMediaChrome(
      background: dark[AppColorRole.background],
      card: dark[AppColorRole.card],
      fill: dark[AppColorRole.fill],
      separator: dark[AppColorRole.separator],
      ink: dark[AppColorRole.text],
    );
  }

  static ThemeData _build({
    required final Brightness brightness,
    required final ColorPackId pack,
    required final Map<AppColorRole, Color> overrides,
    required final AppFontFamily family,
    required final ViewingMode viewingMode,
    required final AccessiblePalette palette,
    required final IconPackId iconPack,
  }) {
    final isMonoOutline = viewingMode == ViewingMode.monoOutline;
    // Any grayscale mode (marker outline or monochrome palette) renders on the
    // grayscale ramp with the accent toned to ink, so no color survives. That is
    // the `mono` pack's definition, which is why the overlay can express itself
    // as a pack substitution rather than as a second set of branches.
    final grayscale = isMonoOutline || palette == AccessiblePalette.monochrome;

    // Axis 1 + 2 — pack at this brightness, with the user's per-role overrides.
    // Grayscale drops the overrides: a guarantee the user asked for outranks a
    // preference they expressed earlier, and the adjustment is not erased — it
    // returns when the mode does.
    final colors = ResolvedColors.of(
      grayscale ? ColorPackId.mono.pack : pack.pack,
      brightness,
      overrides: grayscale ? const {} : overrides,
    );

    final bg = colors[AppColorRole.background];
    final card = colors[AppColorRole.card];
    final fill = colors[AppColorRole.fill];
    final text = colors[AppColorRole.text];
    final secondary = colors[AppColorRole.secondaryText];
    final separator = colors[AppColorRole.separator];
    final effectiveAccent = colors[AppColorRole.accent];

    // Axis 3 — the accessibility overlay, applied last and winning. It replaces
    // signal roles only; surfaces and accent above already came from the pack.
    final semanticTheme = switch ((isMonoOutline, palette)) {
      // Marker outline keeps its distinctive outline flag + ink ramp.
      (true, _) => AppSemanticTheme.ink(text, isMonoOutline: true),
      // Monochrome: ink ramp, but filled surfaces (isMonoOutline stays false).
      (false, AccessiblePalette.monochrome) => AppSemanticTheme.ink(text),
      (false, AccessiblePalette.deuteranopia) => AppSemanticTheme.deuteranopia,
      (false, AccessiblePalette.standard) => AppSemanticTheme(
        isMonoOutline: false,
        stateNew: colors[AppColorRole.stateNew],
        stateLearning: colors[AppColorRole.stateLearning],
        stateMastery: colors[AppColorRole.stateMastery],
        actionAgain: colors[AppColorRole.actionAgain],
        actionHard: colors[AppColorRole.actionHard],
        actionGood: colors[AppColorRole.actionGood],
        actionEasy: colors[AppColorRole.actionEasy],
      ),
    };
    // Axis 3 owns `error` too. It is an `AppColorRoleKind.signal`, and a signal
    // that survives the overlay is precisely what the overlay exists to prevent
    // (2.4): the shipped theme hardwired it to the classic "again" hex in every
    // mode, so deuteranopia moved the rating to Okabe–Ito vermillion while an
    // error surface stayed unsafe red, and monochrome kept one red while
    // claiming no color survives. The pack still seeds the role — under
    // `standard` its value is used verbatim, so a pack may name a failed
    // condition independently of the "again" rating — but an overlay publishes
    // one safe value for that meaning and it wins here like everywhere else.
    final overlayOwnsSignals =
        isMonoOutline || palette != AccessiblePalette.standard;
    final errorColor = overlayOwnsSignals
        ? semanticTheme.actionAgain
        : colors[AppColorRole.error];
    final textTheme = AppTypography.textTheme(text, secondary, family: family);
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: effectiveAccent,
      onPrimary: colors[AppColorRole.onAccent],
      secondary: secondary,
      onSecondary: text,
      surface: card,
      onSurface: text,
      error: errorColor,
      // The pack's `onError` sits on the pack's `error`; once the overlay has
      // renamed the color, that pairing is stale, so the ink is re-chosen by
      // measured contrast between the only two inks the theme can guarantee are
      // on-palette — the reading ink and the background it reads on.
      onError: overlayOwnsSignals
          ? _legibleInkOn(errorColor, ink: text, bg: bg)
          : colors[AppColorRole.onError],
      surfaceContainerHighest: fill,
      outline: separator,
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [
        semanticTheme,
        // Media chrome is the same pack read at its dark brightness — never the
        // app's. The overrides ride along so a user's adjustment reaches a
        // video surface too; grayscale drops them for the same reason it does
        // above.
        _mediaChrome(
          grayscale ? ColorPackId.mono.pack : pack.pack,
          overrides: grayscale ? const {} : overrides,
        ),
        AppIconPackTheme(iconPack.build()),
        // The shipped basis. Registered so every screen reads its grid from the
        // theme rather than from a constant — which is what lets a subtree
        // (the dev gallery) swap in a different basis and watch it re-flow.
        const AppLayoutTheme(),
      ],
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: text),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: AppShadows.soft(brightness).first.color,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: effectiveAccent,
          // Match onPrimary so an ink accent (grayscale modes) stays legible in
          // dark mode, where a hardcoded white would vanish on a near-white fill.
          foregroundColor: grayscale ? bg : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          backgroundColor: card,
          side: BorderSide(
            color: separator,
            width: viewingMode == ViewingMode.monoOutline ? 1.2 : 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((final states) {
            if (states.contains(WidgetState.selected)) {
              return effectiveAccent;
            }
            return viewingMode == ViewingMode.monoOutline ? card : fill;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((final states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return text;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: separator.withValues(
                alpha: viewingMode == ViewingMode.monoOutline ? 1 : 0.9,
              ),
              width: viewingMode == ViewingMode.monoOutline ? 1.2 : 1,
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          overlayColor: WidgetStatePropertyAll(
            effectiveAccent.withValues(alpha: 0.08),
          ),
          textStyle: WidgetStatePropertyAll(
            AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: separator, thickness: 1, space: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: separator.withValues(alpha: 0.4),
            width: viewingMode == ViewingMode.monoOutline ? 1.2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: separator.withValues(alpha: 0.4),
            width: viewingMode == ViewingMode.monoOutline ? 1.2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: effectiveAccent,
            width: viewingMode == ViewingMode.monoOutline ? 1.4 : 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: secondary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: effectiveAccent,
        unselectedItemColor: secondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.caption.copyWith(
          color: effectiveAccent,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTypography.caption.copyWith(
          color: secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
