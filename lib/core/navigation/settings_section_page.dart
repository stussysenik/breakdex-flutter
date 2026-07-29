import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/design/spacing.dart';

/// The transition every `/settings-panel*` route opens with.
///
/// Settings is the one place in the app where a full view replaces another full
/// view of the same family, so the transition has to read as *entering a
/// section* rather than as a generic push. It composes the two sanctioned
/// motion families (CLAUDE.md → Motion doctrine) and nothing else:
///
/// - **Fluid** ([AppMotion.entrance] / [AppMotion.fluid]) — the arriving section
///   fades up into place over a short rise.
/// - **Morph** ([AppMotion.morph]) — the view it covers stays one persistent
///   surface and settles back on the gentle spring, so the two views read as
///   depth in one stack instead of two unrelated pages.
///
/// Honours [MediaQueryData.disableAnimations]: with reduced motion the child is
/// returned unwrapped, so the route cuts rather than animates.
CustomTransitionPage<void> settingsSectionPage({
  required final LocalKey key,
  required final Widget child,
}) => CustomTransitionPage<void>(
  key: key,
  transitionDuration: AppMotion.moderate02,
  reverseTransitionDuration: AppMotion.moderate01,
  child: child,
  transitionsBuilder:
      (final context, final animation, final secondaryAnimation, final child) =>
          SettingsSectionTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          ),
);

/// The motion of [settingsSectionPage], as a widget so it can be tested and
/// reused without a router.
class SettingsSectionTransition extends StatelessWidget {
  const SettingsSectionTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    super.key,
  });

  /// How far the arriving section rises, as a fraction of its own height.
  static const double riseFraction = 0.06;

  /// How far the covered view scales back while it is behind the section.
  static const double recedeScale = 0.96;

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }

    // Fluid — appearance rides `entrance`, movement rides `fluid`.
    final fade = animation.drive(CurveTween(curve: AppMotion.entrance));
    final rise = animation.drive(
      Tween<Offset>(
        begin: const Offset(0, riseFraction),
        end: Offset.zero,
      ).chain(CurveTween(curve: AppMotion.fluid)),
    );

    // Morph — one surface changing shape, so it rides the gentle spring.
    final recede = secondaryAnimation.drive(
      Tween<double>(
        begin: 1,
        end: recedeScale,
      ).chain(CurveTween(curve: AppMotion.morph)),
    );

    return SlideTransition(
      position: rise,
      child: FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: recede, child: child),
      ),
    );
  }
}
