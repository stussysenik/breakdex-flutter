import 'package:flutter/material.dart';

abstract final class AppColors {
  // White/black foundation with a blue 10% accent for a sharper 60/30/10 split.
  static const lightBg = Color(0xFFF8FAFC);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightFill = Color(0xFFF1F5F9);
  static const lightText = Color(0xFF0B0D12);
  static const lightSecondary = Color(0xFF5A6272);
  static const lightSeparator = Color(0xFFD9E0EA);

  static const darkBg = Color(0xFF090B10);
  static const darkCard = Color(0xFF11141B);
  static const darkFill = Color(0xFF1A1F29);
  static const darkText = Color(0xFFF7FAFF);
  static const darkSecondary = Color(0xFFA7B1C2);
  static const darkSeparator = Color(0xFF283041);

  static const accent = Color(0xFF1F5EFF);

  static const monoLightBg = Color(0xFFF7F7F7);
  static const monoLightCard = Color(0xFFFFFFFF);
  static const monoLightFill = Color(0xFFF0F0F0);
  static const monoLightText = Color(0xFF111111);
  static const monoLightSecondary = Color(0xFF5F5F5F);
  static const monoLightSeparator = Color(0xFF111111);

  static const monoDarkBg = Color(0xFF090909);
  static const monoDarkCard = Color(0xFF111111);
  static const monoDarkFill = Color(0xFF181818);
  static const monoDarkText = Color(0xFFF4F4F4);
  static const monoDarkSecondary = Color(0xFFB3B3B3);
  static const monoDarkSeparator = Color(0xFFF4F4F4);

  // Learning states
  static const stateNew = Color(0xFFE45D7A);
  static const stateLearning = Color(0xFF2F6BFF);
  static const stateMastery = Color(0xFF1F8A70);

  // Review actions
  static const actionAgain = Color(0xFFC23B2A);
  static const actionHard = Color(0xFFB7791F);
  static const actionGood = Color(0xFF1F7A4F);
  static const actionEasy = Color(0xFF0D9F9A);

  // Deuteranopia-safe semantic ramp — Okabe–Ito palette, whose members stay
  // mutually distinguishable under red-green color-vision deficiency. Applied
  // to the app-controlled semantic signals (learning states + review ratings)
  // when AccessiblePalette.deuteranopia is active. Surfaces/accent are left
  // untouched — only the meaning-by-color signals swap.
  static const deuterStateNew = Color(0xFFE69F00); // amber
  static const deuterStateLearning = Color(0xFF0072B2); // blue
  static const deuterStateMastery = Color(0xFF009E73); // bluish green
  static const deuterActionAgain = Color(0xFFD55E00); // vermillion
  static const deuterActionHard = Color(0xFFE69F00); // amber
  static const deuterActionGood = Color(0xFF009E73); // bluish green
  static const deuterActionEasy = Color(0xFF0072B2); // blue
}
