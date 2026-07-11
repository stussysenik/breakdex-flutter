import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Opens the persistent web SQLite database backed by `sqlite3.wasm`.
///
/// Drift probes the browser and picks the best available storage — OPFS
/// (durable, multi-tab) when supported, falling back to IndexedDB. Both
/// `web/sqlite3.wasm` and `web/drift_worker.js` are served from the web root
/// (see `web/`); the wasm is ABI-pinned to the `sqlite3` version in
/// `pubspec.yaml` (bump both in lockstep).
///
/// Any reduced-durability fallback is surfaced (not silently swallowed) per the
/// web release's "platform gaps degrade visibly" contract.
QueryExecutor openPlatformConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'breakdex',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    if (result.missingFeatures.isNotEmpty) {
      debugPrint(
        '[drift/web] storage=${result.chosenImplementation.name} '
        'degraded — missing ${result.missingFeatures.map((f) => f.name).join(', ')}',
      );
    }
    return result.resolvedExecutor;
  });
}
