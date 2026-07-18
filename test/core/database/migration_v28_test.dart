import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

/// Builds an in-memory database at the v27 schema carrying the exact duplicate
/// shapes production accumulated (design D7):
///
/// * `h1` — one logical local copy occupying THREE rows, one per legacy id
///   scheme (`${move.id}_local` from the legacy migration, `${hash}_local` from
///   import, `${hash}_local_redownload` from the on-demand downloader), plus
///   two `gdrive` rows from re-uploads under fresh UUIDs. `copy_count` was
///   stamped 5 — the two-copy minimum satisfied on ONE real cloud copy.
/// * `h2` — duplicate `gdrive` rows at different statuses, to prove the
///   most-protective one survives rather than the last one written.
/// * `h3` — a single already-canonical row, to prove the collapse is a no-op
///   on healthy data.
NativeDatabase v27Database() {
  return NativeDatabase.memory(
    setup: (final rawDb) {
      rawDb.execute('''
        CREATE TABLE asset_manifest (
          content_hash TEXT NOT NULL PRIMARY KEY,
          local_path TEXT,
          file_size_bytes INTEGER NOT NULL DEFAULT 0,
          source_type TEXT NOT NULL DEFAULT 'camera',
          imported_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          copy_count INTEGER NOT NULL DEFAULT 1,
          deleted_at INTEGER
        )
      ''');
      rawDb.execute('''
        CREATE TABLE asset_copies (
          id TEXT NOT NULL PRIMARY KEY,
          content_hash TEXT NOT NULL,
          provider TEXT NOT NULL,
          remote_path TEXT,
          remote_etag TEXT,
          verified_at INTEGER,
          status TEXT NOT NULL DEFAULT 'pending',
          upload_progress REAL,
          error_message TEXT,
          created_at INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Tables the unconditional post-migration steps (review-snapshot
      // backfill, integrity triggers) touch — empty, but they must exist.
      rawDb.execute('''
        CREATE TABLE moves (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT '',
          created_at INTEGER NOT NULL DEFAULT 0,
          archived_at INTEGER,
          updated_at INTEGER,
          deleted_at INTEGER
        )
      ''');
      rawDb.execute('''
        CREATE TABLE combos (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT 0,
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
          reviewed_at INTEGER NOT NULL DEFAULT 0,
          fsrs_pre_state INTEGER,
          fsrs_post_state INTEGER,
          entity_id_snapshot TEXT,
          entity_type TEXT,
          entity_display_name TEXT,
          entity_category TEXT
        )
      ''');

      rawDb.execute(
        'CREATE TABLE sets (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
      );
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
          timestamp INTEGER NOT NULL DEFAULT 0,
          metadata TEXT
        )
      ''');
      rawDb.execute('''
        CREATE TABLE decks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          deck_type TEXT NOT NULL DEFAULT 'smart',
          created_at INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL DEFAULT 0,
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
      rawDb.execute('''
        CREATE TABLE move_note_entries (
          id TEXT PRIMARY KEY,
          move_id TEXT NOT NULL,
          body TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER,
          deleted_at INTEGER
        )
      ''');
      rawDb.execute('''
        CREATE TABLE combo_note_entries (
          id TEXT PRIMARY KEY,
          combo_id TEXT NOT NULL,
          body TEXT NOT NULL,
          kind TEXT NOT NULL DEFAULT 'jot',
          created_at INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER,
          deleted_at INTEGER
        )
      ''');
      rawDb.execute('''
        CREATE TABLE sync_log (
          entity_id TEXT NOT NULL,
          entity_table TEXT NOT NULL,
          action TEXT NOT NULL,
          changed_at INTEGER NOT NULL DEFAULT 0,
          synced INTEGER NOT NULL DEFAULT 0,
          video_synced INTEGER NOT NULL DEFAULT 1,
          PRIMARY KEY (entity_id, entity_table, action)
        )
      ''');

      for (final hash in const ['h1', 'h2', 'h3']) {
        rawDb.execute(
          'INSERT INTO asset_manifest (content_hash, file_size_bytes, copy_count) '
          "VALUES ('$hash', 1024, 5)",
        );
      }

      void copy(
        final String id,
        final String hash,
        final String provider,
        final String status,
        final int updatedAt,
      ) {
        rawDb.execute(
          'INSERT INTO asset_copies '
          '(id, content_hash, provider, status, created_at, updated_at) '
          "VALUES ('$id', '$hash', '$provider', '$status', 0, $updatedAt)",
        );
      }

      // h1: three local id schemes + two UUID gdrive rows.
      copy('move-abc_local', 'h1', 'local', 'verified', 100);
      copy('h1_local', 'h1', 'local', 'verified', 200);
      copy('h1_local_redownload', 'h1', 'local', 'verified', 150);
      copy('8f14e45f-uuid-one', 'h1', 'gdrive', 'verified', 300);
      copy('c9f0f895-uuid-two', 'h1', 'gdrive', 'verified', 400);

      // h2: the most-protective status must win regardless of recency.
      copy('h2-newest-failed', 'h2', 'gdrive', 'failed', 900);
      copy('h2-older-verified', 'h2', 'gdrive', 'verified', 100);

      // h3: already canonical and unique.
      copy('h3_local', 'h3', 'local', 'verified', 100);

      rawDb.execute('PRAGMA user_version = 27');
    },
  );
}

Future<List<Map<String, Object?>>> _copies(
  final AppDatabase db,
  final String hash,
) async {
  final rows = await db
      .customSelect(
        'SELECT id, provider, status FROM asset_copies '
        'WHERE content_hash = ? ORDER BY provider, id',
        variables: [Variable.withString(hash)],
      )
      .get();
  return rows
      .map((final r) => <String, Object?>{
            'id': r.read<String>('id'),
            'provider': r.read<String>('provider'),
            'status': r.read<String>('status'),
          })
      .toList();
}

Future<int> _copyCount(final AppDatabase db, final String hash) async {
  final row = await db
      .customSelect(
        'SELECT copy_count FROM asset_manifest WHERE content_hash = ?',
        variables: [Variable.withString(hash)],
      )
      .getSingle();
  return row.read<int>('copy_count');
}

void main() {
  group('Migration v27 → v28 — copy identity', () {
    test('collapses five rows to one per (contentHash, provider)', () async {
      final db = AppDatabase.forTesting(v27Database());
      final rows = await _copies(db, 'h1');

      expect(rows.length, 2);
      expect(
        rows.map((final r) => r['id']).toList(),
        ['h1_gdrive', 'h1_local'],
      );
      await db.close();
    });

    test('keeps the most-protective status, not the newest row', () async {
      final db = AppDatabase.forTesting(v27Database());
      final rows = await _copies(db, 'h2');

      expect(rows.length, 1);
      expect(rows.single['status'], 'verified');
      expect(rows.single['id'], 'h2_gdrive');
      await db.close();
    });

    test('leaves already-canonical rows untouched', () async {
      final db = AppDatabase.forTesting(v27Database());
      final rows = await _copies(db, 'h3');

      expect(rows.length, 1);
      expect(rows.single['id'], 'h3_local');
      await db.close();
    });

    test('recomputes copy_count from surviving rows', () async {
      final db = AppDatabase.forTesting(v27Database());

      // Was stamped 5 — one real cloud copy dressed as five.
      expect(await _copyCount(db, 'h1'), 2);
      expect(await _copyCount(db, 'h2'), 1);
      expect(await _copyCount(db, 'h3'), 1);
      await db.close();
    });

    test('unique index rejects a duplicate (contentHash, provider)', () async {
      final db = AppDatabase.forTesting(v27Database());

      await expectLater(
        db.customStatement(
          'INSERT INTO asset_copies '
          '(id, content_hash, provider, status, created_at, updated_at) '
          "VALUES ('sneaky', 'h3', 'local', 'verified', 0, 0)",
        ),
        throwsA(isA<Exception>()),
      );
      await db.close();
    });

    test('no asset loses its only copy (non-destructive)', () async {
      final db = AppDatabase.forTesting(v27Database());
      for (final hash in const ['h1', 'h2', 'h3']) {
        expect((await _copies(db, hash)).isNotEmpty, isTrue, reason: hash);
      }
      await db.close();
    });
  });
}
