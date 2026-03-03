import 'package:flutter/material.dart';

abstract final class AppColors {
  // Light mode
  static const lightBg = Color(0xFFF8F9FB);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightFill = Color(0xFFEDF0F5);
  static const lightText = Color(0xFF101114);
  static const lightSecondary = Color(0xFF5C626A);
  static const lightSeparator = Color(0xFFDCE0E6);

  // Dark mode
  static const darkBg = Color(0xFF0B0C0E);
  static const darkCard = Color(0xFF14181E);
  static const darkFill = Color(0xFF181B21);
  static const darkText = Color(0xFFF5F6F8);
  static const darkSecondary = Color(0xFFA2AAB4);
  static const darkSeparator = Color(0xFF262A32);

  // Accent (shared)
  static const accent = Color(0xFF2362A2);

  // Learning states
  static const stateNew = Color(0xFFFF7EB6);
  static const stateLearning = Color(0xFF33B1FF);
  static const stateMastery = Color(0xFF8A3FFC);

  // Review actions
  static const actionAgain = Color(0xFFDA1E28);
  static const actionHard = Color(0xFFF1C21B);
  static const actionGood = Color(0xFF42BE65);
}
