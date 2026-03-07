/// A single detected body joint from Apple Vision's 3D pose estimation.
///
/// Apple Vision provides 17 joints for the human body skeleton.
/// Each joint has a name (matching the VNHumanBodyPose3DObservation joint names)
/// and 3D coordinates in the camera's coordinate space.
///
/// **Coordinate system:**
/// - x: horizontal (negative = left, positive = right)
/// - y: vertical (negative = down, positive = up)
/// - z: depth (negative = towards camera, positive = away)
///
/// Confidence ranges from 0.0 (no confidence) to 1.0 (fully confident).
class PoseJoint {
  final String name;
  final double x;
  final double y;
  final double z;
  final double confidence;

  const PoseJoint({
    required this.name,
    required this.x,
    required this.y,
    required this.z,
    required this.confidence,
  });

  /// Deserialize from the native Vision ML plugin's joint dictionary.
  factory PoseJoint.fromMap(Map<String, dynamic> map) {
    return PoseJoint(
      name: map['name'] as String? ?? '',
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      z: (map['z'] as num?)?.toDouble() ?? 0.0,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Serialize to a map for passing to SceneKit 3D.
  Map<String, dynamic> toMap() => {
        'name': name,
        'x': x,
        'y': y,
        'z': z,
        'confidence': confidence,
      };

  /// Whether this joint was detected with sufficient confidence (> 0.3).
  bool get isConfident => confidence > 0.3;

  /// All 17 joint names from Apple Vision's body pose detection.
  static const allJointNames = [
    'root',
    'left_hip_joint',
    'right_hip_joint',
    'spine_7_joint',
    'left_knee_joint',
    'right_knee_joint',
    'center_shoulder_joint',
    'left_ankle_joint',
    'right_ankle_joint',
    'left_shoulder_1_joint',
    'right_shoulder_1_joint',
    'left_elbow_joint',
    'right_elbow_joint',
    'left_wrist_joint',
    'right_wrist_joint',
    'left_foot_joint',
    'right_foot_joint',
  ];

  @override
  String toString() => 'PoseJoint($name: [$x, $y, $z] conf=$confidence)';
}
