import Flutter

/// Protocol that every native iOS capability conforms to.
///
/// This is the foundation of Breakdex's native bridge architecture — any iOS-specific
/// feature (video export, ML inference, 3D rendering, HealthKit, NFC, etc.) implements
/// this protocol instead of ad-hoc FlutterPlugin registration.
///
/// **Convention:**
/// - Method channel: `com.breakdex/{channelName}`
/// - Event channel:  `com.breakdex/{channelName}/stream` (optional)
///
/// Conforming types are auto-registered by `CapabilityRegistry` — no manual
/// registrar wiring needed in AppDelegate.
protocol NativeCapability: FlutterPlugin {
    /// Base name for the MethodChannel (e.g. "video_export").
    /// Full channel path becomes `com.breakdex/{channelName}`.
    static var channelName: String { get }

    /// Optional EventChannel for streaming data back to Dart.
    /// Full channel path becomes `com.breakdex/{channelName}/stream`.
    /// Return `nil` if this capability doesn't stream events.
    static var eventChannelName: String? { get }
}

// Default: no event channel unless the conforming type overrides.
extension NativeCapability {
    static var eventChannelName: String? { nil }
}
