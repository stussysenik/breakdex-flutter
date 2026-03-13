import 'dart:ui';

/// Depth system for layered z-index compositions with texture and materiality.
///
/// Each depth level defines visual properties that simulate physical distance
/// from the viewer: higher layers have more shadow spread, subtle scale
/// increase, and reduced background blur (closer objects are sharper).
///
/// Usage:
/// ```dart
/// final depth = AppDepth.elevated;
/// Transform.scale(scale: depth.scale, child: ...);
/// ```
abstract final class AppDepth {
  // -- Z-index semantic layers ------------------------------------------------

  /// Background elements (heatmaps, decorative textures).
  static const double zBackground = -1;

  /// Default content surface (cards, rows, panels).
  static const double zContent = 0;

  /// Raised interactive elements (FABs, toggle pills).
  static const double zRaised = 1;

  /// Floating overlays (bottom sheets, dialogs).
  static const double zOverlay = 2;

  /// Top-most layer (toasts, system alerts).
  static const double zTop = 3;

  // -- Per-depth visual properties --------------------------------------------

  static const DepthLevel sunken = DepthLevel(
    scale: 0.98,
    blurSigma: 0,
    shadowOpacity: 0.0,
    shadowOffset: Offset.zero,
    shadowBlur: 0,
    parallaxMultiplier: 0.0,
  );

  static const DepthLevel flat = DepthLevel(
    scale: 1.0,
    blurSigma: 0,
    shadowOpacity: 0.06,
    shadowOffset: Offset(0, 2),
    shadowBlur: 8,
    parallaxMultiplier: 0.0,
  );

  static const DepthLevel elevated = DepthLevel(
    scale: 1.0,
    blurSigma: 0,
    shadowOpacity: 0.12,
    shadowOffset: Offset(0, 4),
    shadowBlur: 16,
    parallaxMultiplier: 0.5,
  );

  static const DepthLevel floating = DepthLevel(
    scale: 1.005,
    blurSigma: 0,
    shadowOpacity: 0.18,
    shadowOffset: Offset(0, 8),
    shadowBlur: 28,
    parallaxMultiplier: 1.0,
  );

  static const DepthLevel overlay = DepthLevel(
    scale: 1.01,
    blurSigma: 20,
    shadowOpacity: 0.24,
    shadowOffset: Offset(0, 16),
    shadowBlur: 40,
    parallaxMultiplier: 1.5,
  );
}

/// Visual properties for a single depth level.
///
/// Immutable value object — can be used with `const` constructors for
/// zero-allocation lookups in hot widget builds.
class DepthLevel {
  const DepthLevel({
    required this.scale,
    required this.blurSigma,
    required this.shadowOpacity,
    required this.shadowOffset,
    required this.shadowBlur,
    required this.parallaxMultiplier,
  });

  /// Subtle scale applied to the widget (e.g. 1.005 for floating cards).
  final double scale;

  /// Background blur sigma for frosted-glass effects (0 = no blur).
  final double blurSigma;

  /// Shadow opacity (0.0–1.0) for the key-light shadow.
  final double shadowOpacity;

  /// Shadow offset direction simulating overhead key light.
  final Offset shadowOffset;

  /// Shadow blur radius in logical pixels.
  final double shadowBlur;

  /// Parallax movement multiplier for gyroscope/scroll effects.
  /// 0.0 = no movement (background), 1.0 = full parallax (foreground).
  final double parallaxMultiplier;
}
