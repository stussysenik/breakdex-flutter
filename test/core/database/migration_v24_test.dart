import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

/// Builds an in-memory database at the v23 schema — `moves` already has
/// `updated_at`, but `combos` and `combo_moves` do NOT — seeded with
/// production-shaped rows and `user_version = 23`, so the v23→v24 migration
/// (which adds and backfills both new LWW clocks) runs on open.
///
/// Only the tables the unconditional post-migration steps touch
/// (`_installIntegrityTriggers` + `_backfillReviewSnapshots`) are created.
NativeDatabase v23Database() {
  return NativeDatabase.memory(
    setup: (final rawDb) {
      // moves at v23: updated_at already present.
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

      // combos at v23: no updated_at column yet.
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

      // combo_moves at v23: no updated_at, and no created_at at all.
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

      // A move (so the review-snapshot backfill has work), a combo with a known
      // created_at, and two steps under it (one gets backfilled from the parent).
      rawDb.execute(
        'INSERT INTO moves (id, name, category, created_at, updated_at) '
        "VALUES ('m1', 'Windmill', 'powermove', 1700000000, 1700000000)",
      );
      rawDb.execute(
        'INSERT INTO moves (id, name, category, created_at, updated_at) '
        "VALUES ('m2', 'Flare', 'powermove', 1700000000, 1700000000)",
      );
      rawDb.execute(
        'INSERT INTO combos (id, name, created_at) '
        "VALUES ('c1', 'Opener', 1700000000)",
      );
      // Two distinct steps (combo_moves is unique on combo_id+move_id).
      rawDb.execute(
        'INSERT INTO combo_moves (id, combo_id, move_id, sequence_index) '
        "VALUES ('cm1', 'c1', 'm1', 0)",
      );
      rawDb.execute(
        'INSERT INTO combo_moves (id, combo_id, move_id, sequence_index) '
        "VALUES ('cm2', 'c1', 'm2', 1)",
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

      rawDb.execute('PRAGMA user_version = 23');
    },
  );
}

void main() {
  group('Migration v23 → v24', () {
    test(
      'adds combos.updated_at and backfills it from combos.created_at',
      () async {
        final db = AppDatabase.forTesting(v23Database());

        final cols = await db.customSelect('PRAGMA table_info(combos)').get();
        expect(
          cols.map((final r) => r.read<String>('name')).toSet(),
          contains('updated_at'),
        );

        final combo = await db
            .customSelect(
              'SELECT created_at, updated_at FROM combos WHERE id = ?',
              variables: [Variable.withString('c1')],
            )
            .getSingle();
        expect(combo.read<int>('created_at'), 1700000000);
        expect(combo.read<int>('updated_at'), 1700000000);

        await db.close();
      },
    );

    test('adds combo_moves.updated_at and backfills every step from its parent '
        'combo created_at', () async {
      final db = AppDatabase.forTesting(v23Database());

      final cols = await db
          .customSelect('PRAGMA table_info(combo_moves)')
          .get();
      expect(
        cols.map((final r) => r.read<String>('name')).toSet(),
        contains('updated_at'),
      );

      final steps = await db
          .customSelect(
            'SELECT id, updated_at FROM combo_moves ORDER BY sequence_index',
          )
          .get();
      expect(steps.length, 2);
      // Both steps inherit the parent combo's created_at — no residual NULL.
      expect(steps[0].read<int>('updated_at'), 1700000000);
      expect(steps[1].read<int>('updated_at'), 1700000000);

      await db.close();
    });

    test('row counts identical across migration', () async {
      final db = AppDatabase.forTesting(v23Database());

      Future<int> count(final String table) async =>
          (await db
                  .customSelect('SELECT COUNT(*) AS c FROM $table')
                  .getSingle())
              .read<int>('c');

      expect(await count('combos'), 1);
      expect(await count('combo_moves'), 2);
      expect(await count('moves'), 2);

      await db.close();
    });

    test('CombosDao stamps updated_at on combo insert + update', () async {
      final db = AppDatabase.forTesting(v23Database());
      final before = DateTime.now().toUtc();

      await db.combosDao.insertCombo(
        CombosCompanion.insert(id: 'c2', name: 'New'),
      );
      final inserted = await db.combosDao.getById('c2');
      expect(inserted.updatedAt, isNotNull);
      expect(
        inserted.updatedAt!.isBefore(
          before.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );

      await db.combosDao.updateCombo(
        const CombosCompanion(id: Value('c2'), name: Value('Renamed')),
      );
      final updated = await db.combosDao.getById('c2');
      expect(updated.updatedAt!.isBefore(inserted.updatedAt!), isFalse);

      await db.close();
    });

    test('CombosDao stamps updated_at on combo_moves insert', () async {
      final db = AppDatabase.forTesting(v23Database());
      final before = DateTime.now().toUtc();

      await db.combosDao.addMoveToCombo(
        ComboMovesCompanion.insert(
          id: 'cm3',
          comboId: 'c1',
          moveId: 'm3', // distinct move — combo_moves is unique on combo+move
          sequenceIndex: 2,
        ),
      );
      final step = await (db.select(
        db.comboMoves,
      )..where((final t) => t.id.equals('cm3'))).getSingle();
      expect(step.updatedAt, isNotNull);
      expect(
        step.updatedAt!.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );

      await db.close();
    });

    test(
      'reconcile writes preserve an explicit combo updated_at (no clobber)',
      () async {
        final db = AppDatabase.forTesting(v23Database());
        final remoteTs = DateTime.utc(2020, 1, 1, 12);

        // Direct upsert (the dual-read merge path) must keep the remote clock.
        await db
            .into(db.combos)
            .insertOnConflictUpdate(
              CombosCompanion.insert(
                id: 'c3',
                name: 'Remote',
                updatedAt: Value(remoteTs),
              ),
            );
        final row = await db.combosDao.getById('c3');
        expect(row.updatedAt!.isAtSameMomentAs(remoteTs), isTrue);

        await db.close();
      },
    );
  });
}
