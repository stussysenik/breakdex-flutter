import 'package:drift/drift.dart';

/// The consumer web app's persistent connection is not wired yet: the
/// widget-preview harness constructs its database via [AppDatabase.forTesting]
/// with an in-memory WASM executor, so this path is never reached today.
///
/// Implement it (WasmDatabase + OPFS/IndexedDB persistence) as part of the
/// Flutter-Web release before shipping a web build that constructs
/// `AppDatabase()` directly.
QueryExecutor openPlatformConnection() {
  throw UnsupportedError(
    'Web AppDatabase connection is not implemented yet. Previews use '
    'AppDatabase.forTesting; wire WasmDatabase for the web release.',
  );
}
