// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

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
    this.overlay = false,
    this.stepNames,
    this.beatCounts,
  });

  final int stepCount;
  final int activeIndex;
  final ValueChanged<int> onStepSelected;
  final VoidCallback? onAddStep;

  /// Overlay mode: white/semi-transparent colors for dark video backgrounds.
  final bool overlay;

  /// Optional step names shown below each circle (e.g. move names).
  final List<String>? stepNames;

  /// Optional beat counts shown below each circle (e.g. "4 beats").
  final List<int>? beatCounts;

  @override
  State<ComboStepLine> createState() => _ComboStepLineState();
}

class _ComboStepLineState extends State<ComboStepLine> {
  int? _pressedIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToActiveStep();
  }

  @override
  void didUpdateWidget(final ComboStepLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      _scrollToActiveStep();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String? _buildLabel(final int index) {
    final name = widget.stepNames != null &&
            index < widget.stepNames!.length
        ? widget.stepNames![index]
        : null;
    final beats = widget.beatCounts != null &&
            index < widget.beatCounts!.length
        ? widget.beatCounts![index]
        : null;

    if (name == null && beats == null) return null;
    if (name != null && beats != null) return '$name · $beats';
    return name ?? '$beats';
  }

  /// Smoothly scrolls to center the active step node in the viewport.
  ///
  /// Uses a post-frame callback so the scroll position is calculated after
  /// layout — each node is ~84 px wide (24 leading + 36 circle + 24 trailing),
  /// though the first node lacks a leading line and the last lacks a trailing.
  void _scrollToActiveStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      const nodeWidth = 84.0;
      final targetOffset = (widget.activeIndex * nodeWidth) -
          (_scrollController.position.viewportDimension / 2) +
          (nodeWidth / 2);
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: AppMotion.moderate02,
        curve: AppMotion.entrance,
      );
    });
  }

  @override
  Widget build(final BuildContext context) {
    if (widget.stepCount <= 0 && widget.onAddStep == null) {
      return const SizedBox.shrink();
    }

    final safeActiveIndex = widget.stepCount == 0
        ? 0
        : widget.activeIndex.clamp(0, widget.stepCount - 1);

    return SingleChildScrollView(
      controller: _scrollController,
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
                  // Delight budget: press-pop overshoot on tap feedback.
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
                    overlay: widget.overlay,
                    label: _buildLabel(index),
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
                  // Delight budget: press-pop overshoot on tap feedback.
                  curve: AppMotion.expressive,
                  child: TimelineNode(
                    index: 0,
                    style: TimelineNodeStyle.add,
                    showLeadingLine: widget.stepCount > 0,
                    showTrailingLine: false,
                    overlay: widget.overlay,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
