import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

/// Builds an in-memory database at the v26 schema — the five delete-bearing
/// tables carry `deleted_at`, and `move_note_entries`/`combo_note_entries` exist
/// but have NEITHER `updated_at` NOR `deleted_at` yet — seeded with
/// production-shaped rows and `user_version = 26`, so the v26→v27 migration
/// (which adds + backfills the note-entry LWW clocks and adds their soft-hide
/// column) runs on open. Only the tables the v27 block + the unconditional
/// post-migration steps touch are created.
NativeDatabase v26Database() {
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
          updated_at INTEGER,
          deleted_at INTEGER
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
          updated_at INTEGER,
          deleted_at INTEGER
        )
      ''');
      rawDb.execute('''
        CREATE TABLE combo_moves (
          id TEXT PRIMARY KEY,
          combo_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          sequence_index INTEGER NOT NULL DEFAULT 0,
          count INTEGER NOT NULL DEFAULT 1,
          updated_at INTEGER,
          deleted_at INTEGER
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
      rawDb.execute('''
        CREATE TABLE decks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          deck_type TEXT NOT NULL DEFAULT 'smart',
          filter_criteria TEXT,
          session_size INTEGER,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          deleted_at INTEGER
        )
      ''');
      rawDb.execute('''
        CREATE TABLE deck_moves (
          deck_id TEXT NOT NULL,
          move_id TEXT NOT NULL,
          updated_at INTEGER,
          deleted_at INTEGER,
          PRIMARY KEY (deck_id, move_id)
        )
      ''');
      // Note-entry tables at v26: present, but WITHOUT updated_at/deleted_at.
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
        'INSERT INTO combos (id, name, created_at, updated_at) '
        "VALUES ('c1', 'Combo', 1700000000, 1700000000)",
      );
      // Note entries with a KNOWN created_at; updated_at is backfilled from it.
      rawDb.execute(
        'INSERT INTO move_note_entries (id, move_id, body, created_at) '
        "VALUES ('mn1', 'm1', 'jot A', 1699000111)",
      );
      rawDb.execute(
        'INSERT INTO combo_note_entries (id, combo_id, body, created_at) '
        "VALUES ('cn1', 'c1', 'jot B', 1699000222)",
      );

      rawDb.execute('PRAGMA user_version = 26');
    },
  );
}

void main() {
  group('Migration v26 → v27', () {
    test('adds updated_at + deleted_at to both note-entry tables', () async {
      final db = AppDatabase.forTesting(v26Database());
      for (final table in const ['move_note_entries', 'combo_note_entries']) {
        final cols =
            await db.customSelect('PRAGMA table_info($table)').get();
        final names = cols.map((final r) => r.read<String>('name')).toSet();
        expect(names, contains('updated_at'), reason: '$table.updated_at');
        expect(names, contains('deleted_at'), reason: '$table.deleted_at');
      }
      await db.close();
    });

    test('backfills updated_at from created_at; deleted_at stays NULL',
        () async {
      final db = AppDatabase.forTesting(v26Database());
      final mn = await db
          .customSelect(
              'SELECT updated_at, deleted_at FROM move_note_entries WHERE id = ?',
              variables: [Variable.withString('mn1')])
          .getSingle();
      expect(mn.read<int>('updated_at'), 1699000111);
      expect(mn.readNullable<int>('deleted_at'), isNull);

      final cn = await db
          .customSelect(
              'SELECT updated_at, deleted_at FROM combo_note_entries WHERE id = ?',
              variables: [Variable.withString('cn1')])
          .getSingle();
      expect(cn.read<int>('updated_at'), 1699000222);
      expect(cn.readNullable<int>('deleted_at'), isNull);
      await db.close();
    });

    test('row counts identical across migration (non-destructive)', () async {
      final db = AppDatabase.forTesting(v26Database());
      Future<int> count(final String table) async =>
          (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
              .read<int>('c');
      expect(await count('move_note_entries'), 1);
      expect(await count('combo_note_entries'), 1);
      await db.close();
    });

    test('note DAOs stamp updated_at on add + update', () async {
      final db = AppDatabase.forTesting(v26Database());
      final before = DateTime.now().toUtc();

      await db.moveNoteEntriesDao
          .addEntry(id: 'mn2', moveId: 'm1', body: 'new');
      final added = await db.moveNoteEntriesDao.getById('mn2');
      expect(added!.updatedAt, isNotNull);
      expect(
        added.updatedAt!.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );

      await db.moveNoteEntriesDao.updateEntry('mn2', 'edited');
      final edited = await db.moveNoteEntriesDao.getById('mn2');
      expect(edited!.updatedAt!.isBefore(added.updatedAt!), isFalse);
      await db.close();
    });

    test('note DAO writes log to sync_log (dirty-tracking hook)', () async {
      final db = AppDatabase.forTesting(v26Database());
      await db.comboNoteEntriesDao
          .addEntry(id: 'cn2', comboId: 'c1', body: 'x');
      await db.comboNoteEntriesDao.deleteEntry('cn2');

      final logs = await db
          .customSelect(
              "SELECT action FROM sync_log WHERE entity_table = 'combo_note_entries' "
              "AND entity_id = 'cn2' ORDER BY action")
          .get();
      expect(
        logs.map((final r) => r.read<String>('action')).toList(),
        containsAll(<String>['create', 'delete']),
      );
      await db.close();
    });

    test('direct upsert preserves an explicit remote clock (no clobber)',
        () async {
      final db = AppDatabase.forTesting(v26Database());
      final remoteTs = DateTime.utc(2020, 1, 1, 12);
      await db.into(db.moveNoteEntries).insertOnConflictUpdate(
            MoveNoteEntriesCompanion.insert(
              id: 'mn9',
              moveId: 'm1',
              body: 'remote',
              updatedAt: Value(remoteTs),
            ),
          );
      final row = await db.moveNoteEntriesDao.getById('mn9');
      expect(row!.updatedAt!.isAtSameMomentAs(remoteTs), isTrue);
      await db.close();
    });
  });
}
