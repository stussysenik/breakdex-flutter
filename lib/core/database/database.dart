import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../services/app_storage_paths.dart';
import 'tables/moves.dart';
import 'tables/combos.dart';
import 'tables/combo_moves.dart';
import 'tables/reviews.dart';
import 'tables/battle_results.dart';
import 'tables/sync_log.dart';
import 'tables/fsrs_cards.dart';
import 'tables/decks.dart';
import 'tables/deck_moves.dart';
import 'tables/asset_manifest.dart';
import 'tables/asset_copies.dart';
import 'tables/sync_providers.dart';
import 'tables/sync_operations.dart';
import 'tables/labs.dart';
import 'tables/milestones.dart';
import 'tables/lab_moves.dart';
import 'tables/lab_entries.dart';
import 'tables/achievements.dart';
import 'tables/aura_links.dart';
import 'tables/aura_presets.dart';
import 'tables/sets.dart';
import 'tables/set_items.dart';
import 'tables/provenance_events.dart';
import 'tables/move_note_entries.dart';
import 'tables/combo_note_entries.dart';
import 'tables/combo_plans.dart';
import 'daos/moves_dao.dart';
import 'daos/combos_dao.dart';
import 'daos/reviews_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/fsrs_cards_dao.dart';
import 'daos/decks_dao.dart';
import 'daos/asset_manifest_dao.dart';
import 'daos/asset_copies_dao.dart';
import 'daos/sync_operations_dao.dart';
import 'daos/sync_providers_dao.dart';
import 'daos/labs_dao.dart';
import 'daos/milestones_dao.dart';
import 'daos/lab_entries_dao.dart';
import 'daos/achievements_dao.dart';
import 'daos/aura_dao.dart';
import 'daos/move_note_entries_dao.dart';
import 'daos/combo_note_entries_dao.dart';
import 'daos/combo_plans_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Moves,
    Combos,
    ComboMoves,
    Reviews,
    BattleResults,
    SyncLog,
    FsrsCards,
    Decks,
    DeckMoves,
    AssetManifest,
    AssetCopies,
    SyncProviders,
    SyncOperations,
    Labs,
    Milestones,
    LabMoves,
    LabEntries,
    Achievements,
    AuraLinks,
    AuraPresets,
    Sets,
    SetItems,
    ProvenanceEvents,
    MoveNoteEntries,
    ComboNoteEntries,
    ComboPlans,
  ],
  daos: [
    MovesDao,
    CombosDao,
    ReviewsDao,
    SyncDao,
    FsrsCardsDao,
    DecksDao,
    AssetManifestDao,
    AssetCopiesDao,
    SyncOperationsDao,
    SyncProvidersDao,
    LabsDao,
    MilestonesDao,
    LabEntriesDao,
    AchievementsDao,
    AuraDao,
    MoveNoteEntriesDao,
    ComboNoteEntriesDao,
    ComboPlansDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 23;

  /// Column names currently present on [table] — used to keep migrations
  /// idempotent across legacy databases and tables created mid-upgrade
  /// from current Drift definitions.
  Future<Set<String>> _columnNames(final String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.map((final r) => r.read<String>('name')).toSet();
  }

  Future<void> _installIntegrityTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS moves_name_unique_insert
      BEFORE INSERT ON moves
      FOR EACH ROW
      BEGIN
        SELECT CASE
          WHEN EXISTS (
            SELECT 1
            FROM moves
            WHERE lower(trim(name)) = lower(trim(NEW.name))
          ) OR EXISTS (
            SELECT 1
            FROM combos
            WHERE lower(trim(name)) = lower(trim(NEW.name))
          )
          THEN RAISE(ABORT, 'duplicate_card_name')
        END;
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS moves_name_unique_update
      BEFORE UPDATE OF name ON moves
      FOR EACH ROW
      BEGIN
        SELECT CASE
          WHEN EXISTS (
            SELECT 1
            FROM moves
            WHERE id != OLD.id
              AND lower(trim(name)) = lower(trim(NEW.name))
          ) OR EXISTS (
            SELECT 1
            FROM combos
            WHERE lower(trim(name)) = lower(trim(NEW.name))
          )
          THEN RAISE(ABORT, 'duplicate_card_name')
        END;
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS combos_name_unique_insert
      BEFORE INSERT ON combos
      FOR EACH ROW
      BEGIN
        SELECT CASE
          WHEN EXISTS (
            SELECT 1
            FROM combos
            WHERE lower(trim(name)) = lower(trim(NEW.name))
          ) OR EXISTS (
            SELECT 1
            FROM moves
            WHERE lower(trim(name)) = lower(trim(NEW.name))
          )
          THEN RAISE(ABORT, 'duplicate_card_name')
        END;
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS combos_name_unique_update
      BEFORE UPDATE OF name ON combos
      FOR EACH ROW
      BEGIN
        SELECT CASE
          WHEN EXISTS (
            SELECT 1
            FROM combos
            WHERE id != OLD.id
              AND lower(trim(name)) = lower(trim(NEW.name))
          ) OR EXISTS (
            SELECT 1
            FROM moves
            WHERE lower(trim(name)) = lower(trim(NEW.name))
          )
          THEN RAISE(ABORT, 'duplicate_card_name')
        END;
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS combo_moves_unique_insert
      BEFORE INSERT ON combo_moves
      FOR EACH ROW
      BEGIN
        SELECT CASE
          WHEN EXISTS (
            SELECT 1
            FROM combo_moves
            WHERE combo_id = NEW.combo_id
              AND move_id = NEW.move_id
          )
          THEN RAISE(ABORT, 'duplicate_combo_move')
        END;
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS combo_moves_unique_update
      BEFORE UPDATE OF combo_id, move_id ON combo_moves
      FOR EACH ROW
      BEGIN
        SELECT CASE
          WHEN EXISTS (
            SELECT 1
            FROM combo_moves
            WHERE id != OLD.id
              AND combo_id = NEW.combo_id
              AND move_id = NEW.move_id
          )
          THEN RAISE(ABORT, 'duplicate_combo_move')
        END;
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS sets_name_unique_insert
      BEFORE INSERT ON sets
      FOR EACH ROW
      BEGIN
        SELECT CASE
          WHEN EXISTS (
            SELECT 1
            FROM sets
            WHERE lower(trim(name)) = lower(trim(NEW.name))
          ) OR EXISTS (
            SELECT 1
            FROM moves
            WHERE lower(trim(name)) = lower(trim(NEW.name))
          ) OR EXISTS (
            SELECT 1
            FROM combos
            WHERE lower(trim(name)) = lower(trim(NEW.name))
          )
          THEN RAISE(ABORT, 'duplicate_card_name')
        END;
      END;
    ''');

        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS sets_name_unique_update
          BEFORE UPDATE OF name ON sets
          FOR EACH ROW
          BEGIN
            SELECT CASE
              WHEN EXISTS (
                SELECT 1
                FROM sets
                WHERE id != OLD.id
                  AND lower(trim(name)) = lower(trim(NEW.name))
              ) OR EXISTS (
                SELECT 1
                FROM moves
                WHERE lower(trim(name)) = lower(trim(NEW.name))
              ) OR EXISTS (
                SELECT 1
                FROM combos
                WHERE lower(trim(name)) = lower(trim(NEW.name))
              )
              THEN RAISE(ABORT, 'duplicate_card_name')
            END;
          END;
        ''');

        // v15 indexes — idempotent on both fresh create and upgrade
        await customStatement('''
          CREATE UNIQUE INDEX IF NOT EXISTS idx_set_items_unique
          ON set_items(set_id, item_type, item_id)
        ''');

        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_provenance_entity
          ON provenance_events(entity_type, entity_id, timestamp)
        ''');
      }

  Future<void> _backfillReviewSnapshots() async {
    await customStatement('''
      UPDATE reviews
      SET entity_id_snapshot = CASE
        WHEN entity_id_snapshot IS NOT NULL THEN entity_id_snapshot
        WHEN move_id IS NOT NULL THEN move_id
        WHEN combo_id IS NOT NULL THEN combo_id
        ELSE entity_id_snapshot
      END
    ''');

    await customStatement('''
      UPDATE reviews
      SET entity_type = CASE
        WHEN entity_type IS NOT NULL THEN entity_type
        WHEN combo_id IS NOT NULL THEN 'combo'
        WHEN move_id IS NOT NULL THEN 'move'
        ELSE entity_type
      END
    ''');

    await customStatement('''
      UPDATE reviews
      SET entity_display_name = (
        CASE
          WHEN move_id IS NOT NULL THEN (
            SELECT name FROM moves WHERE moves.id = reviews.move_id
          )
          WHEN combo_id IS NOT NULL THEN (
            SELECT name FROM combos WHERE combos.id = reviews.combo_id
          )
          ELSE entity_display_name
        END
      )
      WHERE entity_display_name IS NULL
    ''');

    await customStatement('''
      UPDATE reviews
      SET entity_category = (
        CASE
          WHEN move_id IS NOT NULL THEN (
            SELECT category FROM moves WHERE moves.id = reviews.move_id
          )
          WHEN combo_id IS NOT NULL THEN 'combo'
          ELSE entity_category
        END
      )
      WHERE entity_category IS NULL
    ''');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (final m) async {
      await m.createAll();
      await _installIntegrityTriggers();
    },
    onUpgrade: (final m, final from, final to) async {
      if (from < 2) {
        await m.createTable(battleResults);
      }
      if (from < 3) {
        await m.createTable(syncLog);
      }
      if (from < 4) {
        // Old fsrs_cards with moveId PK — will be migrated in v8
        await customStatement('''
              CREATE TABLE IF NOT EXISTS fsrs_cards (
                move_id TEXT NOT NULL PRIMARY KEY REFERENCES moves(id) ON DELETE CASCADE,
                stability REAL NOT NULL DEFAULT 0.0,
                difficulty REAL NOT NULL DEFAULT 0.0,
                due INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
                last_review INTEGER,
                reps INTEGER NOT NULL DEFAULT 0,
                lapses INTEGER NOT NULL DEFAULT 0,
                fsrs_state INTEGER NOT NULL DEFAULT 0
              )
            ''');
      }
      if (from < 5) {
        await m.addColumn(moves, moves.originalVideoName);
      }
      if (from < 6) {
        await m.addColumn(reviews, reviews.fsrsPreState);
        await m.addColumn(reviews, reviews.fsrsPostState);
      }
      if (from < 7) {
        await m.createTable(decks);
        await m.createTable(deckMoves);
      }
      if (from < 8) {
        // --- Schema v8: Generalize FSRS cards for moves + combos ---
        //
        // Polymorphic pattern: rename moveId → entityId, add entityType.
        // Composite PK (entityId, entityType) replaces single moveId PK.
        // Drop FK to moves since polymorphic refs can't FK to two tables.

        // 1. Rename old table
        await customStatement(
          'ALTER TABLE fsrs_cards RENAME TO fsrs_cards_old',
        );

        // 2. Create new table with entityId + entityType
        await customStatement('''
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

        // 3. Copy existing move cards → new table
        await customStatement('''
              INSERT INTO fsrs_cards
                (entity_id, entity_type, stability, difficulty, due,
                 last_review, reps, lapses, fsrs_state)
              SELECT
                move_id, 'move', stability, difficulty, due,
                last_review, reps, lapses, fsrs_state
              FROM fsrs_cards_old
            ''');

        // 4. Drop old table
        await customStatement('DROP TABLE fsrs_cards_old');

        // 5. Performance indexes for schedule queries
        await customStatement('''
              CREATE INDEX IF NOT EXISTS idx_fsrs_cards_due
              ON fsrs_cards(due)
            ''');
        await customStatement('''
              CREATE INDEX IF NOT EXISTS idx_fsrs_cards_type_due
              ON fsrs_cards(entity_type, due)
            ''');

        // 6. Add comboId column to reviews
        await m.addColumn(reviews, reviews.comboId);
      }
      if (from < 9) {
        await m.addColumn(reviews, reviews.entityIdSnapshot);
        await m.addColumn(reviews, reviews.entityType);
        await m.addColumn(reviews, reviews.entityDisplayName);
        await m.addColumn(reviews, reviews.entityCategory);
      }
      if (from < 10) {
        // --- Schema v10: Asset sync engine tables ---
        //
        // Content-addressable manifest + copy tracking + cloud provider config
        // + sync operation queue. Enables multi-provider video backup with
        // two-copy enforcement and soft deletes.
        await m.createTable(assetManifest);
        await m.createTable(assetCopies);
        await m.createTable(syncProviders);
        await m.createTable(syncOperations);

        // Add content_hash FK column to moves and combos for linking to manifest.
        await customStatement(
          'ALTER TABLE moves ADD COLUMN content_hash TEXT REFERENCES asset_manifest(content_hash)',
        );
        await customStatement(
          'ALTER TABLE combos ADD COLUMN content_hash TEXT REFERENCES asset_manifest(content_hash)',
        );

        // Index for fast manifest lookups by local path and sync state.
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_asset_manifest_local_path
          ON asset_manifest(local_path)
        ''');
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_asset_copies_hash
          ON asset_copies(content_hash)
        ''');
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_sync_operations_status
          ON sync_operations(status, priority)
        ''');
      }

      if (from < 11) {
        await m.addColumn(moves, moves.notes);
        await m.addColumn(combos, combos.notes);
      }

      if (from < 12) {
        // --- Schema v12: Labs system ---
        // Labs (projects + sets), milestones, lab-move links,
        // daily log entries, achievements, bboy aura.
        await m.createTable(labs);
        await m.createTable(milestones);
        await m.createTable(labMoves);
        await m.createTable(labEntries);
        await m.createTable(achievements);
        await m.createTable(auraLinks);
        await m.createTable(auraPresets);

        // Backfill seed achievements for every existing move.
        await customStatement('''
          INSERT OR IGNORE INTO achievements (id, move_id, tier, unlocked_at, created_at)
          SELECT
            lower(hex(randomblob(16))),
            id,
            'seed',
            strftime('%s', 'now'),
            strftime('%s', 'now')
          FROM moves
        ''');
      }

      if (from < 13) {
        await m.addColumn(moves, moves.managedAlbumAssetId);
        await m.addColumn(moves, moves.managedAlbumFilename);
        await m.addColumn(moves, moves.managedAlbumName);
      }

      if (from < 14) {
        await m.addColumn(moves, moves.archivedAt);
        await m.addColumn(moves, moves.archiveReason);
      }

      if (from < 15) {
        // --- Schema v15: Sets, provenance events, cloud abstraction foundation ---
        await m.createTable(sets);
        await m.createTable(setItems);
        await m.createTable(provenanceEvents);
      }

      if (from < 16) {
        await m.addColumn(moves, moves.imagePaths);
      }

      if (from < 17) {
        await m.addColumn(moves, moves.count);
      }

      if (from < 18) {
        await m.createTable(moveNoteEntries);
      }

      if (from < 19) {
        await m.createTable(comboNoteEntries);
      }

      if (from < 20) {
        await customStatement(
          'ALTER TABLE combo_moves ADD COLUMN count INTEGER NOT NULL DEFAULT 1',
        );
      }

      if (from < 21) {
        await m.addColumn(moves, moves.videoFileSize);
        await m.addColumn(moves, moves.videoCreationDate);
      }

      if (from < 22) {
        // --- Schema v22: Combo journey system (all additive) ---
        //
        // PRAGMA-guarded adds: legacy devices may already carry a
        // created_at on combos (pre-Drift schema), and upgraders from <19
        // get combo_note_entries created from the *current* definition
        // (already including kind/video columns) earlier in this upgrade.
        final comboCols = await _columnNames('combos');
        if (!comboCols.contains('status')) {
          await customStatement(
            "ALTER TABLE combos ADD COLUMN status TEXT NOT NULL DEFAULT 'idea'",
          );
        }
        if (!comboCols.contains('created_at')) {
          // SQLite forbids ADD COLUMN with non-constant default; add with
          // 0 and backfill below.
          await customStatement(
            'ALTER TABLE combos ADD COLUMN created_at INTEGER NOT NULL DEFAULT 0',
          );
        }

        // Backfill createdAt: earliest journal entry when one exists,
        // else migration time. Existing non-zero values are respected.
        await customStatement('''
          UPDATE combos SET created_at = COALESCE(
            (SELECT MIN(e.created_at) FROM combo_note_entries e
              WHERE e.combo_id = combos.id),
            strftime('%s', 'now')
          )
          WHERE created_at IS NULL OR created_at = 0
        ''');

        final entryCols = await _columnNames('combo_note_entries');
        if (!entryCols.contains('kind')) {
          await m.addColumn(comboNoteEntries, comboNoteEntries.kind);
        }
        if (!entryCols.contains('video_path')) {
          await m.addColumn(comboNoteEntries, comboNoteEntries.videoPath);
        }
        if (!entryCols.contains('video_hash')) {
          await m.addColumn(comboNoteEntries, comboNoteEntries.videoHash);
        }

        await m.createTable(comboPlans);
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_combo_plans_combo
          ON combo_plans(combo_id)
        ''');
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_combo_plans_date
          ON combo_plans(plan_date)
        ''');
      }

      if (from < 23) {
        // --- Schema v23: moves.updated_at for Convex last-writer-wins sync ---
        //
        // Additive + backfilled. SQLite forbids ADD COLUMN with a non-constant
        // default, so add nullable, then seed every existing row's updated_at
        // from its created_at (the best available proxy for last-modified).
        final moveCols = await _columnNames('moves');
        if (!moveCols.contains('updated_at')) {
          await customStatement(
            'ALTER TABLE moves ADD COLUMN updated_at INTEGER',
          );
        }
        await customStatement(
          'UPDATE moves SET updated_at = created_at WHERE updated_at IS NULL',
        );
      }

      await _backfillReviewSnapshots();
      await _installIntegrityTriggers();
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await AppStoragePaths.documentsDirectory();
    final file = File(p.join(dir.path, 'breakdex.db'));
    return NativeDatabase.createInBackground(file);
  });
}
