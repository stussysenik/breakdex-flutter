import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/design/icons.dart';

/// Embeds a native SceneKit 3D view (Metal-backed) in Flutter.
///
/// Uses `UiKitView` to host the native `SCNView` platform view.
/// The 3D scene is controlled via `Scene3D` service (MethodChannel),
/// not through widget parameters — this keeps the API flexible.
///
/// **Web:** renders an "Unavailable on web" placeholder — the 3D skeleton
/// depends on a native SceneKit platform view, which has no web equivalent.
///
/// **Usage:**
/// ```dart
/// Scene3DView(
///   backgroundColor: Colors.black,
///   creationParams: {'showGrid': true},
/// )
/// ```
class Scene3DView extends StatelessWidget {
  const Scene3DView({super.key, this.creationParams, this.backgroundColor});

  /// Optional parameters passed to the native view during creation.
  final Map<String, dynamic>? creationParams;

  /// Background color for the container. The SCNView itself defaults to black.
  final Color? backgroundColor;

  @override
  Widget build(final BuildContext context) {
    if (kIsWeb) {
      return _webPlaceholder();
    }

    return Container(
      color: backgroundColor ?? Colors.black,
      child: UiKitView(
        viewType: 'com.breakdex/scene_3d_view',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }

  Widget _webPlaceholder() {
    return Container(
      color: backgroundColor ?? Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIconView(AppIcon.discover, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '3D view unavailable on web',
            style: AppTypography.caption.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
