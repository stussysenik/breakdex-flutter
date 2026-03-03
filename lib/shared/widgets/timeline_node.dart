import 'package:flutter/material.dart';
import '../../core/design/colors.dart';
import '../../core/design/typography.dart';

enum TimelineNodeStyle { active, inactive, add }

class TimelineNode extends StatelessWidget {
  const TimelineNode({
    super.key,
    required this.index,
    this.style = TimelineNodeStyle.inactive,
    this.onTap,
    this.showLeadingLine = false,
    this.showTrailingLine = true,
  });

  final int index;
  final TimelineNodeStyle style;
  final VoidCallback? onTap;
  final bool showLeadingLine;
  final bool showTrailingLine;

  @override
  Widget build(BuildContext context) {
    final isAdd = style == TimelineNodeStyle.add;
    final isActive = style == TimelineNodeStyle.active;
    final secondary = Theme.of(context).colorScheme.secondary;
    final separator = Theme.of(context).colorScheme.outline;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLeadingLine)
            Container(
              width: 24,
              height: 2,
              color: separator,
            ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAdd ? Colors.transparent : null,
              border: Border.all(
                color: isActive
                    ? AppColors.accent
                    : isAdd
                        ? secondary
                        : separator,
                width: isActive ? 3 : 2,
              ),
            ),
            child: Center(
              child: isAdd
                  ? Icon(Icons.add, size: 18, color: secondary)
                  : Text(
                      '$index',
                      style: AppTypography.caption.copyWith(
                        color: isActive ? AppColors.accent : secondary,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
            ),
          ),
          if (showTrailingLine)
            Container(
              width: 24,
              height: 2,
              color: separator,
            ),
        ],
      ),
    );
  }
}
