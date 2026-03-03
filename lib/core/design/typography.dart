import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextStyle _plex({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );

  static final titleLarge = _plex(fontSize: 32, fontWeight: FontWeight.w700);
  static final titleMedium = _plex(fontSize: 24, fontWeight: FontWeight.w600);
  static final titleSmall = _plex(fontSize: 20, fontWeight: FontWeight.w500);
  static final bodyMedium = _plex(fontSize: 16, fontWeight: FontWeight.w400);
  static final bodySmall = _plex(fontSize: 14, fontWeight: FontWeight.w400);
  static final caption = _plex(fontSize: 12, fontWeight: FontWeight.w400);
  static final sectionHeader = _plex(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
  );

  static TextTheme textTheme(Color textColor, Color secondaryColor) =>
      TextTheme(
        headlineLarge: titleLarge.copyWith(color: textColor),
        headlineMedium: titleMedium.copyWith(color: textColor),
        headlineSmall: titleSmall.copyWith(color: textColor),
        bodyLarge: bodyMedium.copyWith(color: textColor),
        bodyMedium: bodyMedium.copyWith(color: textColor),
        bodySmall: bodySmall.copyWith(color: secondaryColor),
        labelSmall: caption.copyWith(color: secondaryColor),
        labelLarge: sectionHeader.copyWith(color: secondaryColor),
      );
}
