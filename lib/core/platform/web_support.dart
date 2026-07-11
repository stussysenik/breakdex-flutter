/// Native-only capability flags for **visible** web degradation (task 1.3).
///
/// Flutter Web has no AVFoundation, no camera/gallery capture, and no
/// local-file I/O ([File] operations throw via the `io.dart` seam). The
/// affordances that depend on those capabilities are therefore hidden or
/// labeled "unavailable" on web rather than opening a control that throws a
/// [MissingPluginException] or a silently-caught [UnsupportedError].
///
/// These read `false` only on web; native builds are unaffected. Real web
/// video import lands in task 1.4 — until then [supportsVideoCaptureAndImport]
/// stays `false` on web, and it is the one flag that flips independently of
/// [supportsNativeVideoExport] once that path exists.
library;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Native AVFoundation video export (trim/crop/speed) is iOS-only. No web
/// equivalent is planned — web consumes already-exported videos.
bool get supportsNativeVideoExport => !kIsWeb;

/// Capturing (camera) or importing (gallery/files) a video into local storage
/// depends on `dart:io` file writes, which throw on web. Deferred to task 1.4.
bool get supportsVideoCaptureAndImport => !kIsWeb;
