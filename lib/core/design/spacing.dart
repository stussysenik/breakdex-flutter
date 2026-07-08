import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
  static const double screenEdge = 24;
}

abstract final class AppRadius {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 500;
}

/// IBM Carbon–inspired motion scale for consistent, purposeful animation.
///
/// **Motion doctrine — exactly two families** (redesign-visual-first-experience):
/// - **Fluid** — the default. Opacity + translation only. Flow transitions ride
///   [fluid] ([productive]); appearances ride [entrance]. Durations live in the
///   `fast01`–`moderate02` band.
/// - **Morph** — continuity of one persistent identity (size/shape/position).
///   Reserved for state changes of a single element; rides [morph]
///   ([springGentle]).
///
/// Delight overshoot ([expressive], [springBouncy]) is a budget: allowed only
/// with a justified call-site comment. Ambient loops and sequenced celebrations
/// fall outside the two transition families; their durations are named here
/// ([shimmerLoop], [celebrate]) so no raw literal escapes onto a product surface.
abstract final class AppMotion {
  static const fast01 = Duration(milliseconds: 70);
  static const fast02 = Duration(milliseconds: 110);
  static const moderate01 = Duration(milliseconds: 150);
  static const moderate02 = Duration(milliseconds: 240);
  static const slow01 = Duration(milliseconds: 400);
  static const Curve productive = Curves.easeInOutCubic;
  static const Curve expressive = Curves.easeOutBack;
  static const Curve entrance = Curves.easeOut;

  /// Gentle spring for layout transitions (expanding panels, card reorder).
  /// Low overshoot, smooth settle — feels physical without being playful.
  static final Curve springGentle = _SpringCurve(
    const SpringDescription(mass: 1, stiffness: 200, damping: 15),
  );

  /// Bouncy spring for delight moments (FAB entrance, success check, card flip).
  /// Visible overshoot and settle — playful "pop" that draws attention.
  static final Curve springBouncy = _SpringCurve(
    const SpringDescription(mass: 1, stiffness: 150, damping: 10),
  );

  // --- Motion families (doctrine) ---
  // Reference these aliases so the family a call site belongs to is legible.

  /// **Fluid** default curve — flow transitions (opacity/translation). Alias
  /// of [productive]; appearances use [entrance] instead.
  static const Curve fluid = productive;

  /// **Morph** curve — continuity of one persistent identity. Alias of
  /// [springGentle].
  static final Curve morph = springGentle;

  // --- Ambient durations (outside the two transition families) ---

  /// Repeating shimmer/skeleton loop.
  static const shimmerLoop = Duration(milliseconds: 1200);

  /// One half-sweep of the signature two-dot loader (dots slide and cross,
  /// then return — a full cross-and-return is two of these). Ambient loop.
  static const loaderLoop = Duration(milliseconds: 800);

  /// Sequenced one-shot celebration overlay.
  static const celebrate = Duration(milliseconds: 1500);
}

/// Maps a [SpringSimulation] onto the 0→1 Curve contract.
///
/// The simulation runs from displacement 0→1 with zero initial velocity.
/// We clamp the output to [0, 1] because spring overshoot can momentarily
/// exceed 1.0 (that overshoot is the visible "bounce").
class _SpringCurve extends Curve {
  _SpringCurve(final SpringDescription spring)
      : _simulation = SpringSimulation(spring, 0, 1, 0);

  final SpringSimulation _simulation;

  @override
  double transformInternal(final double t) {
    // SpringSimulation.x(t) returns displacement at time `t` (seconds).
    // We treat the 0→1 curve parameter as 0→3 seconds — long enough for
    // any reasonable spring to settle, short enough to avoid wasted frames.
    return _simulation.x(t * 3).clamp(0.0, 1.0);
  }
}
