import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:breakdex/core/database/database.dart';

/// Creates an in-memory [AppDatabase] for unit tests.
///
/// Uses SQLite's `:memory:` database — no filesystem needed, each call
/// returns a fresh isolated instance. Perfect for parallel test execution.
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(
    NativeDatabase.memory(setup: (db) {
      // Enable WAL mode for better concurrent read performance in tests.
      db.execute('PRAGMA journal_mode=WAL');
    }),
  );
}
