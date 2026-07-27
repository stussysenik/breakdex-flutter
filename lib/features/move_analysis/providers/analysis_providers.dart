import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/models/pose_frame.dart';

/// Analysis mode: analyzing a recorded video vs live camera feed.
enum AnalysisMode { video, camera }

/// Current pose data from the latest analyzed frame.
/// Updated each time VisionML processes a video frame or camera frame.
final currentPoseProvider = StateProvider<PoseFrame?>((_) => null);

/// Whether live camera pose detection is currently streaming.
final livePoseActiveProvider = StateProvider<bool>((_) => false);

/// Analysis mode toggle: video playback vs live camera.
final analysisModeProvider =
    StateProvider<AnalysisMode>((_) => AnalysisMode.video);

/// Whether the "Remove Background" segmentation is active.
final segmentationActiveProvider = StateProvider<bool>((_) => false);
