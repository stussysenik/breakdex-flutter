import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

/// Creates an in-memory database with the subset of the v21 schema that the
/// v21→v22 migration touches (combos, combo_note_entries, moves, combo_moves,
/// reviews, plus the tables referenced by the integrity triggers), seeded
/// with production-shaped data, and user_version=21.
///
/// [legacyCreatedAt] simulates old devices whose combos table already carries
/// a created_at column from the pre-Drift schema.
NativeDatabase v21Database({final bool legacyCreatedAt = false}) {
  return NativeDatabase.memory(
    setup: (final rawDb) {
      rawDb.execute('''
        CREATE TABLE moves (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT '',
          video_path TEXT,
          learning_state TEXT NOT NULL DEFAULT 'NEW',
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          original_video_name TEXT,
          content_hash TEXT,
          notes TEXT,
          archived_at INTEGER,
          archive_reason TEXT,
          image_paths TEXT,
          count INTEGER NOT NULL DEFAULT 1,
          video_file_size INTEGER,
          video_creation_date INTEGER
        )
      ''');

      rawDb.execute('''
        CREATE TABLE combos (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          notes TEXT,
          active_video_path TEXT,
          content_hash TEXT${legacyCreatedAt ? ",\n          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))" : ''}
        )
      ''');

      rawDb.execute('''
        CREATE TABLE combo_moves (
          id TEXT PRIMARY KEY,
          combo_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          sequence_index INTEGER NOT NULL DEFAULT 0,
          count INTEGER NOT NULL DEFAULT 1
        )
      ''');

      rawDb.execute('''
        CREATE TABLE combo_note_entries (
          id TEXT PRIMARY KEY,
          combo_id TEXT NOT NULL,
          body TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('''
        CREATE TABLE reviews (
          id TEXT PRIMARY KEY,
          move_id TEXT,
          combo_id TEXT,
          rating TEXT NOT NULL DEFAULT 'good',
          review_type TEXT NOT NULL DEFAULT 'standard',
          reviewed_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          fsrs_pre_state INTEGER,
          fsrs_post_state INTEGER,
          entity_id_snapshot TEXT,
          entity_type TEXT,
          entity_display_name TEXT,
          entity_category TEXT
        )
      ''');

      rawDb.execute('''
        CREATE TABLE sets (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL
        )
      ''');

      rawDb.execute('''
        CREATE TABLE set_items (
          id TEXT PRIMARY KEY,
          set_id TEXT NOT NULL,
          item_type TEXT NOT NULL,
          item_id TEXT NOT NULL
        )
      ''');

      rawDb.execute('''
        CREATE TABLE provenance_events (
          id TEXT PRIMARY KEY,
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          event_type TEXT NOT NULL,
          timestamp INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          metadata TEXT
        )
      ''');

      // Production-shaped seed: a combo with journal history, a combo
      // without, a move, a step linking them.
      rawDb.execute(
        "INSERT INTO moves (id, name, category) VALUES ('m1', 'Windmill', 'powermove')",
      );
      rawDb.execute(
        "INSERT INTO combos (id, name, notes) VALUES ('c1', 'Opener Set', 'old notes blob')",
      );
      rawDb.execute(
        "INSERT INTO combos (id, name) VALUES ('c2', 'Fresh Sketch')",
      );
      rawDb.execute(
        "INSERT INTO combo_moves (id, combo_id, move_id, sequence_index) "
        "VALUES ('cm1', 'c1', 'm1', 0)",
      );
      // Entries with known timestamps: earliest = 1700000000
      rawDb.execute(
        "INSERT INTO combo_note_entries (id, combo_id, body, created_at) "
        "VALUES ('e1', 'c1', 'first jot — unicode ✓ → preserved', 1700000000)",
      );
      rawDb.execute(
        "INSERT INTO combo_note_entries (id, combo_id, body, created_at) "
        "VALUES ('e2', 'c1', 'second jot', 1710000000)",
      );

      rawDb.execute('PRAGMA user_version = 21');
    },
  );
}

void main() {
  group('Migration v21 → v22', () {
    test('adds status with idea default and createdAt backfill', () async {
      final db = AppDatabase.forTesting(v21Database());

      final combos = await db
          .customSelect('SELECT id, status, created_at FROM combos ORDER BY id')
          .get();

      expect(combos.length, 2);
      expect(combos[0].read<String>('status'), 'idea');
      expect(combos[1].read<String>('status'), 'idea');

      // c1: backfilled from earliest journal entry
      expect(combos[0].read<int>('created_at'), 1700000000);
      // c2: no entries → backfilled to migration time (non-zero, recent)
      final c2CreatedAt = combos[1].read<int>('created_at');
      expect(c2CreatedAt, greaterThan(1700000000));

      await db.close();
    });

    test('preserves all existing journal entries byte-identical with kind=jot',
        () async {
      final db = AppDatabase.forTesting(v21Database());

      final entries = await db
          .customSelect(
            'SELECT id, combo_id, body, kind, video_path, video_hash, created_at '
            'FROM combo_note_entries ORDER BY created_at',
          )
          .get();

      expect(entries.length, 2);
      expect(entries[0].read<String>('id'), 'e1');
      expect(
        entries[0].read<String>('body'),
        'first jot — unicode ✓ → preserved',
      );
      expect(entries[0].read<int>('created_at'), 1700000000);
      expect(entries[0].read<String>('kind'), 'jot');
      expect(entries[0].readNullable<String>('video_path'), isNull);
      expect(entries[0].readNullable<String>('video_hash'), isNull);
      expect(entries[1].read<String>('body'), 'second jot');
      expect(entries[1].read<String>('kind'), 'jot');

      await db.close();
    });

    test('creates combo_plans with expected columns and indexes', () async {
      final db = AppDatabase.forTesting(v21Database());

      final columns =
          await db.customSelect('PRAGMA table_info(combo_plans)').get();
      final colNames = columns.map((final r) => r.read<String>('name')).toSet();
      expect(
        colNames,
        containsAll([
          'id',
          'combo_id',
          'plan_date',
          'position',
          'created_at',
          'completed_at',
        ]),
      );

      final indices = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'combo_plans'",
          )
          .get();
      final indexNames =
          indices.map((final r) => r.read<String>('name')).toSet();
      expect(indexNames, contains('idx_combo_plans_combo'));
      expect(indexNames, contains('idx_combo_plans_date'));

      await db.close();
    });

    test('row counts identical across migration', () async {
      final db = AppDatabase.forTesting(v21Database());

      Future<int> count(final String table) async {
        final row = await db
            .customSelect('SELECT COUNT(*) AS c FROM $table')
            .getSingle();
        return row.read<int>('c');
      }

      expect(await count('combos'), 2);
      expect(await count('combo_note_entries'), 2);
      expect(await count('combo_moves'), 1);
      expect(await count('moves'), 1);
      expect(await count('combo_plans'), 0);

      await db.close();
    });

    test('legacy devices with pre-existing created_at survive the migration',
        () async {
      final db = AppDatabase.forTesting(v21Database(legacyCreatedAt: true));

      final combos = await db
          .customSelect('SELECT id, status, created_at FROM combos ORDER BY id')
          .get();

      expect(combos.length, 2);
      // Legacy created_at values are respected (non-zero → no backfill
      // overwrite), and status still arrives at its default.
      expect(combos[0].read<String>('status'), 'idea');
      expect(combos[0].read<int>('created_at'), greaterThan(0));

      await db.close();
    });

    test('new columns are writable after migration', () async {
      final db = AppDatabase.forTesting(v21Database());

      await db.customStatement(
        "UPDATE combos SET status = 'attempting' WHERE id = 'c1'",
      );
      final c1 = await db
          .customSelect("SELECT status FROM combos WHERE id = 'c1'")
          .getSingle();
      expect(c1.read<String>('status'), 'attempting');

      await db.customStatement(
        "INSERT INTO combo_plans (id, combo_id, plan_date, position, created_at) "
        "VALUES ('p1', 'c1', strftime('%s','now'), 0, strftime('%s','now'))",
      );
      final plans =
          await db.customSelect('SELECT id FROM combo_plans').get();
      expect(plans.length, 1);

      await db.close();
    });
  });
}
