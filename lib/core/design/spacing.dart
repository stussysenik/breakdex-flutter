import 'package:flutter/animation.dart';

abstract final class AppSpacing {
  static const double screenEdge = 20;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 30;
}

/// IBM Carbon–inspired motion scale for consistent, purposeful animation.
///
/// Two curve families:
/// - **Productive**: used for transitions that move the user through a flow
///   (page changes, expanding panels). [Curves.easeInOutCubic] gives a
///   symmetrical acceleration/deceleration that feels efficient.
/// - **Expressive**: used for feedback & delight (success checkmarks, FAB
///   entrance). [Curves.easeOutBack] overshoots slightly then settles,
///   producing a playful "pop."
/// - **Entrance**: used for elements appearing on screen (fade-ins, slide-ups).
///   [Curves.easeOut] decelerates smoothly into rest position.
abstract final class AppMotion {
  static const fast01 = Duration(milliseconds: 70);
  static const fast02 = Duration(milliseconds: 110);
  static const moderate01 = Duration(milliseconds: 150);
  static const moderate02 = Duration(milliseconds: 240);
  static const slow01 = Duration(milliseconds: 400);
  static const Curve productive = Curves.easeInOutCubic;
  static const Curve expressive = Curves.easeOutBack;
  static const Curve entrance = Curves.easeOut;
}
