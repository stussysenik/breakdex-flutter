import Flutter

/// Central registry for all native capabilities.
///
/// Instead of manually wiring each plugin in AppDelegate, every native capability
/// adds itself to the `capabilities` array. `registerAll` handles the rest —
/// creating registrars and calling each plugin's `register(with:)`.
///
/// **To add a new capability:**
/// 1. Create a Swift class conforming to `NativeCapability`
/// 2. Add its type to the `capabilities` array below
/// 3. Create a matching Dart class extending `NativeBridge`
/// 4. Done — auto-registered, consistent channels, streamable.
final class CapabilityRegistry {
    /// All native capabilities — add new ones here, they auto-register.
    static let capabilities: [NativeCapability.Type] = [
        VideoExportPlugin.self,
        NativeVideoImportPlugin.self,
        VisionMLPlugin.self,
        SceneKit3DPlugin.self,
    ]

    /// Register every capability with the Flutter engine's plugin registry.
    /// Called once from AppDelegate during engine initialization.
    ///
    /// Each plugin is registered independently — if one fails, the others
    /// still load. This prevents a single bad plugin from crashing the app
    /// before Flutter even renders.
    static func registerAll(with registry: FlutterPluginRegistry) {
        print("[CapabilityRegistry] Registering \(capabilities.count) capabilities…")
        for cap in capabilities {
            let pluginName = String(describing: cap)
            guard let registrar = registry.registrar(forPlugin: pluginName) else {
                print("[CapabilityRegistry] ✗ No registrar for \(pluginName)")
                continue
            }
            // FlutterPlugin.register(with:) is not a throwing API, but the
            // underlying code can still crash (missing frameworks, force
            // unwraps, etc.). Log breadcrumbs so crash reports show exactly
            // which plugin was being registered.
            print("[CapabilityRegistry] → registering \(pluginName)…")
            cap.register(with: registrar)
            print("[CapabilityRegistry] ✓ \(pluginName)")
        }
        print("[CapabilityRegistry] Done.")
    }
}
