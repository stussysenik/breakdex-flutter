import 'package:flutter/material.dart';
import 'package:breakdex/core/design/typography.dart';

enum TimelineNodeStyle { active, inactive, add }

class TimelineNode extends StatelessWidget {
  const TimelineNode({
    super.key,
    required this.index,
    this.style = TimelineNodeStyle.inactive,
    this.onTap,
    this.showLeadingLine = false,
    this.showTrailingLine = true,
    this.overlay = false,
    this.label,
  });

  final int index;
  final TimelineNodeStyle style;
  final VoidCallback? onTap;
  final bool showLeadingLine;
  final bool showTrailingLine;

  /// Overlay mode: white/semi-transparent colors for dark video backgrounds.
  final bool overlay;

  /// Optional label shown below the circle (e.g. step name).
  final String? label;

  @override
  Widget build(final BuildContext context) {
    final isAdd = style == TimelineNodeStyle.add;
    final isActive = style == TimelineNodeStyle.active;

    // Overlay uses white-based colors; normal uses theme colors.
    final Color activeColor;
    final Color inactiveColor;
    final Color lineColor;
    if (overlay) {
      activeColor = Colors.white;
      inactiveColor = Colors.white.withValues(alpha: 0.3);
      lineColor = Colors.white.withValues(alpha: 0.15);
    } else {
      activeColor = Theme.of(context).colorScheme.primary;
      inactiveColor = isAdd
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).colorScheme.outline;
      lineColor = Theme.of(context).colorScheme.outline;
    }

    final nodeColor = isActive ? activeColor : inactiveColor;

    // Active nodes use a filled circle with contrasting text;
    // inactive nodes stay hollow with a border-only style.
    final Color textColor;
    if (isActive) {
      // Filled circle — text must contrast with the fill color.
      textColor = overlay ? Colors.black87 : Colors.white;
    } else {
      textColor = overlay
          ? Colors.white.withValues(alpha: 0.3)
          : Theme.of(context).colorScheme.secondary;
    }

    final node = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLeadingLine)
          Container(width: 24, height: 2, color: lineColor),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Active: solid fill; Inactive/Add: transparent with border.
            color: isActive ? activeColor : (isAdd ? Colors.transparent : null),
            border: isActive
                ? null
                : Border.all(color: nodeColor, width: 2),
          ),
          child: Center(
            child: isAdd
                ? Icon(Icons.add, size: 18, color: inactiveColor)
                : Text(
                    '$index',
                    style: AppTypography.caption.copyWith(
                      color: textColor,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
          ),
        ),
        if (showTrailingLine)
          Container(width: 24, height: 2, color: lineColor),
      ],
    );

    if (label != null) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            node,
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Text(
                label!,
                style: AppTypography.caption.copyWith(
                  color: textColor,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(onTap: onTap, child: node);
  }
}
