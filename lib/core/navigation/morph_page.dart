import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/shared/widgets/app_morph.dart';

/// The shared element between the Add screen's combo row and `/create-combo`.
///
/// Both ends import this constant, so the two halves of the flight cannot drift
/// apart by a typo.
const String createComboMorphId = 'create-combo';

/// A route that arrives by **Morph**: the control that opened it grows into the
/// page, and the page's content fades in over the shape once it is travelling.
///
/// This is the doctrine's answer to "what is the default for layout/shape
/// continuity" (CLAUDE.md → Motion doctrine). `settingsSectionPage` is the Fluid
/// counterpart — a view *replacing* a view, so it rises and fades. Here one
/// surface is *becoming* another, so the surface is a single persistent identity
/// carried by [AppMorph] and the fade is only what rides on top of it.
///
/// A push from a control that carries no matching [AppMorph] simply does not
/// fly: Hero with an unmatched tag is a no-op, so the other three call sites
/// that open `/create-combo` keep a plain fade and nothing asserts.
/// The destination end of the flight lives in the page's **child**, never in
/// its `transitionsBuilder`. `ModalRoute.subtreeContext` — the context Flutter
/// searches for heroes when a route is pushed — points at `buildPage`'s output
/// only; everything a `buildTransitions` adds is a wrapper *outside* it. A Hero
/// declared there is silently never found, and the push just fades. Proved by
/// bisection: the same widget under `builder:` flies, under `transitionsBuilder`
/// it does not.
CustomTransitionPage<T> morphPage<T>({
  required final LocalKey key,
  required final String identifier,
  required final Widget child,
}) => CustomTransitionPage<T>(
  key: key,
  transitionDuration: AppMotion.moderate02,
  reverseTransitionDuration: AppMotion.moderate01,
  child: MorphDestination(identifier: identifier, child: child),
  transitionsBuilder:
      (final context, final animation, final secondaryAnimation, final child) {
        if (MediaQuery.of(context).disableAnimations) return child;
        // Fluid rides on top: the page's content is not what morphs, it is what
        // appears once the shape has arrived. The surface underneath it is a
        // placeholder for the whole flight, so nothing is drawn twice.
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: AppMotion.entrance)),
          child: child,
        );
      },
);

/// The page-sized end of a morph, behind [child].
///
/// It stays in the tree after the transition completes — a shared element has to
/// exist at rest for the reverse flight to have somewhere to land.
class MorphDestination extends StatelessWidget {
  const MorphDestination({
    required this.identifier,
    required this.child,
    super.key,
  });

  final String identifier;
  final Widget child;

  @override
  Widget build(final BuildContext context) => Stack(
    children: [
      Positioned.fill(child: AppMorph.surface(identifier: identifier)),
      child,
    ],
  );
}
