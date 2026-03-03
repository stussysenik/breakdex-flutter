import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/design/colors.dart';

class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.timeRemaining,
    required this.totalTime,
  });

  final double timeRemaining;
  final double totalTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (timeRemaining / totalTime).clamp(0.0, 1.0);

    // Color lerps from accent to red as time depletes
    final ringColor = Color.lerp(
      AppColors.actionAgain,
      AppColors.accent,
      progress,
    )!;

    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: _TimerRingPainter(
          progress: progress,
          ringColor: ringColor,
          trackColor: cs.surfaceContainerHighest,
          brightness: Theme.of(context).brightness,
        ),
        child: Center(
          child: Text(
            '${timeRemaining.ceil()}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ringColor,
                ),
          ),
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  _TimerRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.brightness,
  });

  final double progress;
  final Color ringColor;
  final Color trackColor;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );

    // Dot at arc tip
    if (progress > 0) {
      final angle = -pi / 2 + sweepAngle;
      final dotCenter = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final dotPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}
