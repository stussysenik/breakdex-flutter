import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Native (device/simulator/test) preview executor: an in-memory SQLite DB via
/// FFI. Never compiled on web — see [preview_db.dart]'s conditional export.
Future<QueryExecutor> openPreviewExecutor() async => NativeDatabase.memory();
