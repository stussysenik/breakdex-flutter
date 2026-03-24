import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';

/// Frosted glass legend overlay for the Flow Graph.
///
/// Displays a compact 3-column guide explaining the visual encoding used
/// in the force-directed graph:
/// - **Nodes**: circle size/opacity encodes mastery (mastered → learning → new)
/// - **Edges**: line style encodes affinity (solid → dashed → dotted)
/// - **Gestures**: tap/double-tap/pinch interaction model
///
/// The panel uses a frosted glass aesthetic (backdrop blur + translucent
/// surface) to float above the graph without fully obscuring it — the user
/// can still see nodes through the legend while learning the visual language.
class FlowGraphLegend extends StatelessWidget {
  const FlowGraphLegend({super.key, this.onDismiss});

  /// Called when the user taps "dismiss" — parent hides the legend.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.06),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -- Header: "Legend" title + dismiss button --
              _buildHeader(colorScheme),
              const SizedBox(height: AppSpacing.xs),
              // -- Three-column content --
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildNodesColumn(colorScheme)),
                  Expanded(child: _buildEdgesColumn(colorScheme)),
                  Expanded(child: _buildGesturesColumn(colorScheme)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header row: bold "Legend" title on the left, dismiss text button right.
  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Legend',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        GestureDetector(
          onTap: onDismiss,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            child: Text(
              'dismiss',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Column 1 — Nodes
  // ---------------------------------------------------------------------------

  Widget _buildNodesColumn(ColorScheme colorScheme) {
    final labelColor = colorScheme.onSurface.withValues(alpha: 0.75);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nodes',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Mastered: large circle with halo ring.
        _nodeRow(
          circleRadius: 5,
          color: AppColors.stateMastery,
          halo: true,
          label: 'Mastered',
          labelColor: labelColor,
        ),
        const SizedBox(height: 3),
        // Learning: mid-size solid circle.
        _nodeRow(
          circleRadius: 3.5,
          color: AppColors.stateLearning,
          halo: false,
          label: 'Learning',
          labelColor: labelColor,
        ),
        const SizedBox(height: 3),
        // New: tiny, faded circle.
        _nodeRow(
          circleRadius: 2,
          color: AppColors.stateNew.withValues(alpha: 0.40),
          halo: false,
          label: 'New',
          labelColor: labelColor,
        ),
      ],
    );
  }

  /// A single node-legend row: colored circle (with optional halo) + label.
  Widget _nodeRow({
    required double circleRadius,
    required Color color,
    required bool halo,
    required String label,
    required Color labelColor,
  }) {
    // Total widget height stays consistent via SizedBox.
    final diameter = halo ? (circleRadius + 2) * 2 : circleRadius * 2;
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: Center(
            child: CustomPaint(
              size: Size(diameter, diameter),
              painter: _NodeCirclePainter(
                radius: circleRadius,
                color: color,
                halo: halo,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Column 2 — Edges
  // ---------------------------------------------------------------------------

  Widget _buildEdgesColumn(ColorScheme colorScheme) {
    final labelColor = colorScheme.onSurface.withValues(alpha: 0.75);
    final lineColor = colorScheme.onSurface.withValues(alpha: 0.50);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edges',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Natural: solid line.
        _edgeRow(
          style: _EdgeLineStyle.solid,
          label: 'Natural',
          lineColor: lineColor,
          labelColor: labelColor,
        ),
        const SizedBox(height: 3),
        // Possible: dashed line.
        _edgeRow(
          style: _EdgeLineStyle.dashed,
          label: 'Possible',
          lineColor: lineColor,
          labelColor: labelColor,
        ),
        const SizedBox(height: 3),
        // Stretch: dotted line.
        _edgeRow(
          style: _EdgeLineStyle.dotted,
          label: 'Stretch',
          lineColor: lineColor,
          labelColor: labelColor,
        ),
      ],
    );
  }

  /// A single edge-legend row: styled line + label.
  Widget _edgeRow({
    required _EdgeLineStyle style,
    required String label,
    required Color lineColor,
    required Color labelColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 14,
          child: Center(
            child: CustomPaint(
              size: const Size(16, 2),
              painter: _EdgeLinePainter(style: style, color: lineColor),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Column 3 — Gestures
  // ---------------------------------------------------------------------------

  Widget _buildGesturesColumn(ColorScheme colorScheme) {
    final labelColor = colorScheme.onSurface.withValues(alpha: 0.75);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestures',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _gestureRow('Tap = spotlight', labelColor),
        const SizedBox(height: 3),
        _gestureRow('2× tap = open', labelColor),
        const SizedBox(height: 3),
        _gestureRow('Pinch = zoom', labelColor),
      ],
    );
  }

  Widget _gestureRow(String text, Color color) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        fontSize: 10,
        color: color,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters for legend icons
// ---------------------------------------------------------------------------

/// Paints a small circle with an optional halo ring for the node legend.
class _NodeCirclePainter extends CustomPainter {
  const _NodeCirclePainter({
    required this.radius,
    required this.color,
    required this.halo,
  });

  final double radius;
  final Color color;
  final bool halo;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (halo) {
      final haloPaint = Paint()
        ..color = color.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius + 1.5, haloPaint);
    }

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _NodeCirclePainter oldDelegate) =>
      radius != oldDelegate.radius ||
      color != oldDelegate.color ||
      halo != oldDelegate.halo;
}

/// Edge line styles matching the graph's visual encoding.
enum _EdgeLineStyle { solid, dashed, dotted }

/// Paints a short horizontal line in solid, dashed, or dotted style.
class _EdgeLinePainter extends CustomPainter {
  const _EdgeLinePainter({required this.style, required this.color});

  final _EdgeLineStyle style;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;

    switch (style) {
      case _EdgeLineStyle.solid:
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      case _EdgeLineStyle.dashed:
        // 4px dash, 2px gap (scaled for 16px width).
        double x = 0;
        while (x < size.width) {
          final end = (x + 4).clamp(0.0, size.width);
          canvas.drawLine(Offset(x, y), Offset(end, y), paint);
          x += 6;
        }
      case _EdgeLineStyle.dotted:
        // 2px dot, 2px gap.
        double x = 0;
        while (x < size.width) {
          final end = (x + 2).clamp(0.0, size.width);
          canvas.drawLine(Offset(x, y), Offset(end, y), paint);
          x += 4;
        }
    }
  }

  @override
  bool shouldRepaint(covariant _EdgeLinePainter oldDelegate) =>
      style != oldDelegate.style || color != oldDelegate.color;
}
