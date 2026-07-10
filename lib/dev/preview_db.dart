/// Platform-selected Drift executor for the widget-preview harness.
///
/// Widget previews render only on web (Chrome), where `dart:ffi` — and thus
/// Drift's [NativeDatabase] — cannot compile (`Only JS interop members may be
/// 'external'`). This facade hands back a native, in-memory FFI executor for
/// device/test runs and a worker-less WASM in-memory executor for the web
/// preview scaffold, keeping `dart:ffi` out of the web compile entirely.
library;

export 'preview_db_native.dart'
    if (dart.library.js_interop) 'preview_db_web.dart';
