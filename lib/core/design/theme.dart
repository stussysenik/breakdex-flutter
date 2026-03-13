import 'package:flutter/material.dart';
import '../models/learning_state.dart';
import '../services/settings_service.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

abstract final class AppShadows {
  static List<BoxShadow> soft(Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.light
          ? const Color(0x140F0B08)
          : const Color(0x42000000),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> raised(Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.light
          ? const Color(0x1A0F0B08)
          : const Color(0x52000000),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> focus(Brightness brightness) => [
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
  static List<BoxShadow> layered(Brightness brightness) => [
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
  Widget build(BuildContext context) {
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
    BuildContext context, {
    AppSurfaceTone tone = AppSurfaceTone.base,
    bool raised = false,
    bool focused = false,
    double radius = AppRadius.md,
    Color? borderColor,
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

  Color colorForState(LearningState state) => switch (state) {
    LearningState.newState => stateNew,
    LearningState.learning => stateLearning,
    LearningState.mastery => stateMastery,
  };

  Color colorForRating(ReviewRating rating) => switch (rating) {
    ReviewRating.again => actionAgain,
    ReviewRating.hard => actionHard,
    ReviewRating.good => actionGood,
    ReviewRating.easy => actionEasy,
  };

  static AppSemanticTheme of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticTheme>()!;

  @override
  AppSemanticTheme copyWith({
    bool? isMonoOutline,
    Color? stateNew,
    Color? stateLearning,
    Color? stateMastery,
    Color? actionAgain,
    Color? actionHard,
    Color? actionGood,
    Color? actionEasy,
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
  AppSemanticTheme lerp(ThemeExtension<AppSemanticTheme>? other, double t) {
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

abstract final class AppTheme {
  static ThemeData light({
    AppFontFamily family = AppFontFamily.inter,
    Color accent = AppColors.accent,
    ViewingMode viewingMode = ViewingMode.standard,
  }) => _build(
    brightness: Brightness.light,
    bg: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoLightBg
        : AppColors.lightBg,
    card: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoLightCard
        : AppColors.lightCard,
    fill: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoLightFill
        : AppColors.lightFill,
    text: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoLightText
        : AppColors.lightText,
    secondary: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoLightSecondary
        : AppColors.lightSecondary,
    separator: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoLightSeparator
        : AppColors.lightSeparator,
    family: family,
    accent: accent,
    viewingMode: viewingMode,
  );

  static ThemeData dark({
    AppFontFamily family = AppFontFamily.inter,
    Color accent = AppColors.accent,
    ViewingMode viewingMode = ViewingMode.standard,
  }) => _build(
    brightness: Brightness.dark,
    bg: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoDarkBg
        : AppColors.darkBg,
    card: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoDarkCard
        : AppColors.darkCard,
    fill: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoDarkFill
        : AppColors.darkFill,
    text: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoDarkText
        : AppColors.darkText,
    secondary: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoDarkSecondary
        : AppColors.darkSecondary,
    separator: viewingMode == ViewingMode.monoOutline
        ? AppColors.monoDarkSeparator
        : AppColors.darkSeparator,
    family: family,
    accent: accent,
    viewingMode: viewingMode,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color card,
    required Color fill,
    required Color text,
    required Color secondary,
    required Color separator,
    required AppFontFamily family,
    required Color accent,
    required ViewingMode viewingMode,
  }) {
    final effectiveAccent = viewingMode == ViewingMode.monoOutline
        ? text
        : accent;
    final semanticTheme = viewingMode == ViewingMode.monoOutline
        ? AppSemanticTheme(
            isMonoOutline: true,
            stateNew: text,
            stateLearning: text,
            stateMastery: text,
            actionAgain: text,
            actionHard: text,
            actionGood: text,
            actionEasy: text,
          )
        : const AppSemanticTheme(
            isMonoOutline: false,
            stateNew: AppColors.stateNew,
            stateLearning: AppColors.stateLearning,
            stateMastery: AppColors.stateMastery,
            actionAgain: AppColors.actionAgain,
            actionHard: AppColors.actionHard,
            actionGood: AppColors.actionGood,
            actionEasy: AppColors.actionEasy,
          );
    final textTheme = AppTypography.textTheme(text, secondary, family: family);
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: effectiveAccent,
      onPrimary: viewingMode == ViewingMode.monoOutline ? bg : Colors.white,
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
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return effectiveAccent;
            }
            return viewingMode == ViewingMode.monoOutline ? card : fill;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
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
      ),
    );
  }
}
