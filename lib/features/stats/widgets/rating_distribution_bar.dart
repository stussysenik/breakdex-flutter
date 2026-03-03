import 'package:flutter/material.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';

class RatingDistributionBar extends StatelessWidget {
  const RatingDistributionBar({super.key, required this.distribution});

  final Map<String, int> distribution;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = distribution.values.fold(0, (a, b) => a + b);

    if (total == 0) {
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: Text('No reviews yet',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.secondary)),
        ),
      );
    }

    final again = distribution['AGAIN'] ?? 0;
    final hard = distribution['HARD'] ?? 0;
    final good = distribution['GOOD'] ?? 0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 32,
            child: CustomPaint(
              size: const Size(double.infinity, 32),
              painter: _DistributionPainter(
                again: again,
                hard: hard,
                good: good,
                total: total,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _LegendDot(
                color: AppColors.actionAgain,
                label: 'Again ${_pct(again, total)}'),
            const SizedBox(width: AppSpacing.md),
            _LegendDot(
                color: AppColors.actionHard,
                label: 'Hard ${_pct(hard, total)}'),
            const SizedBox(width: AppSpacing.md),
            _LegendDot(
                color: AppColors.actionGood,
                label: 'Good ${_pct(good, total)}'),
          ],
        ),
      ],
    );
  }

  String _pct(int value, int total) =>
      '${(value / total * 100).round()}%';
}

class _DistributionPainter extends CustomPainter {
  _DistributionPainter({
    required this.again,
    required this.hard,
    required this.good,
    required this.total,
  });

  final int again, hard, good, total;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    double x = 0;

    void drawSegment(int count, Color color) {
      if (count == 0) return;
      final w = size.width * count / total;
      paint.color = color;
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w;
    }

    drawSegment(again, AppColors.actionAgain);
    drawSegment(hard, AppColors.actionHard);
    drawSegment(good, AppColors.actionGood);
  }

  @override
  bool shouldRepaint(covariant _DistributionPainter old) =>
      old.again != again || old.hard != hard || old.good != good;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                )),
      ],
    );
  }
}
