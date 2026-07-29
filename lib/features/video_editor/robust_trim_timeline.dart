// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/features/video_editor/trim_timeline_math.dart';
import 'package:breakdex/core/design/icons.dart';

class RobustTrimTimeline extends StatefulWidget {
  const RobustTrimTimeline({
    super.key,
    required this.trimStart,
    required this.trimEnd,
    required this.playbackPosition,
    required this.isPlaying,
    required this.thumbnails,
    required this.videoDurationMs,
    required this.onTrimChanged,
    required this.onPlayheadChanged,
    this.onDragStart,
    this.onDragEnd,
  });

  final double trimStart;
  final double trimEnd;
  final ValueNotifier<double> playbackPosition;
  final ValueNotifier<bool> isPlaying;
  final List<Uint8List?> thumbnails;
  final int videoDurationMs;
  final void Function(double start, double end) onTrimChanged;
  final void Function(double position) onPlayheadChanged;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  @override
  State<RobustTrimTimeline> createState() => _RobustTrimTimelineState();
}

class _RobustTrimTimelineState extends State<RobustTrimTimeline> {
  String? _activeHandle;
  double? _dragValue;
  double? _dragRawValue;
  Offset? _dragOrigin;
  double _dragVerticalLiftPx = 0.0;

  static const double _kGrabRadiusPx = 30.0;
  static const double _kHandleVisualWidth = 20.0;
  static const double _kFineScrubIndicatorLiftPx = 32.0;

  void _handleDragStart(final DragStartDetails details) {
    final box = context.findRenderObject()! as RenderBox;
    final width = box.size.width;
    final localX = box.globalToLocal(details.globalPosition).dx;

    final startPx = widget.trimStart * width;
    final endPx = widget.trimEnd * width;
    final playheadPx = widget.playbackPosition.value * width;

    final dStart = (localX - startPx).abs();
    final dEnd = (localX - endPx).abs();
    final dPlayhead = (localX - playheadPx).abs();

    String? target;
    double best = _kGrabRadiusPx;

    if (dStart < best) {
      best = dStart;
      target = 'start';
    }
    if (dEnd < best) {
      best = dEnd;
      target = 'end';
    }
    if (dPlayhead < best) {
      target = 'playhead';
    }

    if (target == null) return;

    widget.onDragStart?.call();
    setState(() {
      _activeHandle = target;
      _dragValue = target == 'start'
          ? widget.trimStart
          : (target == 'end' ? widget.trimEnd : widget.playbackPosition.value);
      _dragRawValue = _dragValue;
      _dragOrigin = details.globalPosition;
      _dragVerticalLiftPx = 0.0;
    });
    HapticFeedback.selectionClick();
  }

  void _handleDragUpdate(final DragUpdateDetails details) {
    if (_activeHandle == null) return;
    final box = context.findRenderObject()! as RenderBox;
    final width = box.size.width;

    if (_activeHandle == 'start' || _activeHandle == 'end') {
      final origin = _dragOrigin;
      if (origin == null) return;
      final lift = (origin.dy - details.globalPosition.dy)
          .clamp(0.0, 100.0)
          .toDouble();
      setState(() => _dragVerticalLiftPx = lift);

      final isStart = _activeHandle == 'start';
      final minVal = isStart ? 0.0 : widget.trimStart + 0.05;
      final maxVal = isStart ? widget.trimEnd - 0.05 : 1.0;

      _dragRawValue = applyRawDrag(
        currentRaw: _dragRawValue!,
        deltaDx: details.delta.dx,
        timelineWidth: width,
        verticalLiftPx: _dragVerticalLiftPx,
        minValue: minVal,
        maxValue: maxVal,
      );

      final snapped = snapNormalizedToDuration(
        _dragRawValue!,
        widget.videoDurationMs,
        quantumMs: 1,
      ).clamp(minVal, maxVal).toDouble();

      if (snapped != _dragValue) {
        HapticFeedback.selectionClick();
        _dragValue = snapped;
        if (isStart) {
          widget.onTrimChanged(snapped, widget.trimEnd);
        } else {
          widget.onTrimChanged(widget.trimStart, snapped);
        }
        widget.onPlayheadChanged(snapped);
      }
    } else if (_activeHandle == 'playhead') {
      final delta = details.delta.dx / width;
      final newPos = (widget.playbackPosition.value + delta)
          .clamp(widget.trimStart, widget.trimEnd)
          .toDouble();
      if (newPos != widget.playbackPosition.value) {
        widget.onPlayheadChanged(newPos);
      }
    }
  }

  void _handleDragEnd(final DragEndDetails details) {
    setState(() {
      _activeHandle = null;
      _dragValue = null;
      _dragRawValue = null;
      _dragOrigin = null;
      _dragVerticalLiftPx = 0.0;
    });
    widget.onDragEnd?.call();
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timelineWidth =
        MediaQuery.of(context).size.width - AppSpacing.screenEdge * 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timecodes
        SizedBox(
          height: 20,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatDuration(widget.trimStart * widget.videoDurationMs),
                  style: AppTypography.caption.copyWith(
                    color: _activeHandle == 'start'
                        ? colorScheme.primary
                        : Colors.white54,
                    fontWeight: _activeHandle == 'start'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              Center(
                child: ValueListenableBuilder<double>(
                  valueListenable: widget.playbackPosition,
                  builder: (final context, final pos, _) => Text(
                    _formatDuration(pos * widget.videoDurationMs),
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatDuration(widget.trimEnd * widget.videoDurationMs),
                  style: AppTypography.caption.copyWith(
                    color: _activeHandle == 'end'
                        ? colorScheme.primary
                        : Colors.white54,
                    fontWeight: _activeHandle == 'end'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Timeline Strip
        GestureDetector(
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Thumbnails
                Row(
                  children: List.generate(8, (final i) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: AppColors.darkFill,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            (i < widget.thumbnails.length &&
                                widget.thumbnails[i] != null)
                            ? Opacity(
                                opacity: 0.6,
                                child: Image.memory(
                                  widget.thumbnails[i]!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                ),

                // Dim overlays
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: widget.trimStart * timelineWidth,
                  child: Container(color: Colors.black54),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: (1 - widget.trimEnd) * timelineWidth,
                  child: Container(color: Colors.black54),
                ),

                // Trim region border
                Positioned(
                  left: widget.trimStart * timelineWidth,
                  top: 0,
                  bottom: 0,
                  width: (widget.trimEnd - widget.trimStart) * timelineWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        vertical: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Handles (Visual only)
                _buildHandle(
                  widget.trimStart * timelineWidth,
                  true,
                  colorScheme,
                ),
                _buildHandle(
                  widget.trimEnd * timelineWidth - _kHandleVisualWidth,
                  false,
                  colorScheme,
                ),

                // Playhead - High precision layered design
                ValueListenableBuilder<double>(
                  valueListenable: widget.playbackPosition,
                  builder: (final context, final pos, _) {
                    final isActive = _activeHandle == 'playhead';
                    return Positioned(
                      left: pos * timelineWidth - 4,
                      top: -8,
                      bottom: -8,
                      width: 8,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Broad outer glow
                            Container(
                              width: 6,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: isActive ? 0.3 : 0.15,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xxs,
                                ),
                              ),
                            ),
                            // 2. Medium precision guide
                            Container(
                              width: 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // 3. Ultra-thin core 1px needle
                            Container(width: 1, color: Colors.white),
                            // 4. Mathematical alignment markers (Top/Bottom handle)
                            Positioned(
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: 8,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Fine scrubbing indicator
                if (_activeHandle != null &&
                    _dragVerticalLiftPx > _kFineScrubIndicatorLiftPx)
                  Positioned(
                    top: -30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'FINE SCRUBBING',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHandle(
    final double left,
    final bool isStart,
    final ColorScheme colorScheme,
  ) {
    final isActive =
        (isStart && _activeHandle == 'start') ||
        (!isStart && _activeHandle == 'end');

    return Positioned(
      left: left,
      top: -2,
      bottom: -2,
      width: _kHandleVisualWidth,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: AppMotion.moderate01,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : colorScheme.primary,
            borderRadius: isStart
                ? const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.xs),
                  )
                : const BorderRadius.horizontal(
                    right: Radius.circular(AppRadius.xs),
                  ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: AppIconView(
              AppIcon.menu,
              size: isActive ? 16 : 12,
              color: isActive ? colorScheme.primary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(final double ms) {
    final d = Duration(milliseconds: ms.round());
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$seconds.$millis';
  }
}
