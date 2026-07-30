// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:breakdex/core/design/theme.dart';

class StreakBurst extends StatefulWidget {
  const StreakBurst({super.key, required this.trigger});

  final int trigger; // Rebuilds animation on change

  @override
  State<StreakBurst> createState() => _StreakBurstState();
}

class _StreakBurstState extends State<StreakBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = Random();
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _particles = _generateParticles();
    _controller.forward();
  }

  @override
  void didUpdateWidget(final StreakBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _particles = _generateParticles();
      _controller.forward(from: 0);
    }
  }

  List<_Particle> _generateParticles() => List.generate(12, (_) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 40.0 + _random.nextDouble() * 60;
        return _Particle(
          dx: cos(angle) * speed,
          dy: sin(angle) * speed,
          size: 4.0 + _random.nextDouble() * 4,
        );
      });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (final context, _) {
        return CustomPaint(
          size: const Size(120, 120),
          painter: _BurstPainter(
            particles: _particles,
            progress: _controller.value,
            color: AppSemanticTheme.of(context).actionGood,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double dx, dy, size;
  const _Particle({required this.dx, required this.dy, required this.size});
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  final List<_Particle> particles;
  final double progress;

  /// A painter has no `BuildContext`, so the resolved signal is passed in
  /// rather than read — the read happens in `build`, where the theme lives.
  final Color color;

  @override
  void paint(final Canvas canvas, final Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: opacity);
      final offset = Offset(
        center.dx + p.dx * progress,
        center.dy + p.dy * progress,
      );
      canvas.drawCircle(offset, p.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant final _BurstPainter old) =>
      old.progress != progress;
}
