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
///
/// The curve parameter is normalised onto the spring's **own settle time**, not
/// onto a fixed window. A fixed 3-second window (what this did until 2026-08-02)
/// made `springGentle` reach 1.0 at about t=0.2, so four fifths of every
/// animation's duration was the spring sitting still: a 240ms transition showed
/// ~40ms of motion and read as a pop, not a spring. Asking the simulation when
/// it is done makes the duration at the call site mean what it says.
class _SpringCurve extends Curve {
  _SpringCurve(final SpringDescription spring)
      : _simulation = SpringSimulation(spring, 0, 1, 0) {
    _settleTime = _findSettleTime();
  }

  final SpringSimulation _simulation;

  /// Seconds of simulation the 0→1 curve parameter is stretched across.
  late final double _settleTime;

  double _findSettleTime() {
    // 1ms resolution, capped at 3s — the same ceiling the fixed window used, so
    // a pathological (near-undamped) spring degrades to the old behaviour
    // instead of hanging.
    for (var ms = 1; ms <= 3000; ms++) {
      if (_simulation.isDone(ms / 1000)) return ms / 1000;
    }
    return 3;
  }

  @override
  double transformInternal(final double t) =>
      _simulation.x(t * _settleTime).clamp(0.0, 1.0);
}
