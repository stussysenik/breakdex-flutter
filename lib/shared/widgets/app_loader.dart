import 'package:flutter/material.dart';

import '../../core/design/spacing.dart';

/// The signature Breakdex loading motif: two dots that slide along one track in
/// opposite phase and **cross paths** at center, then return.
///
/// This is the canonical Fluid-family loader — motion composes entirely from
/// [AppMotion] tokens ([AppMotion.fluid] curve, [AppMotion.loaderLoop]
/// duration). Prefer it over a bare [CircularProgressIndicator] so loading feels
/// like the same connected system everywhere.
class AppLoader extends StatefulWidget {
  const AppLoader({
    super.key,
    this.size = 8,
    this.color,
    this.semanticLabel = 'Loading',
  });

  /// Dot diameter in logical pixels; the track is [size] * 3 wide so the two
  /// dots have room to travel past each other.
  final double size;

  /// Dot color; defaults to the theme primary.
  final Color? color;

  /// Accessibility label announced while the loader is visible.
  final String semanticLabel;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.loaderLoop,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final dot = widget.size;
    final travel = dot * 2; // one dot slides across two-dot-widths of track.
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: SizedBox(
        width: dot * 3,
        height: dot,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (final context, final child) {
            // Fluid-curved position 0→1; the two dots read it in opposite phase
            // so they converge and cross at the midpoint of every sweep.
            final t = AppMotion.fluid.transform(_controller.value);
            return Stack(
              children: [
                _dot(color, t * travel),
                _dot(color, (1 - t) * travel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dot(final Color color, final double left) {
    return Positioned(
      left: left,
      top: 0,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
