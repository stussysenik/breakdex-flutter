import 'package:flutter/services.dart';

/// Base class for all native iOS capability bridges.
///
/// Each native module (video export, ML inference, 3D rendering, etc.) extends
/// this class to get consistent MethodChannel + EventChannel wiring.
///
/// **Channel convention:**
/// - Method: `com.breakdex/{capability}`
/// - Events: `com.breakdex/{capability}/stream`
///
/// **Usage:**
/// ```dart
/// class VisionML extends NativeBridge {
///   VisionML() : super('vision_ml');
///   Future<List<PoseJoint>> detectPose(Uint8List data) => ...
/// }
/// ```
abstract class NativeBridge {
  /// The MethodChannel for request/response calls to native code.
  final MethodChannel method;

  /// Optional EventChannel for streaming data from native code.
  /// Null only if the capability doesn't support streaming.
  final EventChannel? events;

  /// Creates a bridge for the given capability name.
  /// [capability] maps to the Swift-side `NativeCapability.channelName`.
  NativeBridge(String capability, {bool hasEventChannel = true})
      : method = MethodChannel('com.breakdex/$capability'),
        events = hasEventChannel
            ? EventChannel('com.breakdex/$capability/stream')
            : null;

  /// Invoke a native method with an optional arguments map.
  /// Returns a typed result or null if the native side returns void.
  Future<T?> invoke<T>(String methodName, [Map<String, dynamic>? args]) {
    return method.invokeMethod<T>(methodName, args);
  }

  /// Stream events from the native side as typed maps.
  /// Throws if this capability was created without an event channel.
  Stream<Map<String, dynamic>> get eventStream {
    assert(events != null, 'This capability does not support event streaming');
    return events!.receiveBroadcastStream().map(
      (e) => Map<String, dynamic>.from(e as Map),
    );
  }
}
