import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    CapabilityRegistry.registerAll(with: self)
    if let registrar = registrar(forPlugin: "FileOpenPlugin") {
      FileOpenPlugin.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Receives video files opened from the Files app ("Open in Breakdex").
///
/// The app is scene-based (`SceneDelegate: FlutterSceneDelegate`), so incoming
/// URLs arrive through `UISceneDelegate` callbacks that Flutter forwards to
/// scene delegates registered via `registrar.addSceneDelegate`:
/// - Cold start: the URL is in the scene connection options before Dart runs —
///   it is buffered until Dart calls `getPendingFileUrl` after boot.
/// - Warm open: `scene(_:openURLContexts:)` pushes a `fileOpened` call straight
///   to Dart; the buffer is only cleared once Dart confirms it handled it.
///
/// `LSSupportsOpeningDocumentsInPlace` is NO, so iOS hands us an Inbox copy the
/// app owns outright. The security-scoped branch below is defensive only.
final class FileOpenPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
    private var channel: FlutterMethodChannel?
    private var pendingFileUrl: String?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.breakdex/file_open",
            binaryMessenger: registrar.messenger()
        )
        let instance = FileOpenPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addSceneDelegate(instance)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPendingFileUrl":
            result(pendingFileUrl)
            pendingFileUrl = nil
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterSceneLifeCycleDelegate

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions?
    ) -> Bool {
        guard let context = connectionOptions?.urlContexts.first(where: { $0.url.isFileURL }),
              let path = localPath(for: context) else {
            return false
        }
        print("[FileOpenPlugin] Cold-start file URL buffered: \(path)")
        pendingFileUrl = path
        return true
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        guard let context = URLContexts.first(where: { $0.url.isFileURL }),
              let path = localPath(for: context) else {
            return false
        }
        print("[FileOpenPlugin] Warm file open: \(path)")
        pendingFileUrl = path
        channel?.invokeMethod("fileOpened", arguments: path) { [weak self] result in
            let unhandled = result is FlutterError
                || (result as? NSObject) === FlutterMethodNotImplemented
            // Keep the buffer when Dart wasn't listening yet — the post-boot
            // getPendingFileUrl sweep picks it up instead.
            if !unhandled {
                self?.pendingFileUrl = nil
            }
        }
        return true
    }

    /// Returns a readable local path for the opened URL. With documents-in-place
    /// disabled iOS delivers an Inbox copy we own; if an in-place URL slips
    /// through anyway, copy it to tmp under security-scoped access.
    private func localPath(for context: UIOpenURLContext) -> String? {
        let url = context.url
        guard context.options.openInPlace else { return url.path }
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(url.lastPathComponent)
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: url, to: destination)
            return destination.path
        } catch {
            print("[FileOpenPlugin] In-place copy failed: \(error)")
            return nil
        }
    }
}
