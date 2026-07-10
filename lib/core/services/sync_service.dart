// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import '../platform/io.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../database/database.dart';
import '../database/daos/sync_dao.dart';
import 'auth_service.dart';
import 'video_path_resolver.dart';
import '../domain/failures/failure.dart';
import '../sync/sync_backend.dart';
import '../sync/codecs/move_codec.dart';

class SyncService {
  final AuthService authService;
  final SyncDao syncDao;
  final AppDatabase db;
  final SharedPreferences prefs;

  /// Canonical metadata backend (Convex) for the strangler-fig dual-read.
  /// Nullable: until the live deployment is provisioned (task 0.2) and wired,
  /// this stays `null` and every pull uses the Firestore path unchanged.
  final SyncBackend? syncBackend;

  SyncService({
    required this.authService,
    required this.syncDao,
    required this.db,
    required this.prefs,
    this.syncBackend,
  });

  /// Kill-switch for the `moves` dual-read (task 2.1). Off by default, so the
  /// live read path is byte-identical to Firestore-only until the owner flips
  /// it on after verifying two-way reconcile against real data. Flipping it
  /// back off is the instant rollback.
  ///
  /// **Prerequisite:** enabling this is only safe once `moves` dual-*write*
  /// (task 4.2) is live. Reading from a shadow that no local flush writes to
  /// would serve permanently-stale data; the strangler-fig order is
  /// dual-write → dual-read, never the reverse (audit A1).
  static const String movesDualReadPrefKey = 'sync.moves.dualRead.enabled';

  /// Pref holding the `moves` backend high-water cursor (ms since epoch),
  /// advanced from [SyncDelta.cursor] after each successful pull (H.1).
  /// Deliberately independent of Firestore's shared `last_sync_at` (audit A2):
  /// the two backends have different clocks and delete horizons, so sharing a
  /// cursor would silently skip records. A missing cursor means "full pull".
  static const String movesBackendCursorPrefKey = 'sync.moves.backend.cursor';

  TaskEither<AppFailure, Unit> authenticate() {
    return authService.refreshAuth().mapLeft((final f) => AppFailure.sync('Authentication failed: ${f.message}'));
  }

  TaskEither<AppFailure, Unit> pushMetadata(final void Function(int, int, String) onProgress) {
    return TaskEither.tryCatch(
      () async {
        final pending = await syncDao.getPendingChanges();
        if (pending.isEmpty) return unit;

        const batchSize = 500;
        for (var i = 0; i < pending.length; i += batchSize) {
          final chunk = pending.skip(i).take(batchSize).toList();
          final batch = FirebaseFirestore.instance.batch();
          final userId = authService.userId;

          onProgress(i + chunk.length, pending.length, chunk.last.entityTable);

          final syncedEntries = <SyncLogData>[];

          for (final entry in chunk) {
            try {
              final table = entry.entityTable;
              final docRef = FirebaseFirestore.instance.collection(table).doc(entry.entityId);

              if (entry.action == 'delete') {
                if (table == 'moves' || table == 'combos') {
                  final storagePath = '$userId/$table/${entry.entityId}.mp4';
                  try {
                    await FirebaseStorage.instance.ref('videos/$storagePath').delete();
                  } on Object catch (_) {}
                }
                batch.delete(docRef);
              } else {
                final body = await _getLocalRecordBody(table, entry.entityId);
                if (body != null) {
                  body['user_id'] = userId;
                  body['updated_at'] = FieldValue.serverTimestamp();
                  batch.set(docRef, body);
                }
              }
              syncedEntries.add(entry);
            } on Object catch (e) {
              debugPrint('[SyncService] Failed to prepare batch entry: $e');
            }
          }

          try {
            await batch.commit();
            for (final entry in syncedEntries) {
              await syncDao.markSynced(entry.entityId, entry.entityTable, entry.action);
            }
          } catch (e) {
            debugPrint('[SyncService] Batch commit failed: $e');
            rethrow;
          }
        }
        return unit;
      },
      (final error, final stackTrace) => AppFailure.sync('Pushing metadata failed: $error'),
    );
  }

  TaskEither<AppFailure, Unit> uploadVideos(final void Function(int, int, String) onProgress) {
    return TaskEither.tryCatch(
      () async {
        final pending = await syncDao.getPendingVideoUploads();
        if (pending.isEmpty) return unit;

        final userId = authService.userId;

        for (var i = 0; i < pending.length; i++) {
          final entry = pending[i];
          onProgress(i + 1, pending.length, entry.entityId);

          try {
            String? videoPath;

            if (entry.entityTable == 'moves') {
              final move = await db.movesDao.getById(entry.entityId);
              videoPath = move.videoPath;
            } else if (entry.entityTable == 'combos') {
              final combo = await db.combosDao.getById(entry.entityId);
              videoPath = combo.activeVideoPath;
            } else {
              continue;
            }

            if (videoPath == null) continue;

            final absolutePath = VideoPathResolver.toAbsolute(videoPath);
            final file = File(absolutePath);
            if (!await file.exists()) continue;

            final storagePath = '$userId/${entry.entityTable}/${entry.entityId}.mp4';

            await FirebaseStorage.instance.ref('videos/$storagePath').putFile(file);
            await syncDao.markVideoSynced(entry.entityId, entry.entityTable);
          } on Object catch (_) {}
        }
        return unit;
      },
      (final error, final stackTrace) => AppFailure.sync('Uploading videos failed: $error'),
    );
  }

  TaskEither<AppFailure, Unit> pullRemote() {
    return TaskEither.tryCatch(
      () async {
        final userId = authService.userId;
        final ms = prefs.getInt('last_sync_at');
        final since = ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

        for (final table in [
          'moves', 'combos', 'combo_moves', 'reviews', 'fsrs_cards', 'battle_results',
        ]) {
          try {
            // Strangler-fig dual-read (task 2.1): serve `moves` from the
            // canonical backend first; on any failure fall through to the
            // Firestore path below so a backend hiccup never blocks a pull. The
            // backend path owns its own cursor (H.1), independent of the
            // Firestore `since` used for the other tables.
            if (table == 'moves') {
              try {
                final result = await pullMovesFromBackend();
                if (result != null) continue;
              } on Object catch (e) {
                debugPrint('[SyncService] moves dual-read failed, falling back to Firestore: $e');
              }
            }

            var query = FirebaseFirestore.instance.collection(table).where('user_id', isEqualTo: userId);
            if (since != null) {
              query = query.where('updated_at', isGreaterThan: since.toUtc().toIso8601String());
            }

            final snapshot = await query.get();
            final records = snapshot.docs.map((final doc) => doc.data()).toList();

            for (final record in records) {
              await _mergeRemoteRecord(table, record);
            }
          } on Object catch (_) {}
        }
        return unit;
      },
      (final error, final stackTrace) => AppFailure.sync('Pulling remote metadata failed: $error'),
    );
  }

  TaskEither<AppFailure, Unit> reconcileLegacy() {
    return TaskEither.tryCatch(
      () async {
        final moves = await db.movesDao.getAll();
        if (moves.isEmpty) return unit;

        final cards = await db.fsrsCardsDao.getAll();
        final stateByMoveId = {
          for (final card in cards.where((final card) => card.entityType == 'move'))
            card.entityId: _learningStateFromFsrs(card.fsrsState),
        };

        for (final move in moves) {
          final desiredState = stateByMoveId[move.id];
          if (desiredState == null || desiredState == move.learningState) continue;

          await db.movesDao.updateMove(
            MovesCompanion(id: Value(move.id), learningState: Value(desiredState)),
          );
        }
        return unit;
      },
      (final error, final stackTrace) => AppFailure.database('Reconciling legacy states failed: $error'),
    );
  }

  TaskEither<AppFailure, Unit> downloadVideos(final void Function(int, int, String) onProgress) {
    return TaskEither.tryCatch(
      () async {
        final userId = authService.userId;
        // Stream downloads straight to disk (H.6): `getData()` caps at 10 MB by
        // default and threw on larger clips — swallowed by the old `catch (_)`,
        // so big videos silently never downloaded. `writeToFile` has no cap.
        // Resolve the docs dir once, not once per file.
        final docsDir = await getApplicationDocumentsDirectory();
        final movesDir = Directory(p.join(docsDir.path, 'Moves'));
        final combosDir = Directory(p.join(docsDir.path, 'Combos'));

        // Download moves
        final moveVideosRef = FirebaseStorage.instance.ref('videos/$userId/moves');
        final moveVideos = await moveVideosRef.listAll();

        final toDownloadMoves = <Reference>[];
        for (final fileObj in moveVideos.items) {
          final moveId = p.basenameWithoutExtension(fileObj.name);
          try {
            final localMove = await db.movesDao.getById(moveId);
            if (localMove.videoPath == null || localMove.videoPath!.isEmpty) {
              toDownloadMoves.add(fileObj);
            } else if (!await File(VideoPathResolver.toAbsolute(localMove.videoPath!)).exists()) {
              toDownloadMoves.add(fileObj);
            }
          } on Object catch (_) {}
        }

        for (var i = 0; i < toDownloadMoves.length; i++) {
          final fileObj = toDownloadMoves[i];
          final moveId = p.basenameWithoutExtension(fileObj.name);
          onProgress(i + 1, toDownloadMoves.length, moveId);

          try {
            if (!await movesDir.exists()) await movesDir.create(recursive: true);
            final localPath = p.join(movesDir.path, '$moveId.mp4');

            await fileObj.writeToFile(File(localPath));

            await (db.update(db.moves)..where((final t) => t.id.equals(moveId))).write(
              MovesCompanion(videoPath: Value(VideoPathResolver.toRelative(localPath))),
            );
          } on Object catch (e) {
            debugPrint('[SyncService] move video download failed for $moveId: $e');
          }
        }

        // Download combos
        final comboVideosRef = FirebaseStorage.instance.ref('videos/$userId/combos');
        final comboVideos = await comboVideosRef.listAll();

        final toDownloadCombos = <Reference>[];
        for (final fileObj in comboVideos.items) {
          final comboId = p.basenameWithoutExtension(fileObj.name);
          try {
            final localCombo = await db.combosDao.getById(comboId);
            if (localCombo.activeVideoPath == null || localCombo.activeVideoPath!.isEmpty) {
              toDownloadCombos.add(fileObj);
            } else if (!await File(VideoPathResolver.toAbsolute(localCombo.activeVideoPath!)).exists()) {
              toDownloadCombos.add(fileObj);
            }
          } on Object catch (_) {}
        }

        for (var i = 0; i < toDownloadCombos.length; i++) {
          final fileObj = toDownloadCombos[i];
          final comboId = p.basenameWithoutExtension(fileObj.name);
          onProgress(i + 1, toDownloadCombos.length, comboId);

          try {
            if (!await combosDir.exists()) await combosDir.create(recursive: true);
            final localPath = p.join(combosDir.path, '$comboId.mp4');

            await fileObj.writeToFile(File(localPath));

            await (db.update(db.combos)..where((final t) => t.id.equals(comboId))).write(
              CombosCompanion(activeVideoPath: Value(VideoPathResolver.toRelative(localPath))),
            );
          } on Object catch (e) {
            debugPrint('[SyncService] combo video download failed for $comboId: $e');
          }
        }

        return unit;
      },
      (final error, final stackTrace) => AppFailure.sync('Downloading videos failed: $error'),
    );
  }

  TaskEither<AppFailure, Unit> reconcileAlbums() {
    return TaskEither.tryCatch(
      () async {
        // Native album reconciliation triggers here
        await prefs.setInt('last_sync_at', DateTime.now().millisecondsSinceEpoch);
        return unit;
      },
      (final error, final stackTrace) => AppFailure.sync('Reconciling albums failed: $error'),
    );
  }

  /// Dual-read for `moves` (task 2.1): pull the moves delta from the canonical
  /// [SyncBackend] using this entity's own persisted cursor (H.1) and merge each
  /// upsert into Drift under last-writer-wins — isolated per-record (H.3) and
  /// inside a single transaction (H.4).
  ///
  /// Returns `(applied, failed)` counts, or `null` when dual-read is disabled
  /// (no [syncBackend] wired, or the [movesDualReadPrefKey] kill-switch is off)
  /// — the caller then falls back to Firestore, preserving today's behavior. A
  /// backend-pull failure **rethrows** (the caller falls back for that cycle)
  /// and leaves the cursor untouched, so nothing is skipped on the next retry.
  ///
  /// Deletes (tombstones) are intentionally **not** applied here: propagating a
  /// hard-delete across the boundary is the destructive step gated behind task
  /// 2.6, so this dual-read only ever upserts. Nothing here removes a local row.
  Future<({int applied, int failed})?> pullMovesFromBackend() async {
    final backend = syncBackend;
    if (backend == null || !(prefs.getBool(movesDualReadPrefKey) ?? false)) {
      return null;
    }

    final cursorMs = prefs.getInt(movesBackendCursorPrefKey);
    final since = cursorMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(cursorMs, isUtc: true);

    final delta = await backend.pull(SyncEntityType.move, since: since);

    var applied = 0;
    var failed = 0;
    await db.transaction(() async {
      for (final record in delta.upserts) {
        try {
          if (await _mergeMoveRecordLww(record)) applied++;
        } on Object catch (e) {
          // A single malformed record is skipped and counted — never aborts the
          // batch (which would degrade moves to the blind Firestore path). H.3.
          failed++;
          debugPrint('[SyncService] skipped malformed move ${record.id}: $e');
        }
      }
    });

    // Advance the cursor only after the merge commits: a mid-cycle backend
    // failure re-pulls from the same high-water mark next time (lossless, A2).
    final cursor = delta.cursor;
    if (cursor != null) {
      await prefs.setInt(
        movesBackendCursorPrefKey,
        cursor.millisecondsSinceEpoch,
      );
    }

    return (applied: applied, failed: failed);
  }

  /// Merge one remote move [record] iff it does not clobber a newer local edit.
  ///
  /// Drift persists DateTimes as whole Unix seconds while backend records carry
  /// milliseconds (H.2/audit A3), so the LWW clocks are compared at second
  /// granularity — otherwise a truncated local (always `.000`) would look stale
  /// against any same-second remote. Ties, and any sub-second race that is
  /// unresolvable once local is truncated, keep the on-device row: a remote must
  /// be a **strictly-newer whole second** to win. That is the data-safety
  /// default — never clobber a local edit we cannot prove is older.
  ///
  /// Writes go straight to Drift, bypassing the sync-aware decorator, so a
  /// remote-origin merge is never re-enqueued as a local change. Returns whether
  /// the row was written.
  Future<bool> _mergeMoveRecordLww(final SyncRecord record) async {
    final existing = await (db.select(db.moves)
          ..where((final t) => t.id.equals(record.id)))
        .getSingleOrNull();
    if (existing != null) {
      final localClock = existing.updatedAt ?? existing.createdAt;
      final localSec = localClock.millisecondsSinceEpoch ~/ 1000;
      final remoteSec = record.updatedAt.millisecondsSinceEpoch ~/ 1000;
      if (localSec >= remoteSec) return false;
    }
    await db.into(db.moves).insertOnConflictUpdate(moveFromSyncRecord(record));
    return true;
  }

  // --- Private Helpers ---

  Future<Map<String, dynamic>?> _getLocalRecordBody(final String table, final String id) async {
    try {
      switch (table) {
        case 'moves':
          final move = await db.movesDao.getById(id);
          return {
            'id': move.id,
            'name': move.name,
            'learning_state': move.learningState,
            'category': move.category,
            'archived_at': move.archivedAt?.toIso8601String(),
            'archive_reason': move.archiveReason,
            'created_at': move.createdAt.toIso8601String(),
          };
        case 'combos':
          final combo = await db.combosDao.getById(id);
          return {
            'id': combo.id,
            'name': combo.name,
            'active_video_path': combo.activeVideoPath,
          };
        case 'combo_moves':
          final result = await (db.select(db.comboMoves)..where((final t) => t.id.equals(id))).getSingle();
          return {
            'id': result.id,
            'sequence_index': result.sequenceIndex,
            'combo_id': result.comboId,
            'move_id': result.moveId,
          };
        case 'reviews':
          final results = await (db.select(db.reviews)..where((final t) => t.id.equals(id))).get();
          if (results.isEmpty) return null;
          final review = results.first;
          return {
            'id': review.id,
            'rating': review.rating,
            'review_type': review.reviewType,
            'reviewed_at': review.reviewedAt.toIso8601String(),
            'move_id': review.moveId,
            'combo_id': review.comboId,
            'entity_id_snapshot': review.entityIdSnapshot,
            'entity_type': review.entityType,
            'entity_display_name': review.entityDisplayName,
            'entity_category': review.entityCategory,
            'fsrs_pre_state': review.fsrsPreState,
            'fsrs_post_state': review.fsrsPostState,
          };
        case 'fsrs_cards':
          final card = await db.fsrsCardsDao.getByEntityId(id) ?? await db.fsrsCardsDao.getByEntityId(id, entityType: 'combo');
          if (card == null) return null;
          return {
            'entity_id': card.entityId,
            'entity_type': card.entityType,
            'stability': card.stability,
            'difficulty': card.difficulty,
            'due': card.due.toIso8601String(),
            'last_review': card.lastReview?.toIso8601String(),
            'reps': card.reps,
            'lapses': card.lapses,
            'fsrs_state': card.fsrsState,
          };
        case 'battle_results':
          final results = await (db.select(db.battleResults)..where((final t) => t.id.equals(id))).get();
          if (results.isEmpty) return null;
          final br = results.first;
          return {
            'id': br.id,
            'score': br.score,
            'moves_reviewed': br.movesReviewed,
            'good_count': br.goodCount,
            'hard_count': br.hardCount,
            'again_count': br.againCount,
            'longest_streak': br.longestStreak,
            'difficulty': br.difficulty,
            'played_at': br.playedAt.toIso8601String(),
          };
        default:
          return null;
      }
    } on Object catch (_) {
      return null;
    }
  }

  Future<void> _mergeRemoteRecord(final String table, final Map<String, dynamic> record) async {
    try {
      switch (table) {
        case 'moves':
          final companion = MovesCompanion(
            id: Value(record['id'] as String),
            name: Value(record['name'] as String),
            learningState: Value(record['learning_state'] as String),
            category: Value(record['category'] as String),
            archivedAt: Value(record['archived_at'] == null ? null : DateTime.parse(record['archived_at'] as String)),
            archiveReason: Value(record['archive_reason'] as String?),
            createdAt: Value(DateTime.parse(record['created_at'] as String)),
          );
          await db.into(db.moves).insertOnConflictUpdate(companion);
          break;
        case 'combos':
          final companion = CombosCompanion(
            id: Value(record['id'] as String),
            name: Value(record['name'] as String),
            activeVideoPath: Value(record['active_video_path'] != null ? VideoPathResolver.toRelative(record['active_video_path'] as String) : null),
          );
          await db.into(db.combos).insertOnConflictUpdate(companion);
          break;
        case 'combo_moves':
          final companion = ComboMovesCompanion(
            id: Value(record['id'] as String),
            sequenceIndex: Value(record['sequence_index'] as int),
            comboId: Value(record['combo_id'] as String),
            moveId: Value(record['move_id'] as String),
          );
          await db.into(db.comboMoves).insertOnConflictUpdate(companion);
          break;
        case 'reviews':
          final companion = ReviewsCompanion(
            id: Value(record['id'] as String),
            rating: Value(record['rating'] as String),
            reviewType: Value(record['review_type'] as String),
            reviewedAt: Value(DateTime.parse(record['reviewed_at'] as String)),
            moveId: Value(record['move_id'] as String?),
            comboId: Value(record['combo_id'] as String?),
            entityIdSnapshot: Value(record['entity_id_snapshot'] as String?),
            entityType: Value(record['entity_type'] as String?),
            entityDisplayName: Value(record['entity_display_name'] as String?),
            entityCategory: Value(record['entity_category'] as String?),
            fsrsPreState: Value(record['fsrs_pre_state'] as int?),
            fsrsPostState: Value(record['fsrs_post_state'] as int?),
          );
          await db.into(db.reviews).insertOnConflictUpdate(companion);
          break;
        case 'fsrs_cards':
          final companion = FsrsCardsCompanion(
            entityId: Value(record['entity_id'] as String),
            entityType: Value((record['entity_type'] as String?) ?? 'move'),
            stability: Value((record['stability'] as num).toDouble()),
            difficulty: Value((record['difficulty'] as num).toDouble()),
            due: Value(DateTime.parse(record['due'] as String)),
            lastReview: Value(record['last_review'] == null ? null : DateTime.parse(record['last_review'] as String)),
            reps: Value(record['reps'] as int),
            lapses: Value(record['lapses'] as int),
            fsrsState: Value(record['fsrs_state'] as int),
          );
          await db.into(db.fsrsCards).insertOnConflictUpdate(companion);
          break;
        case 'battle_results':
          final companion = BattleResultsCompanion(
            id: Value(record['id'] as String),
            score: Value(record['score'] as int),
            movesReviewed: Value(record['moves_reviewed'] as int),
            goodCount: Value(record['good_count'] as int),
            hardCount: Value(record['hard_count'] as int),
            againCount: Value(record['again_count'] as int),
            longestStreak: Value(record['longest_streak'] as int),
            difficulty: Value(record['difficulty'] as String),
            playedAt: Value(DateTime.parse(record['played_at'] as String)),
          );
          await db.into(db.battleResults).insertOnConflictUpdate(companion);
          break;
      }
    } on Object catch (_) {}
  }

  String _learningStateFromFsrs(final int fsrsState) => switch (fsrsState) {
    2 => 'MASTERY',
    1 || 3 => 'LEARNING',
    _ => 'NEW',
  };
}
