import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/moves.dart';
import 'tables/combos.dart';
import 'tables/combo_moves.dart';
import 'tables/reviews.dart';
import 'tables/battle_results.dart';
import 'tables/sync_log.dart';
import 'tables/fsrs_cards.dart';
import 'tables/decks.dart';
import 'tables/deck_moves.dart';
import 'daos/moves_dao.dart';
import 'daos/combos_dao.dart';
import 'daos/reviews_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/fsrs_cards_dao.dart';
import 'daos/decks_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Moves, Combos, ComboMoves, Reviews, BattleResults, SyncLog, FsrsCards, Decks, DeckMoves],
  daos: [MovesDao, CombosDao, ReviewsDao, SyncDao, FsrsCardsDao, DecksDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
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
                'ALTER TABLE fsrs_cards RENAME TO fsrs_cards_old');

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
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'breakdex.db'));
    return NativeDatabase.createInBackground(file);
  });
}
