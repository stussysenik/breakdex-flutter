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
  AppFontFamily.inter => 'Inter',
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
  static const _titleLargeSize = 30.0;
  static const _titleMediumSize = 24.0;
  static const _titleSmallSize = 20.0;
  static const _bodyMediumSize = 16.0;
  static const _bodySmallSize = 14.0;
  static const _captionSize = 12.0;

  // Default (Inter) styles — used throughout the app via static access
  static TextStyle get titleLarge => _base(
    fontSize: _titleLargeSize,
    fontWeight: FontWeight.w700,
    height: 36 / _titleLargeSize,
  );
  static TextStyle get titleMedium => _base(
    fontSize: _titleMediumSize,
    fontWeight: FontWeight.w600,
    height: 30 / _titleMediumSize,
  );
  static TextStyle get titleSmall => _base(
    fontSize: _titleSmallSize,
    fontWeight: FontWeight.w600,
    height: 26 / _titleSmallSize,
  );
  static TextStyle get bodyMedium => _base(
    fontSize: _bodyMediumSize,
    fontWeight: FontWeight.w400,
    height: 24 / _bodyMediumSize,
  );
  static TextStyle get bodyLarge => _base(
    fontSize: _bodyMediumSize,
    fontWeight: FontWeight.w400,
    height: 24 / _bodyMediumSize,
  );
  static TextStyle get bodySmall => _base(
    fontSize: _bodySmallSize,
    fontWeight: FontWeight.w400,
    height: 20 / _bodySmallSize,
  );
  static TextStyle get caption => _base(
    fontSize: _captionSize,
    fontWeight: FontWeight.w500,
    height: 16 / _captionSize,
  );
  static TextStyle get sectionHeader => _base(
    fontSize: _captionSize,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    height: 16 / _captionSize,
  );
  static TextStyle get labelLarge => _base(
    fontSize: _captionSize,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    height: 16 / _captionSize,
  );

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: 'Inter',
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
    TextStyle s(
      double size,
      FontWeight weight, {
      double? letterSpacing,
      double? height,
    }) => _fontStyle(
      family,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );

    return TextTheme(
      headlineLarge: s(
        _titleLargeSize,
        FontWeight.w700,
        height: 36 / _titleLargeSize,
      ).copyWith(color: textColor),
      headlineMedium: s(
        _titleMediumSize,
        FontWeight.w600,
        height: 30 / _titleMediumSize,
      ).copyWith(color: textColor),
      headlineSmall: s(
        _titleSmallSize,
        FontWeight.w600,
        height: 26 / _titleSmallSize,
      ).copyWith(color: textColor),
      bodyLarge: s(
        _bodyMediumSize,
        FontWeight.w400,
        height: 24 / _bodyMediumSize,
      ).copyWith(color: textColor),
      bodyMedium: s(
        _bodyMediumSize,
        FontWeight.w400,
        height: 24 / _bodyMediumSize,
      ).copyWith(color: textColor),
      bodySmall: s(
        _bodySmallSize,
        FontWeight.w400,
        height: 20 / _bodySmallSize,
      ).copyWith(color: secondaryColor),
      labelSmall: s(
        _captionSize,
        FontWeight.w500,
        height: 16 / _captionSize,
      ).copyWith(color: secondaryColor),
      labelLarge: s(
        _captionSize,
        FontWeight.w700,
        letterSpacing: 1.2,
        height: 16 / _captionSize,
      ).copyWith(color: secondaryColor),
    );
  }
}
