import 'package:drift/drift.dart';

import 'open_connection_native.dart'
    if (dart.library.js_interop) 'open_connection_web.dart';

/// The production [AppDatabase] connection, selected per platform.
///
/// Native builds open an on-disk SQLite file via FFI; the web build has no
/// wired connection yet (see [open_connection_web.dart]). Splitting this keeps
/// `dart:io` and `dart:ffi` out of the web compile so the widget-preview
/// scaffold — which renders only on web — can build the rest of the app.
QueryExecutor openConnection() => openPlatformConnection();
