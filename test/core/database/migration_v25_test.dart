import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

/// Builds an in-memory database at the v24 schema — `decks` already has
/// `updated_at` (it always did), but `deck_moves` does NOT — seeded with
/// production-shaped rows and `user_version = 24`, so the v24→v25 migration
/// (which adds and backfills `deck_moves.updated_at` from its parent deck) runs
/// on open. Only the tables the v25 block + the unconditional post-migration
/// steps touch are created.
NativeDatabase v24Database() {
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
          video_creation_date INTEGER,
          updated_at INTEGER
        )
      ''');
      rawDb.execute('''
        CREATE TABLE combos (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          notes TEXT,
          active_video_path TEXT,
          content_hash TEXT,
          status TEXT NOT NULL DEFAULT 'idea',
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER
        )
      ''');
      rawDb.execute('''
        CREATE TABLE combo_moves (
          id TEXT PRIMARY KEY,
          combo_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          sequence_index INTEGER NOT NULL DEFAULT 0,
          count INTEGER NOT NULL DEFAULT 1,
          updated_at INTEGER
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
        CREATE TABLE sets (id TEXT PRIMARY KEY, name TEXT NOT NULL)
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
      // decks at v24: updated_at already present.
      rawDb.execute('''
        CREATE TABLE decks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          deck_type TEXT NOT NULL DEFAULT 'smart',
          filter_criteria TEXT,
          session_size INTEGER,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');
      // deck_moves at v24: composite PK, NO updated_at yet.
      rawDb.execute('''
        CREATE TABLE deck_moves (
          deck_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          PRIMARY KEY (deck_id, move_id)
        )
      ''');
      // DecksDao mutations now log to sync_log (task 4.7 dirty-tracking hook).
      rawDb.execute('''
        CREATE TABLE sync_log (
          entity_id TEXT NOT NULL,
          entity_table TEXT NOT NULL,
          action TEXT NOT NULL,
          changed_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          synced INTEGER NOT NULL DEFAULT 0,
          video_synced INTEGER NOT NULL DEFAULT 1,
          PRIMARY KEY (entity_id, entity_table, action)
        )
      ''');

      rawDb.execute(
        'INSERT INTO moves (id, name, category, created_at, updated_at) '
        "VALUES ('m1', 'Windmill', 'powermove', 1700000000, 1700000000)",
      );
      rawDb.execute(
        'INSERT INTO moves (id, name, category, created_at, updated_at) '
        "VALUES ('m2', 'Flare', 'powermove', 1700000000, 1700000000)",
      );
      // A deck with a KNOWN updated_at, and two join rows that get backfilled.
      rawDb.execute(
        'INSERT INTO decks (id, name, created_at, updated_at) '
        "VALUES ('d1', 'Powermoves', 1699000000, 1700000123)",
      );
      rawDb.execute(
        "INSERT INTO deck_moves (deck_id, move_id) VALUES ('d1', 'm1')",
      );
      rawDb.execute(
        "INSERT INTO deck_moves (deck_id, move_id) VALUES ('d1', 'm2')",
      );

      // Note-entry tables exist from v18/v19 (+ kind/video from v22); the v27
      // migration adds their updated_at/deleted_at, so they must be present here.
      rawDb.execute('''
        CREATE TABLE move_note_entries (
          id TEXT PRIMARY KEY,
          move_id TEXT NOT NULL,
          body TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');
      rawDb.execute('''
        CREATE TABLE combo_note_entries (
          id TEXT PRIMARY KEY,
          combo_id TEXT NOT NULL,
          body TEXT NOT NULL,
          kind TEXT NOT NULL DEFAULT 'jot',
          video_path TEXT,
          video_hash TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      rawDb.execute('PRAGMA user_version = 24');
    },
  );
}

void main() {
  group('Migration v24 → v25', () {
    test('adds deck_moves.updated_at and backfills every row from its parent '
        'deck updated_at', () async {
      final db = AppDatabase.forTesting(v24Database());

      final cols =
          await db.customSelect('PRAGMA table_info(deck_moves)').get();
      expect(
        cols.map((final r) => r.read<String>('name')).toSet(),
        contains('updated_at'),
      );

      final rows = await db
          .customSelect('SELECT move_id, updated_at FROM deck_moves ORDER BY move_id')
          .get();
      expect(rows.length, 2);
      // Both join rows inherit the parent deck's updated_at — no residual NULL.
      expect(rows[0].read<int>('updated_at'), 1700000123);
      expect(rows[1].read<int>('updated_at'), 1700000123);

      await db.close();
    });

    test('row counts identical across migration', () async {
      final db = AppDatabase.forTesting(v24Database());
      Future<int> count(final String table) async =>
          (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
              .read<int>('c');
      expect(await count('decks'), 1);
      expect(await count('deck_moves'), 2);
      await db.close();
    });

    test('DecksDao stamps updated_at on deck insert + update', () async {
      final db = AppDatabase.forTesting(v24Database());
      final before = DateTime.now().toUtc();

      await db.decksDao.insertDeck(DecksCompanion.insert(id: 'd2', name: 'New'));
      final inserted = await db.decksDao.getById('d2');
      expect(
        inserted!.updatedAt.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );

      await db.decksDao.updateDeck(
        const DecksCompanion(id: Value('d2'), name: Value('Renamed')),
      );
      final updated = await db.decksDao.getById('d2');
      expect(updated!.updatedAt.isBefore(inserted.updatedAt), isFalse);

      await db.close();
    });

    test('DecksDao stamps updated_at on deck_moves insert', () async {
      final db = AppDatabase.forTesting(v24Database());
      final before = DateTime.now().toUtc();

      await db.decksDao.insertDeck(DecksCompanion.insert(id: 'd3', name: 'D3'));
      await db.decksDao.addMoveToDeck('d3', 'm2');
      final row = await (db.select(db.deckMoves)
            ..where((final t) => t.deckId.equals('d3') & t.moveId.equals('m2')))
          .getSingle();
      expect(row.updatedAt, isNotNull);
      expect(
        row.updatedAt!.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );

      await db.close();
    });

    test('direct upsert preserves an explicit remote clock (no clobber)',
        () async {
      final db = AppDatabase.forTesting(v24Database());
      final remoteTs = DateTime.utc(2020, 1, 1, 12);

      await db.into(db.decks).insertOnConflictUpdate(
            DecksCompanion.insert(
              id: 'd9',
              name: 'Remote',
              updatedAt: Value(remoteTs),
            ),
          );
      final row = await db.decksDao.getById('d9');
      expect(row!.updatedAt.isAtSameMomentAs(remoteTs), isTrue);

      await db.close();
    });
  });
}
