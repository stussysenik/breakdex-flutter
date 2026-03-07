import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../database/daos/fsrs_cards_dao.dart';
import '../database/daos/moves_dao.dart';
import '../database/daos/combos_dao.dart';

/// One-time migration that creates FSRS card rows for all existing moves.
///
/// Maps legacy learning states to FSRS states with sensible defaults:
/// - NEW → fsrsState=0, stability=0, difficulty=0 (fresh card)
/// - LEARNING → fsrsState=1, stability=0.5, difficulty=5 (mid-learning)
/// - MASTERY → fsrsState=2, stability=30, difficulty=3 (graduated, 30-day interval)
///
/// Guarded by a SharedPreferences flag so it only runs once.
/// All public methods are wrapped in try/catch — migration failure is
/// non-fatal and should never crash the app on startup.
class FsrsMigrationService {
  static const _migrationKey = 'fsrs_migration_v1_complete';
  static const _comboMigrationKey = 'fsrs_combo_migration_v1_complete';

  static Future<void> migrateIfNeeded({
    required MovesDao movesDao,
    required FsrsCardsDao fsrsCardsDao,
    required SharedPreferences prefs,
  }) async {
    try {
      if (prefs.getBool(_migrationKey) == true) return;

      final moves = await movesDao.getAll();
      if (moves.isEmpty) {
        await prefs.setBool(_migrationKey, true);
        return;
      }

      for (final move in moves) {
        final existing =
            await fsrsCardsDao.getByEntityId(move.id, entityType: 'move');
        if (existing != null) continue;

        final (int fsrsState, double stability, double difficulty) =
            switch (move.learningState) {
          'LEARNING' => (1, 0.5, 5.0),
          'MASTERY' => (2, 30.0, 3.0),
          _ => (0, 0.0, 0.0),
        };

        await fsrsCardsDao.upsert(FsrsCardsCompanion(
          entityId: Value(move.id),
          entityType: const Value('move'),
          stability: Value(stability),
          difficulty: Value(difficulty),
          due: Value(DateTime.now().toUtc()),
          reps: Value(fsrsState == 2 ? 5 : 0),
          lapses: const Value(0),
          fsrsState: Value(fsrsState),
        ));
      }

      await prefs.setBool(_migrationKey, true);
    } catch (e) {
      debugPrint('FSRS migration failed (non-fatal): $e');
    }
  }

  /// One-time migration to create FSRS cards for all existing combos.
  ///
  /// Combos start as New (fsrsState=0) since we have no legacy state
  /// to map from — unlike moves which had a learningState column.
  static Future<void> migrateComboCards({
    required CombosDao combosDao,
    required FsrsCardsDao fsrsCardsDao,
    required SharedPreferences prefs,
  }) async {
    try {
      if (prefs.getBool(_comboMigrationKey) == true) return;

      final combos = await combosDao.getAll();
      if (combos.isEmpty) {
        await prefs.setBool(_comboMigrationKey, true);
        return;
      }

      for (final combo in combos) {
        final existing =
            await fsrsCardsDao.getByEntityId(combo.id, entityType: 'combo');
        if (existing != null) continue;

        await fsrsCardsDao.upsert(FsrsCardsCompanion(
          entityId: Value(combo.id),
          entityType: const Value('combo'),
          stability: const Value(0.0),
          difficulty: const Value(0.0),
          due: Value(DateTime.now().toUtc()),
          reps: const Value(0),
          lapses: const Value(0),
          fsrsState: const Value(0),
        ));
      }

      await prefs.setBool(_comboMigrationKey, true);
    } catch (e) {
      debugPrint('FSRS combo migration failed (non-fatal): $e');
    }
  }

  /// How often the integrity check runs on normal cold launch.
  /// Between checks, the scan is skipped to avoid O(n) overhead on every
  /// app start. Set to 24 hours — a reasonable trade-off between safety
  /// and launch performance.
  static const _integrityIntervalMs = 24 * 60 * 60 * 1000; // 24 hours
  static const _integrityLastRunKey = 'fsrs_integrity_last_run';

  /// Integrity check: ensure every move and combo has a corresponding FSRS
  /// card. Self-healing for crashes between entity insert and card create.
  ///
  /// **Performance guard:** This is an O(n) scan over all entities + cards.
  /// To keep cold launch fast, the check is throttled to once per 24 hours
  /// via a SharedPreferences timestamp. Pass [force: true] to bypass the
  /// throttle (e.g. after a migration or import).
  static Future<int> ensureIntegrity({
    required MovesDao movesDao,
    required FsrsCardsDao fsrsCardsDao,
    CombosDao? combosDao,
    SharedPreferences? prefs,
    bool force = false,
  }) async {
    try {
      // Throttle: skip if we already ran recently (unless forced).
      if (!force && prefs != null) {
        final lastRun = prefs.getInt(_integrityLastRunKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastRun < _integrityIntervalMs) {
          debugPrint('FSRS integrity check skipped (ran ${((now - lastRun) / 1000 / 60).round()}m ago)');
          return 0;
        }
      }

      int created = 0;

      // Check moves
      final moves = await movesDao.getAll();
      final cards = await fsrsCardsDao.getAll();
      final moveCardIds = {
        for (final c in cards)
          if (c.entityType == 'move') c.entityId,
      };

      for (final move in moves) {
        if (!moveCardIds.contains(move.id)) {
          await fsrsCardsDao.upsert(FsrsCardsCompanion(
            entityId: Value(move.id),
            entityType: const Value('move'),
            stability: const Value(0.0),
            difficulty: const Value(0.0),
            due: Value(DateTime.now().toUtc()),
            reps: const Value(0),
            lapses: const Value(0),
            fsrsState: const Value(0),
          ));
          created++;
        }
      }

      // Check combos
      if (combosDao != null) {
        final combos = await combosDao.getAll();
        final comboCardIds = {
          for (final c in cards)
            if (c.entityType == 'combo') c.entityId,
        };

        for (final combo in combos) {
          if (!comboCardIds.contains(combo.id)) {
            await fsrsCardsDao.upsert(FsrsCardsCompanion(
              entityId: Value(combo.id),
              entityType: const Value('combo'),
              stability: const Value(0.0),
              difficulty: const Value(0.0),
              due: Value(DateTime.now().toUtc()),
              reps: const Value(0),
              lapses: const Value(0),
              fsrsState: const Value(0),
            ));
            created++;
          }
        }
      }

      // Record successful run timestamp
      await prefs?.setInt(
        _integrityLastRunKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      if (created > 0) {
        debugPrint('FSRS integrity check created $created missing card(s)');
      }

      return created;
    } catch (e) {
      debugPrint('FSRS integrity check failed (non-fatal): $e');
      return 0;
    }
  }
}
