import Flutter
import SceneKit

/// Factory that creates SceneKit3DView instances for Flutter's UiKitView.
///
/// When Dart uses `UiKitView(viewType: 'com.breakdex/scene_3d_view')`,
/// Flutter calls this factory to produce the native platform view.
///
/// **How Flutter PlatformViews work:**
/// Flutter embeds native iOS views using the "Virtual Display" or "Hybrid Composition"
/// approach. The factory receives creation params from Dart and returns a
/// FlutterPlatformView whose `view()` method provides the actual UIView (SCNView).
class SceneKit3DFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    /// Create a new SceneKit3DView instance.
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let creationParams = args as? [String: Any]
        return SceneKit3DView(
            frame: frame,
            viewId: viewId,
            creationParams: creationParams,
            messenger: messenger
        )
    }

    /// Codec for creation parameters passed from Dart.
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
