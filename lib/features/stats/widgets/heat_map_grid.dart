import 'package:flutter/material.dart';
import '../../../core/design/colors.dart';

class HeatMapGrid extends StatelessWidget {
  const HeatMapGrid({super.key, required this.dailyCounts});

  final Map<DateTime, int> dailyCounts;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build 52 weeks of data ending today
    // Find the Sunday that starts the grid (52 weeks ago, aligned to week start)
    final daysFromMonday = today.weekday - 1; // Monday = 0
    final thisWeekMonday = today.subtract(Duration(days: daysFromMonday));
    final startDate = thisWeekMonday.subtract(const Duration(days: 51 * 7));

    // Compute max for intensity scaling
    final maxCount = dailyCounts.values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 7 * 15.0 + 20, // 7 rows * (12+3) + month labels
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Start scrolled to the right (most recent)
            child: CustomPaint(
              size: Size(52 * 15.0, 7 * 15.0 + 20),
              painter: _HeatMapPainter(
                dailyCounts: dailyCounts,
                startDate: startDate,
                today: today,
                maxCount: maxCount > 0 ? maxCount : 1,
                emptyColor: cs.surfaceContainerHighest,
                accentColor: AppColors.accent,
                textColor: cs.secondary,
                brightness: Theme.of(context).brightness,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Less',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.secondary,
                    )),
            const SizedBox(width: 4),
            for (int i = 0; i < 5; i++)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(left: 3),
                decoration: BoxDecoration(
                  color: i == 0
                      ? cs.surfaceContainerHighest
                      : Color.lerp(
                          cs.surfaceContainerHighest,
                          AppColors.accent,
                          i / 4.0,
                        ),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            const SizedBox(width: 4),
            Text('More',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.secondary,
                    )),
          ],
        ),
      ],
    );
  }
}

class _HeatMapPainter extends CustomPainter {
  _HeatMapPainter({
    required this.dailyCounts,
    required this.startDate,
    required this.today,
    required this.maxCount,
    required this.emptyColor,
    required this.accentColor,
    required this.textColor,
    required this.brightness,
  });

  final Map<DateTime, int> dailyCounts;
  final DateTime startDate;
  final DateTime today;
  final int maxCount;
  final Color emptyColor;
  final Color accentColor;
  final Color textColor;
  final Brightness brightness;

  static const double cellSize = 12.0;
  static const double gap = 3.0;
  static const double step = cellSize + gap;
  static const double monthLabelHeight = 20.0;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    int? lastMonth;

    for (int week = 0; week < 52; week++) {
      for (int day = 0; day < 7; day++) {
        final date = startDate.add(Duration(days: week * 7 + day));
        if (date.isAfter(today)) continue;

        final count = dailyCounts[date] ?? 0;
        final x = week * step;
        final y = day * step + monthLabelHeight;

        // Color based on intensity
        if (count == 0) {
          paint.color = emptyColor;
        } else {
          final intensity = (count / maxCount).clamp(0.0, 1.0);
          // Map to 4 levels
          final level = intensity <= 0.25
              ? 0.25
              : intensity <= 0.5
                  ? 0.5
                  : intensity <= 0.75
                      ? 0.75
                      : 1.0;
          paint.color = Color.lerp(emptyColor, accentColor, level)!;
        }

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          const Radius.circular(2.5),
        );
        canvas.drawRRect(rect, paint);

        // Today's cell glow
        if (date == today) {
          final glowPaint = Paint()
            ..color = accentColor.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
          canvas.drawRRect(rect, glowPaint);
        }

        // Month labels
        if (day == 0) {
          final month = date.month;
          if (month != lastMonth) {
            lastMonth = month;
            textPainter.text = TextSpan(
              text: _months[month - 1],
              style: TextStyle(color: textColor, fontSize: 10),
            );
            textPainter.layout();
            textPainter.paint(canvas, Offset(x, 0));
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatMapPainter oldDelegate) =>
      oldDelegate.dailyCounts != dailyCounts || oldDelegate.today != today;
}
