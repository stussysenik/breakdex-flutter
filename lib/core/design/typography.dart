import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Supported font families for the app.
///
/// Persisted as a string key in SharedPreferences ('font_family').
enum AppFontFamily {
  /// Inter — default. Clean, modern, highly legible sans-serif.
  inter('Inter'),

  /// Outfit — stylish geometric sans-serif for a premium feel.
  outfit('Outfit'),

  /// System font — SF Pro on iOS, Roboto on Android.
  system('System');

  final String displayName;
  const AppFontFamily(this.displayName);

  static AppFontFamily fromKey(String? key) => switch (key) {
        'outfit' => AppFontFamily.outfit,
        'system' => AppFontFamily.system,
        _ => AppFontFamily.inter,
      };

  String get key => name;
}

/// Builds [TextStyle]s for a given font family.
///
/// Uses Google Fonts for custom variants and the default Flutter
/// text style (which maps to SF Pro on iOS / Roboto on Android) for
/// the system option.
TextStyle _fontStyle(
  AppFontFamily family, {
  required double fontSize,
  required FontWeight fontWeight,
  double? letterSpacing,
  double? height,
}) {
  switch (family) {
    case AppFontFamily.inter:
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );
    case AppFontFamily.outfit:
      return GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );
    case AppFontFamily.system:
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );
  }
}

/// Central type scale following IBM Carbon productive scale (12/14/16/20/24/32) mapping.
///
/// The static fields use the default Inter. For user-selected fonts,
/// call the factory constructors or use the instance methods.
abstract final class AppTypography {
  // Default (Inter) styles — used throughout the app via static access
  static TextStyle get titleLarge => _inter(fontSize: 32, fontWeight: FontWeight.w700);
  static TextStyle get titleMedium => _inter(fontSize: 24, fontWeight: FontWeight.w600);
  static TextStyle get titleSmall => _inter(fontSize: 20, fontWeight: FontWeight.w500);
  static TextStyle get bodyMedium => _inter(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle get bodySmall => _inter(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle get caption => _inter(fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle get sectionHeader => _inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      );

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
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
      labelLarge: s(12, FontWeight.w600).copyWith(
        color: secondaryColor,
        letterSpacing: 2,
      ),
    );
  }
}
