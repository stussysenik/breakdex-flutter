/// Platform-neutral re-export of the `dart:io` surface the app relies on
/// ([File], [Directory], [Platform], [FileMode], [FileSystemException], …).
///
/// Native builds get the real `dart:io` (byte-identical to importing it
/// directly). The web build gets stubs whose filesystem operations throw a
/// clear [UnsupportedError] — web filesystem access degrades visibly at the
/// UI seam (Phase 1.3) long before these paths are ever reached. Routing every
/// `lib/` file through this facade keeps `dart:io` out of the web compile graph
/// so the whole app (and the widget-preview scaffold, which renders only on
/// web) can build.
library;

export 'io_native.dart'
    if (dart.library.js_interop) 'io_web.dart';
