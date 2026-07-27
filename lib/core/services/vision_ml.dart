import 'dart:typed_data';

import 'package:breakdex/core/models/pose_frame.dart';
import 'package:breakdex/core/models/pose_joint.dart';
import 'package:breakdex/core/services/native_bridge.dart';

/// Dart interface to the native Apple Vision + CoreML plugin.
///
/// Provides three ML capabilities:
///
/// 1. **Single-frame pose detection** — feed an image, get 17 3D joints back.
///    Uses Apple Vision's built-in VNDetectHumanBodyPose3DRequest (no model needed).
///
/// 2. **Live camera pose streaming** — starts camera, streams PoseFrame events
///    at ~30fps through the EventChannel. Perfect for real-time move analysis.
///
/// 3. **Person segmentation** — uses DeepLabV3 CoreML model (8.6MB) to produce
///    an alpha mask separating person from background.
///
/// All inference runs on-device (Neural Engine → GPU → CPU fallback).
class VisionML extends NativeBridge {
  VisionML() : super('vision_ml');

  /// Detect 3D body pose from a single image.
  ///
  /// Returns a list of up to 17 [PoseJoint]s with 3D coordinates and confidence.
  /// Uses Apple Vision's built-in pose detection — no model download needed.
  Future<List<PoseJoint>> detectPose(final Uint8List imageData) async {
    if (imageData.isEmpty) {
      return const <PoseJoint>[];
    }

    final result = await method.invokeMethod<List<dynamic>>('detectPose', {
      'imageData': imageData,
    });

    if (result == null) return [];

    return result
        .map((final j) => PoseJoint.fromMap(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  /// Stream of live pose frames from the device camera.
  ///
  /// Each frame contains all detected joints and a timestamp.
  /// Call [startLivePose] first, then listen to this stream.
  /// Call [stopLivePose] to stop streaming.
  Stream<PoseFrame> get livePoseStream => eventStream.map(PoseFrame.fromMap);

  /// Start live camera pose detection.
  /// Pose data will be emitted on [livePoseStream] at ~30fps.
  Future<void> startLivePose() => invoke('startLivePose');

  /// Stop live camera pose detection and release camera resources.
  Future<void> stopLivePose() => invoke('stopLivePose');

  /// Segment a person from the background.
  ///
  /// Returns PNG mask bytes where white pixels = person, black = background.
  /// Uses DeepLabV3 CoreML model (must be bundled in the app).
  Future<Uint8List?> segmentPerson(final Uint8List imageData) async {
    if (imageData.isEmpty) {
      return null;
    }

    final result = await method.invokeMethod<Uint8List>('segmentPerson', {
      'imageData': imageData,
    });
    return result;
  }
}
