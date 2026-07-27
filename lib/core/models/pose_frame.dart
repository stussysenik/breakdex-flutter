import 'package:breakdex/core/models/pose_joint.dart';

/// A single frame of pose data — all detected joints at a point in time.
///
/// Streamed from `VisionML.livePoseStream` during live camera detection,
/// or returned from `VisionML.detectPose()` for single-frame analysis.
///
/// The [overallConfidence] is the average confidence across all detected joints,
/// giving a quick quality signal for whether the frame is usable.
class PoseFrame {
  final List<PoseJoint> joints;
  final double timestamp;
  final double overallConfidence;

  const PoseFrame({
    required this.joints,
    required this.timestamp,
    required this.overallConfidence,
  });

  /// Deserialize from the native Vision ML plugin's event dictionary.
  factory PoseFrame.fromMap(final Map<String, dynamic> map) {
    final jointsList = (map['joints'] as List<dynamic>?)
            ?.map((final j) => PoseJoint.fromMap(Map<String, dynamic>.from(j as Map)))
            .toList() ??
        [];

    return PoseFrame(
      joints: jointsList,
      timestamp: (map['timestamp'] as num?)?.toDouble() ?? 0.0,
      overallConfidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Whether this frame has enough confident joints to be useful for analysis.
  /// Requires at least 8 joints with confidence > 0.3.
  bool get isUsable => joints.where((final j) => j.isConfident).length >= 8;

  /// Look up a joint by name. Returns null if not found.
  PoseJoint? joint(final String name) {
    for (final j in joints) {
      if (j.name == name) return j;
    }
    return null;
  }

  /// Serialize all joints to maps (for passing to Scene3D.updateSkeleton).
  List<Map<String, dynamic>> toJointMaps() =>
      joints.map((final j) => j.toMap()).toList();

  @override
  String toString() =>
      'PoseFrame(${joints.length} joints, t=${timestamp.toStringAsFixed(0)}ms, '
      'conf=${overallConfidence.toStringAsFixed(2)})';
}
