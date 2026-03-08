import Flutter
import UIKit

final class AppPathsPlugin: NSObject, FlutterPlugin, NativeCapability {
    static var channelName: String { "app_paths" }

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.breakdex/app_paths",
            binaryMessenger: registrar.messenger()
        )
        let instance = AppPathsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "documentsDirectory":
            if let url = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first {
                result(url.path)
            } else {
                result(
                    FlutterError(
                        code: "MISSING_DIRECTORY",
                        message: "Unable to resolve documents directory",
                        details: nil
                    )
                )
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
