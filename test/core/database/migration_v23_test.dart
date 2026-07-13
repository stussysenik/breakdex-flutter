import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

/// Builds an in-memory database at the v22 schema — crucially, a `moves` table
/// WITHOUT `updated_at` — seeded with production-shaped rows and
/// `user_version = 22`, so the v22→v23 migration (which adds and backfills
/// `moves.updated_at`) runs on open.
///
/// Only the tables the unconditional post-migration steps touch
/// (`_installIntegrityTriggers` + `_backfillReviewSnapshots`) are created:
/// moves, combos, combo_moves, reviews, sets, set_items, provenance_events.
NativeDatabase v22Database() {
  return NativeDatabase.memory(
    setup: (final rawDb) {
      // moves at v22: no updated_at column yet.
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
          content_hash TEXT,
          status TEXT NOT NULL DEFAULT 'idea',
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
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

      // Two moves with distinct, known created_at values; a review pointing at
      // one so the review-snapshot backfill has real work to do.
      rawDb.execute(
        'INSERT INTO moves (id, name, category, created_at) '
        "VALUES ('m1', 'Windmill', 'powermove', 1700000000)",
      );
      rawDb.execute(
        'INSERT INTO moves (id, name, category, created_at) '
        "VALUES ('m2', 'Flare', 'powermove', 1710000000)",
      );
      rawDb.execute(
        "INSERT INTO combos (id, name) VALUES ('c1', 'Opener Set')",
      );
      rawDb.execute(
        'INSERT INTO combo_moves (id, combo_id, move_id, sequence_index) '
        "VALUES ('cm1', 'c1', 'm1', 0)",
      );
      rawDb.execute(
        'INSERT INTO reviews (id, move_id, rating, reviewed_at) '
        "VALUES ('r1', 'm1', 'good', 1700000500)",
      );

      rawDb.execute('''
        CREATE TABLE IF NOT EXISTS decks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          deck_type TEXT NOT NULL DEFAULT 'smart',
          filter_criteria TEXT,
          session_size INTEGER,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');
      rawDb.execute('''
        CREATE TABLE IF NOT EXISTS deck_moves (
          deck_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          PRIMARY KEY (deck_id, move_id)
        )
      ''');

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

      rawDb.execute('PRAGMA user_version = 22');
    },
  );
}

void main() {
  group('Migration v22 → v23', () {
    test('adds updated_at and backfills it from created_at', () async {
      final db = AppDatabase.forTesting(v22Database());

      final columns =
          await db.customSelect('PRAGMA table_info(moves)').get();
      final colNames = columns.map((final r) => r.read<String>('name')).toSet();
      expect(colNames, contains('updated_at'));

      final moves = await db
          .customSelect(
            'SELECT id, created_at, updated_at FROM moves ORDER BY id',
          )
          .get();

      expect(moves.length, 2);
      // Every existing row's updated_at seeded from its created_at — the best
      // available proxy for last-modified on a pre-sync device.
      expect(moves[0].read<int>('created_at'), 1700000000);
      expect(moves[0].read<int>('updated_at'), 1700000000);
      expect(moves[1].read<int>('created_at'), 1710000000);
      expect(moves[1].read<int>('updated_at'), 1710000000);

      await db.close();
    });

    test('row counts identical across migration', () async {
      final db = AppDatabase.forTesting(v22Database());

      Future<int> count(final String table) async {
        final row = await db
            .customSelect('SELECT COUNT(*) AS c FROM $table')
            .getSingle();
        return row.read<int>('c');
      }

      expect(await count('moves'), 2);
      expect(await count('combos'), 1);
      expect(await count('combo_moves'), 1);
      expect(await count('reviews'), 1);

      await db.close();
    });

    test('MovesDao stamps updated_at on insert and update', () async {
      final db = AppDatabase.forTesting(v22Database());
      final before = DateTime.now().toUtc();

      await db.movesDao.insertMove(
        MovesCompanion.insert(id: 'm3', name: 'Halo'),
      );
      final inserted = await (db.select(db.moves)
            ..where((final t) => t.id.equals('m3')))
          .getSingle();
      expect(inserted.updatedAt, isNotNull);
      expect(
        inserted.updatedAt!.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );

      await db.movesDao.updateMove(
        const MovesCompanion(id: Value('m3'), name: Value('Halo 2000')),
      );
      final updated = await (db.select(db.moves)
            ..where((final t) => t.id.equals('m3')))
          .getSingle();
      expect(updated.updatedAt!.isBefore(inserted.updatedAt!), isFalse);

      await db.close();
    });

    test('reconcile writes preserve an explicit updated_at (no now() clobber)',
        () async {
      final db = AppDatabase.forTesting(v22Database());
      final remoteTs = DateTime.utc(2020, 1, 1, 12);

      await db.movesDao.insertMove(
        MovesCompanion.insert(
          id: 'm4',
          name: 'Airflare',
          updatedAt: Value(remoteTs),
        ),
      );
      final row = await (db.select(db.moves)
            ..where((final t) => t.id.equals('m4')))
          .getSingle();
      // Same instant as the remote timestamp — drift reads DateTimes back in
      // local tz, so compare moments, not tz-tagged equality. The point: the
      // reconcile clock was NOT clobbered with now().
      expect(row.updatedAt!.isAtSameMomentAs(remoteTs), isTrue);

      await db.close();
    });
  });
}
