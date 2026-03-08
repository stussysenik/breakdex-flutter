import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Supported font families for the app.
///
/// Persisted as a string key in SharedPreferences ('font_family').
enum AppFontFamily {
  /// Inter — default. Clean, modern, highly legible sans-serif.
  inter('Inter'),

  /// Outfit — stylish geometric sans-serif for a premium feel.
  outfit('Outfit'),

  /// Poppins — friendly geometric sans-serif with rounded terminals.
  poppins('Poppins'),

  /// Space Mono — fixed-width font with a retro-futuristic vibe.
  spaceMono('Space Mono'),

  /// JetBrains Mono — developer-oriented monospace with ligatures.
  jetBrainsMono('JetBrains Mono'),

  /// System font — SF Pro on iOS, Roboto on Android.
  system('System');

  final String displayName;
  const AppFontFamily(this.displayName);

  static AppFontFamily fromKey(String? key) => switch (key) {
    'outfit' => AppFontFamily.outfit,
    'poppins' => AppFontFamily.poppins,
    'spaceMono' => AppFontFamily.spaceMono,
    'jetBrainsMono' => AppFontFamily.jetBrainsMono,
    'system' => AppFontFamily.system,
    _ => AppFontFamily.inter,
  };

  String get key => name;
}

/// Builds [TextStyle]s for a given font family.
///
TextStyle _fontStyle(
  AppFontFamily family, {
  required double fontSize,
  required FontWeight fontWeight,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: _resolvedFontFamily(family),
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

String? _resolvedFontFamily(AppFontFamily family) => switch (family) {
  AppFontFamily.spaceMono ||
  AppFontFamily.jetBrainsMono => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => 'Menlo',
    _ => 'monospace',
  },
  _ => null,
};

/// Central type scale following IBM Carbon productive scale (12/14/16/20/24/32) mapping.
///
/// The static fields use the default Inter. For user-selected fonts,
/// call the factory constructors or use the instance methods.
abstract final class AppTypography {
  // Default (Inter) styles — used throughout the app via static access
  static TextStyle get titleLarge =>
      _base(fontSize: 32, fontWeight: FontWeight.w700);
  static TextStyle get titleMedium =>
      _base(fontSize: 24, fontWeight: FontWeight.w600);
  static TextStyle get titleSmall =>
      _base(fontSize: 20, fontWeight: FontWeight.w500);
  static TextStyle get bodyMedium =>
      _base(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle get bodySmall =>
      _base(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle get caption =>
      _base(fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle get sectionHeader =>
      _base(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2);

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// Build a complete [TextTheme] for the given font family and colors.
  ///
  /// This is what [AppTheme] uses to construct the Material theme. When the
  /// user changes their font preference, the theme rebuilds with the new
  /// family and all text respects the selection.
  static TextTheme textTheme(
    Color textColor,
    Color secondaryColor, {
    AppFontFamily family = AppFontFamily.inter,
  }) {
    TextStyle s(double size, FontWeight weight) =>
        _fontStyle(family, fontSize: size, fontWeight: weight);

    return TextTheme(
      headlineLarge: s(32, FontWeight.w700).copyWith(color: textColor),
      headlineMedium: s(24, FontWeight.w600).copyWith(color: textColor),
      headlineSmall: s(20, FontWeight.w500).copyWith(color: textColor),
      bodyLarge: s(16, FontWeight.w400).copyWith(color: textColor),
      bodyMedium: s(16, FontWeight.w400).copyWith(color: textColor),
      bodySmall: s(14, FontWeight.w400).copyWith(color: secondaryColor),
      labelSmall: s(12, FontWeight.w400).copyWith(color: secondaryColor),
      labelLarge: s(
        12,
        FontWeight.w600,
      ).copyWith(color: secondaryColor, letterSpacing: 2),
    );
  }
}
