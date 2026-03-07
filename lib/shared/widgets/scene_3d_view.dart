import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Embeds a native SceneKit 3D view (Metal-backed) in Flutter.
///
/// Uses `UiKitView` to host the native `SCNView` platform view.
/// The 3D scene is controlled via `Scene3D` service (MethodChannel),
/// not through widget parameters — this keeps the API flexible.
///
/// **How it works:**
/// Flutter's platform view system creates a native iOS view and composites
/// it into the Flutter widget tree. Touch events pass through to SceneKit,
/// enabling built-in rotate/zoom/pan gestures.
///
/// **Usage:**
/// ```dart
/// Scene3DView(
///   backgroundColor: Colors.black,
///   creationParams: {'showGrid': true},
/// )
/// ```
class Scene3DView extends StatelessWidget {
  const Scene3DView({
    super.key,
    this.creationParams,
    this.backgroundColor,
  });

  /// Optional parameters passed to the native view during creation.
  final Map<String, dynamic>? creationParams;

  /// Background color for the container. The SCNView itself defaults to black.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black,
      child: UiKitView(
        viewType: 'com.breakdex/scene_3d_view',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
