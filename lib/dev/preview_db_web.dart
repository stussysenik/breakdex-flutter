import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqlite3/wasm.dart';

/// Web (widget-preview scaffold) executor: a worker-less, in-memory SQLite DB
/// backed by `sqlite3.wasm`. The wasm ships as a package asset (see pubspec)
/// and is loaded through [rootBundle] so the asset key resolves regardless of
/// how the preview scaffold remaps root-project asset URIs. In-memory means a
/// fresh, re-seeded database every session — exactly what previews want.
Future<QueryExecutor> openPreviewExecutor() async {
  final wasm = await rootBundle.load('packages/breakdex/assets/sqlite3.wasm');
  final sqlite3 = await WasmSqlite3.load(wasm.buffer.asUint8List());
  return WasmDatabase.inMemory(sqlite3);
}
