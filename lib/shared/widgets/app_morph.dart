import 'package:flutter/material.dart';

import 'package:breakdex/core/design/spacing.dart';

/// **Morph** — the one way this app declares a shared element.
///
/// The motion doctrine (CLAUDE.md → Motion doctrine) names two families, and
/// Morph is the one for *continuity of a single persistent identity*: one thing
/// changing size, shape or position rather than two things swapping. A shared
/// element is the purest case of that — the same surface, in two places, at two
/// sizes — so this type exists to make Morph the **default** for it rather than
/// a curve each call site remembers to pass.
///
/// The curve does not live in the transition, it lives in the *tween of the
/// shape*: [morphRectTween] applies [AppMotion.morph] to the flight's own
/// rect interpolation. A raw `Hero` rides the route's animation linearly, which
/// is the Fluid feel applied to a Morph problem. Every shared element in the app
/// goes through this widget, and `morph_conformance_test.dart` fails the gate on
/// a raw `Hero(` anywhere under `lib/`.
///
/// The path stays a straight line on purpose — no Material arc. The spring is
/// the expression; bending the trajectory as well would be a second opinion
/// about the same motion.
///
/// Honours [MediaQueryData.disableAnimations]: with reduced motion the child is
/// returned unwrapped, so there is no flight at all rather than a fast one.
class AppMorph extends StatelessWidget {
  const AppMorph({required this.identifier, required this.child, super.key});

  /// Both ends of a flight carry the same [identifier]. It is the Hero tag, and
  /// it is a string for the same reason `AppRow.identifier` is: it is the stable
  /// handle a driver and a test can both name.
  final String identifier;

  final Widget child;

  /// The rect interpolation every flight in this app uses.
  ///
  /// Exposed (and unit-tested) because it *is* the ruling: shape continuity is
  /// timed by [AppMotion.morph], not by whatever curve the route happens to run.
  static RectTween morphRectTween(final Rect? begin, final Rect? end) =>
      _MorphRectTween(begin: begin, end: end);

  /// The travelling surface itself: a plain filled rectangle, nothing else.
  ///
  /// A shared element that carries content has to render that content at both
  /// sizes, and a row's worth of text laid out at page size (or the reverse) is
  /// how container transforms acquire overflow. So the thing that travels is the
  /// *container*, and the content of each end fades on its own schedule.
  static Widget surface({
    required final String identifier,
    final double radius = 0,
    final Color? color,
  }) => _MorphSurface(identifier: identifier, radius: radius, color: color);

  /// Places [surface] behind [child] — the source end of a flight, on the
  /// control that opens the screen.
  static Widget behind({
    required final String identifier,
    required final Widget child,
    // The same radius the row's own ink already uses, so at rest the surface
    // is invisible and at the start of a flight it is exactly the row.
    final double radius = AppRadius.sm,
  }) => Stack(
    children: [
      Positioned.fill(child: surface(identifier: identifier, radius: radius)),
      child,
    ],
  );

  /// The key the travelling surface carries, so a test can measure the one
  /// instance that exists mid-flight (both route ends render a placeholder).
  static Key surfaceKey(final String identifier) =>
      Key('morph-surface-$identifier');

  @override
  Widget build(final BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return Hero(
      tag: identifier,
      createRectTween: morphRectTween,
      child: child,
    );
  }
}

class _MorphSurface extends StatelessWidget {
  const _MorphSurface({
    required this.identifier,
    required this.radius,
    required this.color,
  });

  final String identifier;
  final double radius;
  final Color? color;

  @override
  Widget build(final BuildContext context) => AppMorph(
    identifier: identifier,
    child: DecoratedBox(
      key: AppMorph.surfaceKey(identifier),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

/// A [RectTween] that spends its `t` on [AppMotion.morph] before interpolating.
///
/// `Hero` drives `createRectTween` with the route's raw animation value, so this
/// is the only place a shared element can be given a curve of its own.
class _MorphRectTween extends RectTween {
  _MorphRectTween({super.begin, super.end});

  @override
  Rect? lerp(final double t) => super.lerp(AppMotion.morph.transform(t));
}
