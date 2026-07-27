// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:breakdex/core/design/spacing.dart';

/// A reusable press-feedback wrapper that scales down on tap-down and
/// springs back on release, with optional haptic feedback.
///
/// Respects [MediaQuery.disableAnimations] so users who prefer reduced
/// motion still get instant visual feedback without the spring overshoot.
///
/// Usage:
/// ```dart
/// Pressable(
///   onTap: () => context.go('/detail'),
///   child: MyCardWidget(),
/// )
/// ```
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleEnd = 0.98,
    this.haptic = true,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale factor when pressed (1.0 = no scale, 0.96 = noticeable press).
  final double scaleEnd;

  /// Whether to trigger haptic feedback on tap-down.
  final bool haptic;

  /// When false, disables interaction and press animation.
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.moderate01,
      reverseDuration: AppMotion.moderate02,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleEnd,
    ).animate(CurvedAnimation(
      parent: _controller,
      // Fluid press-in; springy release on the delight budget (expressive).
      curve: AppMotion.fluid,
      reverseCurve: AppMotion.expressive,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    if (widget.haptic) HapticFeedback.lightImpact();

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
