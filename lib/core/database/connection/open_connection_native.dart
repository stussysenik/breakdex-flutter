import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'package:breakdex/core/services/app_storage_paths.dart';

/// Opens the on-disk SQLite database via FFI, off the UI isolate.
QueryExecutor openPlatformConnection() {
  return LazyDatabase(() async {
    final dir = await AppStoragePaths.documentsDirectory();
    final file = File(p.join(dir.path, 'breakdex.db'));
    return NativeDatabase.createInBackground(file);
  });
}
