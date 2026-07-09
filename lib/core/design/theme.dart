import 'package:flutter/material.dart';
import '../models/learning_state.dart';
import '../models/learning_state_colors.dart';
import '../services/settings_service.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

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
  AppSemanticTheme lerp(final ThemeExtension<AppSemanticTheme>? other, final double t) {
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

  Color stateColor(final LearningState state) => semanticTheme.colorForState(state);
}

abstract final class AppTheme {
  static ThemeData light({
    final AppFontFamily family = AppFontFamily.inter,
    final Color accent = AppColors.accent,
    final LearningStateColors stateColors = LearningStateColors.defaults,
    final ViewingMode viewingMode = ViewingMode.standard,
    final AccessiblePalette palette = AccessiblePalette.standard,
  }) {
    // monoOutline and monochrome both render on the grayscale surface ramp.
    final gray =
        viewingMode == ViewingMode.monoOutline ||
        palette == AccessiblePalette.monochrome;
    return _build(
      brightness: Brightness.light,
      bg: gray ? AppColors.monoLightBg : AppColors.lightBg,
      card: gray ? AppColors.monoLightCard : AppColors.lightCard,
      fill: gray ? AppColors.monoLightFill : AppColors.lightFill,
      text: gray ? AppColors.monoLightText : AppColors.lightText,
      secondary: gray ? AppColors.monoLightSecondary : AppColors.lightSecondary,
      separator: gray ? AppColors.monoLightSeparator : AppColors.lightSeparator,
      family: family,
      accent: accent,
      stateColors: stateColors,
      viewingMode: viewingMode,
      palette: palette,
    );
  }

  static ThemeData dark({
    final AppFontFamily family = AppFontFamily.inter,
    final Color accent = AppColors.accent,
    final LearningStateColors stateColors = LearningStateColors.defaults,
    final ViewingMode viewingMode = ViewingMode.standard,
    final AccessiblePalette palette = AccessiblePalette.standard,
  }) {
    final gray =
        viewingMode == ViewingMode.monoOutline ||
        palette == AccessiblePalette.monochrome;
    return _build(
      brightness: Brightness.dark,
      bg: gray ? AppColors.monoDarkBg : AppColors.darkBg,
      card: gray ? AppColors.monoDarkCard : AppColors.darkCard,
      fill: gray ? AppColors.monoDarkFill : AppColors.darkFill,
      text: gray ? AppColors.monoDarkText : AppColors.darkText,
      secondary: gray ? AppColors.monoDarkSecondary : AppColors.darkSecondary,
      separator: gray ? AppColors.monoDarkSeparator : AppColors.darkSeparator,
      family: family,
      accent: accent,
      stateColors: stateColors,
      viewingMode: viewingMode,
      palette: palette,
    );
  }

  static ThemeData _build({
    required final Brightness brightness,
    required final Color bg,
    required final Color card,
    required final Color fill,
    required final Color text,
    required final Color secondary,
    required final Color separator,
    required final AppFontFamily family,
    required final Color accent,
    required final LearningStateColors stateColors,
    required final ViewingMode viewingMode,
    required final AccessiblePalette palette,
  }) {
    final isMonoOutline = viewingMode == ViewingMode.monoOutline;
    // Any grayscale mode (marker outline or monochrome palette) tones the accent
    // to ink so no color survives; the deuteranopia palette keeps the accent.
    final grayscale = isMonoOutline || palette == AccessiblePalette.monochrome;
    final effectiveAccent = grayscale ? text : accent;
    final semanticTheme = switch ((isMonoOutline, palette)) {
      // Marker outline keeps its distinctive outline flag + ink ramp.
      (true, _) => AppSemanticTheme.ink(text, isMonoOutline: true),
      // Monochrome: ink ramp, but filled surfaces (isMonoOutline stays false).
      (false, AccessiblePalette.monochrome) => AppSemanticTheme.ink(text),
      (false, AccessiblePalette.deuteranopia) => AppSemanticTheme.deuteranopia,
      (false, AccessiblePalette.standard) => AppSemanticTheme.defaults.copyWith(
        stateNew: stateColors.newState,
        stateLearning: stateColors.learning,
        stateMastery: stateColors.mastery,
      ),
    };
    final textTheme = AppTypography.textTheme(text, secondary, family: family);
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: effectiveAccent,
      onPrimary: grayscale ? bg : Colors.white,
      secondary: secondary,
      onSecondary: text,
      surface: card,
      onSurface: text,
      error: AppColors.actionAgain,
      onError: Colors.white,
      surfaceContainerHighest: fill,
      outline: separator,
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [semanticTheme],
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
