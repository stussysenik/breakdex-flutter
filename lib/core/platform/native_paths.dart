import 'package:breakdex/core/platform/io.dart';

import 'package:breakdex/core/platform/native_paths_native.dart'
    if (dart.library.js_interop) 'native_paths_web.dart';

/// `path_provider`'s application-documents directory is a native filesystem
/// concept — its result is a `dart:io.Directory`, which only unifies with the
/// [io.dart] seam type on native. On web there is no documents directory (the
/// database lives in OPFS via `WasmDatabase`), so this throws: a visible
/// failure, never a fake path.
Future<Directory> appDocumentsDirectory() => nativeAppDocumentsDirectory();
