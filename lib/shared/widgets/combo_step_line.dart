import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/spacing.dart';
import 'timeline_node.dart';

class ComboStepLine extends StatefulWidget {
  const ComboStepLine({
    super.key,
    required this.stepCount,
    required this.activeIndex,
    required this.onStepSelected,
    this.onAddStep,
  });

  final int stepCount;
  final int activeIndex;
  final ValueChanged<int> onStepSelected;
  final VoidCallback? onAddStep;

  @override
  State<ComboStepLine> createState() => _ComboStepLineState();
}

class _ComboStepLineState extends State<ComboStepLine> {
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.stepCount <= 0 && widget.onAddStep == null) {
      return const SizedBox.shrink();
    }

    final safeActiveIndex = widget.stepCount == 0
        ? 0
        : widget.activeIndex.clamp(0, widget.stepCount - 1);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int index = 0; index < widget.stepCount; index++)
            Semantics(
              identifier: 'combo-step-${index + 1}',
              label: 'Step ${index + 1}',
              button: true,
              selected: index == safeActiveIndex,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _pressedIndex = index),
                onTapCancel: () => setState(() => _pressedIndex = null),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pressedIndex = null);
                  widget.onStepSelected(index);
                },
                child: AnimatedScale(
                  scale: _pressedIndex == index ? 0.88 : 1,
                  duration: AppMotion.fast02,
                  curve: AppMotion.expressive,
                  child: TimelineNode(
                    index: index + 1,
                    style: index == safeActiveIndex
                        ? TimelineNodeStyle.active
                        : TimelineNodeStyle.inactive,
                    showLeadingLine: index > 0,
                    showTrailingLine:
                        index < widget.stepCount - 1 ||
                        widget.onAddStep != null,
                  ),
                ),
              ),
            ),
          if (widget.onAddStep != null)
            Semantics(
              identifier: 'combo-add-step',
              label: 'Add move',
              button: true,
              child: GestureDetector(
                onTapDown: (_) =>
                    setState(() => _pressedIndex = widget.stepCount),
                onTapCancel: () => setState(() => _pressedIndex = null),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pressedIndex = null);
                  widget.onAddStep?.call();
                },
                child: AnimatedScale(
                  scale: _pressedIndex == widget.stepCount ? 0.88 : 1,
                  duration: AppMotion.fast02,
                  curve: AppMotion.expressive,
                  child: TimelineNode(
                    index: 0,
                    style: TimelineNodeStyle.add,
                    showLeadingLine: widget.stepCount > 0,
                    showTrailingLine: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
