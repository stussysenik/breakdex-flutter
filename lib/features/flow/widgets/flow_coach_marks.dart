// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';

/// First-visit coach marks for the Flow Graph feature.
///
/// Shows a 3-step tooltip sequence introducing gesture controls:
/// tap-to-spotlight, double-tap-to-detail, and pinch-to-zoom.
/// Uses [SharedPreferences] to ensure the sequence only appears once.
///
/// Usage: call [FlowCoachMarks.showIfNeeded] from a post-frame callback
/// after the Flow screen has built and the graph has had time to render.
class FlowCoachMarks {
  static const _prefKey = 'flow_coach_shown';

  /// Shows the 3-step coach mark sequence if the user hasn't seen it yet.
  ///
  /// Waits 800ms for the graph to render before displaying, then walks
  /// through each tooltip with fade-in/fade-out transitions. Persists
  /// a boolean to [SharedPreferences] so the sequence is one-shot.
  static Future<void> showIfNeeded(final BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey) == true) return;

    // Small delay so the graph has time to render its initial layout
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!context.mounted) return;

    await _showSequence(context);
    await prefs.setBool(_prefKey, true);
  }

  /// The three coach mark steps: message text and vertical position
  /// expressed as a fraction of screen height.
  static const _steps = [
    _CoachStep(
      message: 'Tap a node to spotlight its connections',
      verticalFraction: 0.40,
    ),
    _CoachStep(
      message: 'Double-tap a node to open its detail',
      verticalFraction: 0.45,
    ),
    _CoachStep(
      message: 'Pinch to zoom and pan to explore',
      verticalFraction: 0.50,
    ),
  ];

  /// Walks through each step in sequence, waiting for the user to
  /// tap "Next" or "Got it" before advancing.
  static Future<void> _showSequence(final BuildContext context) async {
    for (var i = 0; i < _steps.length; i++) {
      if (!context.mounted) return;
      await _showStep(
        context,
        step: _steps[i],
        stepIndex: i,
        isLast: i == _steps.length - 1,
      );
    }
  }

  /// Displays a single coach mark tooltip as an [OverlayEntry].
  ///
  /// The tooltip fades in over 200ms, waits for a button tap, then
  /// fades out over 150ms before the completer resolves. A 10% black
  /// scrim sits behind the tooltip so it stands out against the graph.
  static Future<void> _showStep(
    final BuildContext context, {
    required final _CoachStep step,
    required final int stepIndex,
    required final bool isLast,
  }) {
    final completer = Completer<void>();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _CoachTooltipOverlay(
        step: step,
        buttonLabel: isLast ? 'Got it' : 'Next',
        onDismiss: () {
          entry.remove();
          completer.complete();
        },
      ),
    );

    Overlay.of(context).insert(entry);
    return completer.future;
  }
}

/// Data class describing a single coach mark step.
class _CoachStep {
  const _CoachStep({
    required this.message,
    required this.verticalFraction,
  });

  /// The instructional text to display.
  final String message;

  /// Vertical position as a fraction of screen height (0.0 = top, 1.0 = bottom).
  final double verticalFraction;
}

/// The overlay widget for a single coach mark step.
///
/// Renders a semi-transparent scrim with a centered tooltip that
/// fades in and out. The tooltip uses [Theme.of(context).colorScheme.primary] as its
/// background and includes a small downward-pointing triangle to
/// suggest it relates to the canvas below.
class _CoachTooltipOverlay extends StatefulWidget {
  const _CoachTooltipOverlay({
    required this.step,
    required this.buttonLabel,
    required this.onDismiss,
  });

  final _CoachStep step;
  final String buttonLabel;
  final VoidCallback onDismiss;

  @override
  State<_CoachTooltipOverlay> createState() => _CoachTooltipOverlayState();
}

class _CoachTooltipOverlayState extends State<_CoachTooltipOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Total duration covers both fade-in and a hold.
      // Fade-out is triggered manually via reverse.
      duration: AppMotion.moderate02,
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.entrance,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Triggers the fade-out animation, then calls [onDismiss] to
  /// remove the overlay entry and resolve the step future.
  Future<void> _handleDismiss() async {
    if (_dismissing) return;
    _dismissing = true;

    // Fade out over 150ms
    _controller.duration = AppMotion.moderate01;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(final BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _fadeIn,
      builder: (final context, final child) {
        return Opacity(
          opacity: _fadeIn.value,
          child: child,
        );
      },
      child: Material(
        color: Colors.black.withValues(alpha: 0.10),
        child: GestureDetector(
          // Tapping the scrim also advances
          onTap: _handleDismiss,
          behavior: HitTestBehavior.translucent,
          child: SizedBox.expand(
            child: Stack(
              children: [
                Positioned(
                  top: screenSize.height * widget.step.verticalFraction,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildTooltip(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the tooltip card with message text, action button,
  /// and a small triangular arrow pointing downward.
  Widget _buildTooltip(final BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tooltip body
        Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.step.message,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Action button
              GestureDetector(
                onTap: _handleDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    widget.buttonLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Downward-pointing triangle arrow
        CustomPaint(
          size: const Size(16, 8),
          painter: _TrianglePainter(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}

/// Paints a small downward-pointing triangle, used as the tooltip arrow.
///
/// The triangle's color matches the tooltip background so they appear
/// as one connected shape, visually anchoring the tip toward the canvas.
class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(final _TrianglePainter old) => old.color != color;
}

/// Wrapper widget that triggers [FlowCoachMarks.showIfNeeded] once
/// after the first frame, giving the graph canvas time to render.
///
/// Usage in [FlowScreen]:
/// ```dart
/// body: CoachMarkTrigger(
///   child: SafeArea(...),
/// ),
/// ```
class CoachMarkTrigger extends StatefulWidget {
  const CoachMarkTrigger({super.key, required this.child});

  final Widget child;

  @override
  State<CoachMarkTrigger> createState() => _CoachMarkTriggerState();
}

class _CoachMarkTriggerState extends State<CoachMarkTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FlowCoachMarks.showIfNeeded(context);
      }
    });
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}
