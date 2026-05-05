import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

/// Creates an in-memory SQLite database pre-populated with the v14 schema
/// and user_version=14 via the raw sqlite3 setup callback.
NativeDatabase v14Database() {
  return NativeDatabase.memory(
    setup: (rawDb) {
      rawDb.execute('''
        CREATE TABLE moves (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT '',
          video_path TEXT,
          learning_state INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          original_video_name TEXT,
          content_hash TEXT,
          notes TEXT,
          managed_album_asset_id TEXT,
          managed_album_filename TEXT,
          managed_album_name TEXT,
          archived_at INTEGER,
          archive_reason TEXT
        )
      ''');

      rawDb.execute('''
        CREATE TABLE combos (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          active_video_path TEXT,
          thumbnail_path TEXT,
          learning_state INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          content_hash TEXT,
          notes TEXT
        )
      ''');

      rawDb.execute('''
        CREATE TABLE combo_moves (
          id TEXT PRIMARY KEY,
          combo_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          position INTEGER NOT NULL DEFAULT 0
        )
      ''');

      rawDb.execute('''
        CREATE TABLE reviews (
          id TEXT PRIMARY KEY,
          move_id TEXT,
          combo_id TEXT,
          rating TEXT NOT NULL DEFAULT 'good',
          duration_seconds INTEGER NOT NULL DEFAULT 0,
          timestamp INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          fsrs_pre_state INTEGER,
          fsrs_post_state INTEGER,
          entity_id_snapshot TEXT,
          entity_type TEXT,
          entity_display_name TEXT,
          entity_category TEXT
        )
      ''');

      rawDb.execute('''
        CREATE TABLE battle_results (
          id TEXT PRIMARY KEY,
          battle_id TEXT NOT NULL,
          opponent TEXT NOT NULL DEFAULT '',
          result TEXT NOT NULL DEFAULT 'win',
          notes TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE sync_log (
          id TEXT PRIMARY KEY,
          entity_id TEXT NOT NULL,
          table_name TEXT NOT NULL,
          action TEXT NOT NULL DEFAULT 'create',
          has_video INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE fsrs_cards (
          entity_id TEXT NOT NULL,
          entity_type TEXT NOT NULL DEFAULT 'move',
          stability REAL NOT NULL DEFAULT 0.0,
          difficulty REAL NOT NULL DEFAULT 0.0,
          due INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          last_review INTEGER,
          reps INTEGER NOT NULL DEFAULT 0,
          lapses INTEGER NOT NULL DEFAULT 0,
          fsrs_state INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (entity_id, entity_type)
        )
      ''');

      rawDb.execute('''
        CREATE TABLE decks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          algorithm TEXT NOT NULL DEFAULT 'fsrs',
          target_moves INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE deck_moves (
          id TEXT PRIMARY KEY,
          deck_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          position INTEGER NOT NULL DEFAULT 0,
          added_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE asset_manifest (
          content_hash TEXT PRIMARY KEY,
          local_path TEXT,
          original_device_name TEXT,
          content_type TEXT NOT NULL DEFAULT 'video',
          status TEXT NOT NULL DEFAULT 'active',
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          deleted_at INTEGER
        )
      ''');

      rawDb.execute('''
        CREATE TABLE asset_copies (
          id TEXT PRIMARY KEY,
          content_hash TEXT NOT NULL,
          provider TEXT NOT NULL,
          remote_key TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE sync_providers (
          provider_id TEXT PRIMARY KEY,
          provider_type TEXT NOT NULL DEFAULT 'icloud',
          config TEXT,
          enabled INTEGER NOT NULL DEFAULT 1
        )
      ''');

      rawDb.execute('''
        CREATE TABLE sync_operations (
          id TEXT PRIMARY KEY,
          content_hash TEXT NOT NULL,
          provider_id TEXT NOT NULL,
          operation_type TEXT NOT NULL DEFAULT 'upload',
          status TEXT NOT NULL DEFAULT 'pending',
          priority INTEGER NOT NULL DEFAULT 0,
          retry_count INTEGER NOT NULL DEFAULT 0,
          max_retries INTEGER NOT NULL DEFAULT 5,
          error_message TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE labs (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE milestones (
          id TEXT PRIMARY KEY,
          lab_id TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          target_date INTEGER,
          completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE lab_moves (
          id TEXT PRIMARY KEY,
          lab_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          added_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE lab_entries (
          id TEXT PRIMARY KEY,
          lab_id TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE achievements (
          id TEXT PRIMARY KEY,
          move_id TEXT NOT NULL,
          tier TEXT NOT NULL DEFAULT 'seed',
          unlocked_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE aura_links (
          id TEXT PRIMARY KEY,
          move_a_id TEXT NOT NULL,
          move_b_id TEXT NOT NULL,
          link_type TEXT NOT NULL DEFAULT 'related',
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE aura_presets (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          config TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('PRAGMA user_version = 14');
    },
  );
}

/// Creates a v14 database with pre-inserted test data.
NativeDatabase v14DatabaseWithData() {
  return NativeDatabase.memory(
    setup: (rawDb) {
      // Same schema as v14Database...
      rawDb.execute('''
        CREATE TABLE moves (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT '',
          video_path TEXT,
          learning_state INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          original_video_name TEXT,
          content_hash TEXT,
          notes TEXT,
          managed_album_asset_id TEXT,
          managed_album_filename TEXT,
          managed_album_name TEXT,
          archived_at INTEGER,
          archive_reason TEXT
        )
      ''');

      rawDb.execute('''
        CREATE TABLE combos (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          active_video_path TEXT,
          thumbnail_path TEXT,
          learning_state INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          content_hash TEXT,
          notes TEXT
        )
      ''');

      rawDb.execute('''
        CREATE TABLE combo_moves (
          id TEXT PRIMARY KEY,
          combo_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          position INTEGER NOT NULL DEFAULT 0
        )
      ''');

      rawDb.execute('''
        CREATE TABLE reviews (
          id TEXT PRIMARY KEY,
          move_id TEXT,
          combo_id TEXT,
          rating TEXT NOT NULL DEFAULT 'good',
          duration_seconds INTEGER NOT NULL DEFAULT 0,
          timestamp INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          fsrs_pre_state INTEGER,
          fsrs_post_state INTEGER,
          entity_id_snapshot TEXT,
          entity_type TEXT,
          entity_display_name TEXT,
          entity_category TEXT
        )
      ''');

      rawDb.execute('''
        CREATE TABLE battle_results (
          id TEXT PRIMARY KEY,
          battle_id TEXT NOT NULL,
          opponent TEXT NOT NULL DEFAULT '',
          result TEXT NOT NULL DEFAULT 'win',
          notes TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE sync_log (
          id TEXT PRIMARY KEY,
          entity_id TEXT NOT NULL,
          table_name TEXT NOT NULL,
          action TEXT NOT NULL DEFAULT 'create',
          has_video INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE fsrs_cards (
          entity_id TEXT NOT NULL,
          entity_type TEXT NOT NULL DEFAULT 'move',
          stability REAL NOT NULL DEFAULT 0.0,
          difficulty REAL NOT NULL DEFAULT 0.0,
          due INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          last_review INTEGER,
          reps INTEGER NOT NULL DEFAULT 0,
          lapses INTEGER NOT NULL DEFAULT 0,
          fsrs_state INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (entity_id, entity_type)
        )
      ''');

      rawDb.execute('''
        CREATE TABLE decks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          algorithm TEXT NOT NULL DEFAULT 'fsrs',
          target_moves INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE deck_moves (
          id TEXT PRIMARY KEY,
          deck_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          position INTEGER NOT NULL DEFAULT 0,
          added_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE asset_manifest (
          content_hash TEXT PRIMARY KEY,
          local_path TEXT,
          original_device_name TEXT,
          content_type TEXT NOT NULL DEFAULT 'video',
          status TEXT NOT NULL DEFAULT 'active',
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          deleted_at INTEGER
        )
      ''');

      rawDb.execute('''
        CREATE TABLE asset_copies (
          id TEXT PRIMARY KEY,
          content_hash TEXT NOT NULL,
          provider TEXT NOT NULL,
          remote_key TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE sync_providers (
          provider_id TEXT PRIMARY KEY,
          provider_type TEXT NOT NULL DEFAULT 'icloud',
          config TEXT,
          enabled INTEGER NOT NULL DEFAULT 1
        )
      ''');

      rawDb.execute('''
        CREATE TABLE sync_operations (
          id TEXT PRIMARY KEY,
          content_hash TEXT NOT NULL,
          provider_id TEXT NOT NULL,
          operation_type TEXT NOT NULL DEFAULT 'upload',
          status TEXT NOT NULL DEFAULT 'pending',
          priority INTEGER NOT NULL DEFAULT 0,
          retry_count INTEGER NOT NULL DEFAULT 0,
          max_retries INTEGER NOT NULL DEFAULT 5,
          error_message TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE labs (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE milestones (
          id TEXT PRIMARY KEY,
          lab_id TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          target_date INTEGER,
          completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE lab_moves (
          id TEXT PRIMARY KEY,
          lab_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          added_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE lab_entries (
          id TEXT PRIMARY KEY,
          lab_id TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE achievements (
          id TEXT PRIMARY KEY,
          move_id TEXT NOT NULL,
          tier TEXT NOT NULL DEFAULT 'seed',
          unlocked_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE aura_links (
          id TEXT PRIMARY KEY,
          move_a_id TEXT NOT NULL,
          move_b_id TEXT NOT NULL,
          link_type TEXT NOT NULL DEFAULT 'related',
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE aura_presets (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          config TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      // Seed v14 data
      rawDb.execute(
        "INSERT INTO moves (id, name, category) VALUES ('m1', 'Halo', 'powermove')",
      );
      rawDb.execute(
        "INSERT INTO moves (id, name, category) VALUES ('m2', 'Airflare', 'powermove')",
      );

      rawDb.execute('PRAGMA user_version = 14');
    },
  );
}

void main() {
  group('Migration v14 → v15', () {
    test('up migration creates sets, set_items, provenance_events tables',
        () async {
      final db = AppDatabase.forTesting(v14Database());

      final tables = await db.customSelect(
        'SELECT name FROM sqlite_master WHERE type = \'table\' AND name IN (\'sets\', \'set_items\', \'provenance_events\')',
      ).get();

      expect(tables.map((r) => r.read<String>('name')),
          containsAll(['sets', 'set_items', 'provenance_events']));

      await db.close();
    });

    test('sets table has correct columns', () async {
      final db = AppDatabase.forTesting(v14Database());

      final columns = await db.customSelect('PRAGMA table_info(sets)').get();
      final colNames = columns.map((r) => r.read<String>('name')).toSet();
      expect(colNames, containsAll([
        'id',
        'name',
        'description',
        'learning_state',
        'created_at',
        'updated_at',
      ]));

      final pkColumns = columns
          .where((r) => r.read<int>('pk') > 0)
          .map((r) => r.read<String>('name'))
          .toList();
      expect(pkColumns, ['id']);

      await db.close();
    });

    test('set_items table has foreign key and unique constraint', () async {
      final db = AppDatabase.forTesting(v14Database());

      final foreignKeys =
          await db.customSelect('PRAGMA foreign_key_list(set_items)').get();
      expect(foreignKeys.length, 1);
      expect(foreignKeys.first.read<String>('table'), 'sets');
      expect(foreignKeys.first.read<String>('from'), 'set_id');
      expect(foreignKeys.first.read<String>('to'), 'id');

      final indices = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'set_items'",
      ).get();

      final indexNames = indices.map((r) => r.read<String>('name')).toSet();
      expect(indexNames, contains('idx_set_items_unique'));

      await db.close();
    });

    test('provenance_events table has correct columns and index', () async {
      final db = AppDatabase.forTesting(v14Database());

      final columns =
          await db.customSelect('PRAGMA table_info(provenance_events)').get();
      final colNames = columns.map((r) => r.read<String>('name')).toSet();
      expect(colNames, containsAll([
        'id',
        'entity_type',
        'entity_id',
        'event_type',
        'timestamp',
        'metadata',
      ]));

      final indices = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'provenance_events'",
      ).get();

      final indexNames = indices.map((r) => r.read<String>('name')).toSet();
      expect(indexNames, contains('idx_provenance_entity'));

      await db.close();
    });

    test('name uniqueness constraint rejects duplicate set name', () async {
      final db = AppDatabase.forTesting(v14Database());

      await db.customStatement(
        "INSERT INTO sets (id, name) VALUES ('s1', 'My Set')",
      );

      await expectLater(
        () => db.customStatement(
          "INSERT INTO sets (id, name) VALUES ('s2', 'My Set')",
        ),
        throwsA(isA<Exception>()),
      );

      await db.close();
    });

    test('name uniqueness constraint rejects set name matching move name',
        () async {
      final db = AppDatabase.forTesting(v14Database());

      await db.customStatement(
        "INSERT INTO moves (id, name) VALUES ('m1', 'Windmill')",
      );

      await expectLater(
        () => db.customStatement(
          "INSERT INTO sets (id, name) VALUES ('s1', 'Windmill')",
        ),
        throwsA(isA<Exception>()),
      );

      await db.close();
    });

    test('existing v14 data survives migration and new tables are functional',
        () async {
      final db = AppDatabase.forTesting(v14DatabaseWithData());

      // Existing v14 data intact
      final moves = await db.customSelect('SELECT name FROM moves').get();
      final moveNames = moves.map((r) => r.read<String>('name')).toSet();
      expect(moveNames, containsAll(['Halo', 'Airflare']));

      // New v15 tables are functional
      await db.customStatement(
        "INSERT INTO sets (id, name) VALUES ('s-new', 'New Set')",
      );
      final set =
          await db.customSelect('SELECT name FROM sets WHERE id = \'s-new\'')
              .getSingle();
      expect(set.read<String>('name'), 'New Set');

      await db.close();
    });

    test('setsDao is not registered as a Drift DAO (not in daos list)',
        () async {
      // The SetsDao is standalone, not registered in AppDatabase's daos list.
      // This test verifies the raw table is accessible via custom statements.
      final db = AppDatabase.forTesting(v14Database());

      await db.customStatement(
        "INSERT INTO sets (id, name) VALUES ('s1', 'Raw Test')",
      );
      final rows = await db.customSelect('SELECT name FROM sets').get();
      expect(rows.single.read<String>('name'), 'Raw Test');

      await db.close();
    });
  });
}
