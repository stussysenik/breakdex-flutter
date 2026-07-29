import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqlite3/wasm.dart';

/// Web (widget-preview scaffold) executor: a worker-less, in-memory SQLite DB
/// backed by `sqlite3.wasm`. The wasm ships as a package asset (see pubspec)
/// and is loaded through [rootBundle] so the asset key resolves regardless of
/// how the preview scaffold remaps root-project asset URIs. In-memory means a
/// fresh, re-seeded database every session — exactly what previews want.
///
/// The VFS registration is not optional, and "in-memory" does not excuse it.
/// A native sqlite3 build ships default file systems compiled in (`unix`,
/// `win32`); the WASM build ships none, because there is no host filesystem to
/// wrap. `sqlite3_open_v2` still resolves a VFS by name on every open — an
/// empty name meaning "the default" — so with nothing registered the open
/// fails with `SqliteException(1): no such vfs: `, naming the empty string it
/// could not resolve. [InMemoryFileSystem] satisfies that lookup with a
/// `Map<String, Uint8Buffer>` standing in for the disk. `:memory:` databases
/// hold their pages in sqlite's own heap rather than in this VFS, which is why
/// the failure reads as a paradox: the file system is required to open the
/// database, then barely used.
Future<QueryExecutor> openPreviewExecutor() async {
  final wasm = await rootBundle.load('packages/breakdex/assets/sqlite3.wasm');
  final sqlite3 = await WasmSqlite3.load(wasm.buffer.asUint8List());
  sqlite3.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
  return WasmDatabase.inMemory(sqlite3);
}
