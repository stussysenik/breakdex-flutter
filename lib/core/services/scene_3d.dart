import '../models/pose_joint.dart';
import 'native_bridge.dart';

/// Dart interface to the native SceneKit 3D rendering plugin.
///
/// Controls a Metal-backed SCNView embedded in Flutter via PlatformView.
/// Used to visualize 3D skeleton poses from VisionML, load 3D models,
/// and provide interactive camera/lighting control.
///
/// **Usage flow:**
/// 1. Embed `Scene3DView` widget in your layout (creates the native SCNView)
/// 2. Optionally load a 3D model: `scene3D.loadModel('skeleton.usdz')`
/// 3. Feed pose data: `scene3D.updateSkeleton(poseFrame.joints)`
/// 4. Control view: `scene3D.setCamera(...)`, `scene3D.setLighting(...)`
class Scene3D extends NativeBridge {
  Scene3D() : super('scene_3d', hasEventChannel: false);

  /// Load a 3D model into the scene.
  ///
  /// [assetPath] can be a bundle asset name (e.g. "skeleton.usdz")
  /// or an absolute file path.
  Future<bool> loadModel(String assetPath) async {
    final normalizedPath = assetPath.trim();
    if (normalizedPath.isEmpty) return false;

    final result = await invoke<bool>('loadModel', {'path': normalizedPath});
    return result ?? false;
  }

  /// Update the 3D skeleton with new joint positions from VisionML.
  ///
  /// Creates/updates sphere nodes for each joint and cylinder bones
  /// connecting them. Animates smoothly between positions.
  Future<void> updateSkeleton(List<PoseJoint> joints) {
    if (joints.isEmpty) return Future<void>.value();

    return invoke('updateSkeleton', {
      'joints': joints.map((j) => j.toMap()).toList(),
    });
  }

  /// Set the camera position and orientation.
  ///
  /// [x], [y], [z] control position. [pitch] and [yaw] control
  /// orientation in degrees. Animates over 0.3s.
  Future<void> setCamera({
    double x = 0,
    double y = 1.0,
    double z = 3.0,
    double? pitch,
    double? yaw,
  }) {
    final args = <String, Object>{'x': x, 'y': y, 'z': z};
    if (pitch != null) args['pitch'] = pitch;
    if (yaw != null) args['yaw'] = yaw;
    return invoke('setCamera', args);
  }

  /// Configure the scene's key light.
  ///
  /// [type] can be "directional", "omni", "spot", or "ambient".
  /// [intensity] ranges from 0 to ~2000 (default 800).
  /// [color] is an ARGB hex integer.
  Future<void> setLighting({
    String type = 'directional',
    double intensity = 800,
    int? color,
  }) {
    final args = <String, Object>{'type': type, 'intensity': intensity};
    if (color != null) args['color'] = color;
    return invoke('setLighting', args);
  }

  /// Play a named animation on the loaded model.
  Future<void> animate(String name) {
    return invoke('animate', {'name': name});
  }

  /// Clear the scene — removes all joints, bones, and loaded models.
  Future<void> reset() => invoke('reset');
}
