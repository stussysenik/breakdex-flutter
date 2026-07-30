import 'package:flutter/material.dart';
import 'package:breakdex/core/design/theme.dart';

import 'package:breakdex/core/models/pose_frame.dart';
import 'package:breakdex/core/models/pose_joint.dart';

/// 2D overlay that draws detected pose joints on top of the video frame.
///
/// Renders colored dots for each joint and lines connecting them (bones).
/// Joint colors match the 3D view: blue for arms, green for legs, red for torso.
///
/// This is drawn as a CustomPaint overlay on the video player area, using
/// normalized coordinates (0.0 - 1.0) mapped to the widget's size.
class PoseOverlay extends StatelessWidget {
  const PoseOverlay({super.key, required this.poseFrame});

  final PoseFrame? poseFrame;

  @override
  Widget build(final BuildContext context) {
    if (poseFrame == null || !poseFrame!.isUsable) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _PoseOverlayPainter(
        poseFrame!,
        palette: _JointPalette.of(context),
      ),
      size: Size.infinite,
    );
  }
}

/// The four limb-group colors a pose frame paints with, resolved once in
/// `build`. A `CustomPainter` has no `BuildContext`, so the theme read cannot
/// happen inside `paint` — it is lifted here and passed down.
class _JointPalette {
  const _JointPalette({
    required this.arms,
    required this.legs,
    required this.torso,
    required this.other,
  });

  factory _JointPalette.of(final BuildContext context) {
    final semantic = AppSemanticTheme.of(context);
    return _JointPalette(
      arms: Theme.of(context).colorScheme.primary,
      legs: semantic.actionGood,
      torso: semantic.actionAgain,
      other: semantic.actionEasy,
    );
  }

  final Color arms;
  final Color legs;
  final Color torso;
  final Color other;
}

class _PoseOverlayPainter extends CustomPainter {
  _PoseOverlayPainter(this.frame, {required this.palette});

  final PoseFrame frame;
  final _JointPalette palette;

  /// Bone connections — pairs of joint names to draw lines between.
  static const _bones = [
    ('root', 'left_hip_joint'),
    ('root', 'right_hip_joint'),
    ('root', 'spine_7_joint'),
    ('spine_7_joint', 'center_shoulder_joint'),
    ('center_shoulder_joint', 'left_shoulder_1_joint'),
    ('center_shoulder_joint', 'right_shoulder_1_joint'),
    ('left_shoulder_1_joint', 'left_elbow_joint'),
    ('right_shoulder_1_joint', 'right_elbow_joint'),
    ('left_elbow_joint', 'left_wrist_joint'),
    ('right_elbow_joint', 'right_wrist_joint'),
    ('left_hip_joint', 'left_knee_joint'),
    ('right_hip_joint', 'right_knee_joint'),
    ('left_knee_joint', 'left_ankle_joint'),
    ('right_knee_joint', 'right_ankle_joint'),
    ('left_ankle_joint', 'left_foot_joint'),
    ('right_ankle_joint', 'right_foot_joint'),
  ];

  @override
  void paint(final Canvas canvas, final Size size) {
    final jointMap = <String, PoseJoint>{};
    for (final j in frame.joints) {
      jointMap[j.name] = j;
    }

    // Draw bones — stroke width varies with the lower confidence of the pair.
    // High confidence (>0.7) → 3.0px, low confidence (<0.3) → 1.5px.
    for (final (from, to) in _bones) {
      final a = jointMap[from];
      final b = jointMap[to];
      if (a == null || b == null) continue;
      if (!a.isConfident || !b.isConfident) continue;

      final minConf = a.confidence < b.confidence ? a.confidence : b.confidence;
      final strokeWidth = 1.5 + 1.5 * minConf.clamp(0.0, 1.0);
      final boneAlpha = 0.3 + 0.4 * minConf.clamp(0.0, 1.0);

      final bonePaint = Paint()
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: boneAlpha);

      canvas.drawLine(
        _toOffset(a, size),
        _toOffset(b, size),
        bonePaint,
      );
    }

    // Draw joints — glow radius scales with confidence.
    // Confident joints get a prominent glow, uncertain ones just get the dot.
    for (final joint in frame.joints) {
      if (!joint.isConfident) continue;
      final offset = _toOffset(joint, size);
      final color = _jointColor(joint.name);
      final conf = joint.confidence.clamp(0.0, 1.0);

      // Outer glow — radius 3 (low) to 7 (high), alpha scales too
      final glowRadius = 3.0 + 4.0 * conf;
      final glowAlpha = 0.1 + 0.25 * conf;
      canvas.drawCircle(
        offset,
        glowRadius,
        Paint()..color = color.withValues(alpha: glowAlpha),
      );

      // Inner dot — radius 2.5 (low) to 4.5 (high)
      final dotRadius = 2.5 + 2.0 * conf;
      canvas.drawCircle(
        offset,
        dotRadius,
        Paint()..color = color.withValues(alpha: 0.5 + 0.5 * conf),
      );
    }
  }

  /// Map a joint's x/y to widget coordinates.
  /// Vision returns normalized coords — x in [-1, 1], y in [-1, 1].
  /// We map to [0, width] and [0, height], flipping y since screen Y is inverted.
  Offset _toOffset(final PoseJoint joint, final Size size) {
    final x = (joint.x + 1) / 2 * size.width;
    final y = (1 - (joint.y + 1) / 2) * size.height;
    return Offset(x.clamp(0, size.width), y.clamp(0, size.height));
  }

  Color _jointColor(final String name) {
    if (name.contains('shoulder') ||
        name.contains('elbow') ||
        name.contains('wrist')) {
      return palette.arms;
    } else if (name.contains('hip') ||
        name.contains('knee') ||
        name.contains('ankle') ||
        name.contains('foot')) {
      return palette.legs;
    } else if (name.contains('spine') ||
        name == 'root' ||
        name.contains('center')) {
      return palette.torso;
    }
    return palette.other;
  }

  @override
  bool shouldRepaint(final _PoseOverlayPainter oldDelegate) =>
      oldDelegate.frame != frame;
}
