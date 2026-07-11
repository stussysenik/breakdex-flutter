import 'package:drift/wasm.dart';

/// Source for `web/drift_worker.js` — the dedicated/shared worker that backs
/// the OPFS/IndexedDB WASM database opened in
/// `lib/core/database/connection/open_connection_web.dart`.
///
/// Regenerate after a drift bump (kept out of `web/` so the source is not
/// copied verbatim into the deployed build):
///   dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.js
void main() {
  WasmDatabase.workerMainForOpen();
}
