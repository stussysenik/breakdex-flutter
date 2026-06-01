import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/design/colors.dart';
import '../../core/design/typography.dart';

/// Full-screen particle celebration overlay.
/// Shows confetti burst + combo name, auto-dismisses after 1.5s.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.title,
    this.onDismiss,
  });

  final String title;
  final VoidCallback? onDismiss;

  /// Show as an overlay entry on top of the current screen.
  static void show(final BuildContext context, {required final String title}) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => CelebrationOverlay(
        title: title,
        onDismiss: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  late final Animation<double> _titleScale;
  late final Animation<double> _fade;
  final _random = Random();

  static const _particleCount = 28;
  static const _baseColors = [
    AppColors.stateNew,
    AppColors.stateLearning,
    AppColors.stateMastery,
    AppColors.actionGood,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _titleScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.3, curve: Curves.elasticOut),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _particles = List.generate(_particleCount, (_) => _Particle(_random));

    _controller.forward();
    _controller.addStatusListener((final status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (final context, _) {
          final opacity = 1.0 - _fade.value;
          final colors = [
            ..._baseColors,
            Theme.of(context).colorScheme.primary,
          ];

          return Opacity(
            opacity: opacity,
            child: Material(
              color: Colors.black.withValues(alpha: 0.4 * opacity),
              child: Stack(
                children: [
                  // Particles
                  CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _controller.value,
                      colors: colors,
                    ),
                  ),

                  // Title
                  Center(
                    child: Transform.scale(
                      scale: _titleScale.value.clamp(0.0, 1.0),
                      child: Text(
                        widget.title,
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final int colorIndex;
  final double rotationSpeed;

  _Particle(final Random r)
      : angle = r.nextDouble() * 2 * pi,
        speed = 200 + r.nextDouble() * 400,
        size = 4 + r.nextDouble() * 8,
        colorIndex = r.nextInt(5),
        rotationSpeed = (r.nextDouble() - 0.5) * 10;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final List<Color> colors;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.colors,
  });

  @override
  void paint(final Canvas canvas, final Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gravity = size.height * 0.8;

    for (final p in particles) {
      final t = progress;
      final dx = cos(p.angle) * p.speed * t;
      final dy = sin(p.angle) * p.speed * t + gravity * t * t * 0.5;
      final pos = center + Offset(dx, dy);

      // Fade out particles as animation progresses
      final alpha = (1.0 - (t * 0.8)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = colors[p.colorIndex].withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rotationSpeed * t);

      // Mix of circles and small rectangles for confetti look
      if (p.colorIndex % 2 == 0) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.5,
            ),
            Radius.circular(p.size * 0.15),
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(final _ParticlePainter old) => old.progress != progress;
}
