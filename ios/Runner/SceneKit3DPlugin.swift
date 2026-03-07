import Flutter
import Metal
import SceneKit

/// MethodChannel handler for the SceneKit 3D platform view.
///
/// Registers both:
/// 1. A `FlutterPlatformViewFactory` for embedding SCNView in Flutter
/// 2. A `MethodChannel` for controlling the 3D scene (load models, update skeleton, etc.)
///
/// **Architecture:**
/// Flutter renders the 3D view via `UiKitView` → `SceneKit3DFactory` creates
/// the native `SCNView`. Commands flow from Dart through the MethodChannel
/// to manipulate the scene graph.
class SceneKit3DPlugin: NSObject, FlutterPlugin, NativeCapability {
    static var channelName: String { "scene_3d" }
    static var eventChannelName: String? { nil }

    /// Weak reference to the active 3D view — commands target this.
    private static weak var activeView: SceneKit3DView?

    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SceneKit3DPlugin()

        // Guard: Metal is required for SceneKit rendering. On simulator
        // or devices without GPU support, skip the platform view factory
        // to avoid a crash — the MethodChannel still works for graceful
        // error responses from handle(_:result:).
        if MTLCreateSystemDefaultDevice() != nil {
            let factory = SceneKit3DFactory(messenger: registrar.messenger())
            registrar.register(factory, withId: "com.breakdex/scene_3d_view")
        } else {
            print("[SceneKit3D] ⚠ Metal not available — skipping platform view factory")
        }

        // Register the method channel for controlling the 3D scene
        let methodChannel = FlutterMethodChannel(
            name: "com.breakdex/\(channelName)",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }

    /// Called by SceneKit3DView when it's created to register itself.
    static func setActiveView(_ view: SceneKit3DView?) {
        activeView = view
    }

    // MARK: - FlutterPlugin

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let view = SceneKit3DPlugin.activeView else {
            result(FlutterError(code: "NO_VIEW", message: "No active 3D view", details: nil))
            return
        }

        switch call.method {
        case "loadModel":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing path", details: nil))
                return
            }
            view.loadModel(path: path, result: result)

        case "updateSkeleton":
            guard let args = call.arguments as? [String: Any],
                  let joints = args["joints"] as? [[String: Any]] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing joints", details: nil))
                return
            }
            view.updateSkeleton(joints: joints)
            result(nil)

        case "setCamera":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing camera args", details: nil))
                return
            }
            view.setCamera(args: args)
            result(nil)

        case "setLighting":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing lighting args", details: nil))
                return
            }
            view.setLighting(args: args)
            result(nil)

        case "animate":
            guard let args = call.arguments as? [String: Any],
                  let name = args["name"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing animation name", details: nil))
                return
            }
            view.animate(name: name)
            result(nil)

        case "reset":
            view.resetScene()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
