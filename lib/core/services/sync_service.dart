// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import '../platform/io.dart';
import '../platform/native_file_transfer.dart';
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
import '../sync/codecs/combo_codec.dart';
import '../sync/codecs/review_codec.dart';
import '../sync/codecs/fsrs_card_codec.dart';
import '../sync/codecs/deck_codec.dart';

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

  /// Kill-switch for the `moves` dual-*write* (task 4.2). Off by default, so a
  /// flush is byte-identical to Firestore-only until the owner turns it on. When
  /// on (and [syncBackend] is wired), every local `moves` flush also pushes to
  /// the Appwrite shadow — idempotent via `clientOpId`, failures swallowed, never
  /// blocking the Firestore write. This must be live BEFORE dual-read
  /// ([movesDualReadPrefKey]) so the shadow is never read while stale (audit A1).
  static const String movesDualWritePrefKey = 'sync.moves.dualWrite.enabled';

  /// Pref holding the `moves` backend high-water cursor (ms since epoch),
  /// advanced from [SyncDelta.cursor] after each successful pull (H.1).
  /// Deliberately independent of Firestore's shared `last_sync_at` (audit A2):
  /// the two backends have different clocks and delete horizons, so sharing a
  /// cursor would silently skip records. A missing cursor means "full pull".
  static const String movesBackendCursorPrefKey = 'sync.moves.backend.cursor';

  /// Kill-switches + cursors for the `combos` + `comboMoves` **pair** (task 4.4),
  /// which replicate the `moves` strangler-fig (4.1→4.3). The pair shares one
  /// dual-write and one dual-read switch (they cut over together), but each
  /// entity pulls with its **own** cursor — they are distinct backend tables
  /// with independent high-water marks (audit A2, as for moves). Off by default;
  /// flipping a switch off is the instant rollback. Dual-write must precede
  /// dual-read so the shadow is never read while stale (audit A1).
  static const String combosDualWritePrefKey = 'sync.combos.dualWrite.enabled';
  static const String combosDualReadPrefKey = 'sync.combos.dualRead.enabled';
  static const String combosBackendCursorPrefKey = 'sync.combos.backend.cursor';
  static const String comboMovesBackendCursorPrefKey =
      'sync.comboMoves.backend.cursor';

  /// Kill-switches + cursor for `reviews` (task 4.5). Reviews are **append-only**
  /// `reviewEvents`, not an LWW record: a flush only ever pushes new events
  /// (idempotent by the review's own id, deduped server-side by `clientOpId`),
  /// and a pull inserts any event not already present locally — it never merges
  /// or clobbers. Same strangler order as the LWW entities (dual-write must be
  /// live before dual-read so the shadow is never read while stale, audit A1);
  /// both off by default, flipping off is the instant rollback.
  static const String reviewsDualWritePrefKey = 'sync.reviews.dualWrite.enabled';
  static const String reviewsDualReadPrefKey = 'sync.reviews.dualRead.enabled';
  static const String reviewsBackendCursorPrefKey =
      'sync.reviews.backend.cursor';

  /// Kill-switch + cursor for `fsrs_cards` (task 4.6). The card is **derived
  /// server-side** from the `reviewEvents` log (same `fsrs` package, same math)
  /// and **never pushed** — so, unlike every other entity, there is *no*
  /// dual-write switch, only a read one. Dual-read pulls the derived delta and
  /// applies it under an LWW guard keyed on the card's last-review time so a pull
  /// never clobbers a just-finished local review the server hasn't folded yet.
  /// Off by default; flipping off is the instant rollback to the Firestore path.
  static const String fsrsCardsDualReadPrefKey =
      'sync.fsrsCards.dualRead.enabled';
  static const String fsrsCardsBackendCursorPrefKey =
      'sync.fsrsCards.backend.cursor';

  /// Kill-switches + cursors for the `decks` + `deck_moves` **pair** (task 4.7),
  /// replicating the combos-pair strangler (4.4). These are **Appwrite-only**
  /// (D11): decks never had a Firestore leg, so a flush's deck entries no-op
  /// through the Firestore push and only the Appwrite dual-write shadows them.
  /// The pair shares one write and one read switch but pulls with two
  /// independent cursors (distinct backend tables). Off by default; flipping a
  /// switch off is the instant rollback. Dual-write precedes dual-read so the
  /// shadow is never read while stale (audit A1).
  static const String decksDualWritePrefKey = 'sync.decks.dualWrite.enabled';
  static const String decksDualReadPrefKey = 'sync.decks.dualRead.enabled';
  static const String decksBackendCursorPrefKey = 'sync.decks.backend.cursor';
  static const String deckMovesBackendCursorPrefKey =
      'sync.deckMoves.backend.cursor';

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

        // Dual-write `moves` to the Appwrite shadow AFTER Firestore is the source
        // of truth for this flush (task 4.2, strangler order: dual-write precedes
        // any read cutover, audit A1). Pref-gated + non-throwing, so it never
        // blocks or fails the Firestore path.
        await dualWriteMoves(pending.where((final e) => e.entityTable == 'moves'));
        // Same strangler order for the combos + combo_moves pair (task 4.4).
        await dualWriteCombos(pending.where((final e) => e.entityTable == 'combos'));
        await dualWriteComboMoves(
          pending.where((final e) => e.entityTable == 'combo_moves'),
        );
        // Append-only `reviewEvents` (task 4.5): only ever new events, never
        // deletes — same strangler order (dual-write before any read cutover).
        await dualWriteReviews(
          pending.where((final e) => e.entityTable == 'reviews'),
        );
        // Appwrite-only decks + deck_moves pair (task 4.7): no Firestore leg, so
        // these entries no-op through the loop above and are shadowed here only.
        await dualWriteDecks(
          pending.where((final e) => e.entityTable == 'decks'),
        );
        await dualWriteDeckMoves(
          pending.where((final e) => e.entityTable == 'deck_moves'),
        );
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

            await putFileTask(
              FirebaseStorage.instance.ref('videos/$storagePath'),
              absolutePath,
            );
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
            // The combos + combo_moves pair (task 4.4), each with its own cursor.
            if (table == 'combos') {
              try {
                final result = await pullCombosFromBackend();
                if (result != null) continue;
              } on Object catch (e) {
                debugPrint('[SyncService] combos dual-read failed, falling back to Firestore: $e');
              }
            }
            if (table == 'combo_moves') {
              try {
                final result = await pullComboMovesFromBackend();
                if (result != null) continue;
              } on Object catch (e) {
                debugPrint('[SyncService] combo_moves dual-read failed, falling back to Firestore: $e');
              }
            }
            // Append-only reviews (task 4.5): pull new events from the shadow.
            if (table == 'reviews') {
              try {
                final result = await pullReviewsFromBackend();
                if (result != null) continue;
              } on Object catch (e) {
                debugPrint('[SyncService] reviews dual-read failed, falling back to Firestore: $e');
              }
            }
            // Derived FSRS cards (task 4.6): pull-only, server-derived from the
            // reviewEvents log; never pushed.
            if (table == 'fsrs_cards') {
              try {
                final result = await pullFsrsCardsFromBackend();
                if (result != null) continue;
              } on Object catch (e) {
                debugPrint('[SyncService] fsrs_cards dual-read failed, falling back to Firestore: $e');
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

        // Appwrite-only decks + deck_moves pair (task 4.7): no Firestore table to
        // iterate, so pull them explicitly. No-op (returns null) when the read
        // kill-switch is off; a backend hiccup is swallowed so it never blocks
        // the rest of the pull.
        try {
          await pullDecksFromBackend();
        } on Object catch (e) {
          debugPrint('[SyncService] decks dual-read failed: $e');
        }
        try {
          await pullDeckMovesFromBackend();
        } on Object catch (e) {
          debugPrint('[SyncService] deck_moves dual-read failed: $e');
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

            await writeToFileTask(fileObj, localPath);

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

            await writeToFileTask(fileObj, localPath);

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

  /// Dual-write `moves` to the Appwrite shadow (task 4.2). Idempotent and
  /// **non-throwing**: a no-op when the [movesDualWritePrefKey] kill-switch is
  /// off or no [syncBackend] is wired, and any backend failure is logged and
  /// swallowed so it never blocks or fails the Firestore flush that already
  /// committed. Extracted from `pushMetadata` (which touches
  /// `FirebaseFirestore.instance` and so can't be unit-tested) precisely so the
  /// dual-write projection + routing are provable in isolation.
  ///
  /// Upserts reuse `move_codec` (`moveToSyncRecord`) — the same deterministic
  /// `clientOpId`s the backfill uses, so a replay reconciles LWW to a no-op. A
  /// `delete` entry crosses as a **tombstone**, never a hard-delete.
  Future<void> dualWriteMoves(final Iterable<SyncLogData> movesEntries) async {
    final backend = syncBackend;
    if (backend == null || !(prefs.getBool(movesDualWritePrefKey) ?? false)) {
      return;
    }

    final upserts = <SyncRecord>[];
    final deletes = <SyncTombstone>[];
    final now = DateTime.now().toUtc();
    for (final entry in movesEntries) {
      try {
        if (entry.action == 'delete') {
          deletes.add(SyncTombstone(
            id: entry.entityId,
            type: SyncEntityType.move,
            deletedAt: now,
            clientOpId: 'dualwrite:move:delete:${entry.entityId}',
          ));
        } else {
          final move = await db.movesDao.getById(entry.entityId);
          upserts.add(moveToSyncRecord(move));
        }
      } on Object catch (e) {
        // A missing row (e.g. deleted between flush and here) is skipped, never
        // fatal — the shadow is additive.
        debugPrint('[SyncService] dual-write skipped move ${entry.entityId}: $e');
      }
    }

    if (upserts.isEmpty && deletes.isEmpty) return;
    try {
      await backend.push(SyncEntityType.move, upserts: upserts, deletes: deletes);
    } on Object catch (e) {
      // Never block the Firestore path (audit A1); the shadow reconciles on the
      // next flush or the backfill.
      debugPrint('[SyncService] moves dual-write push failed: $e');
    }
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

  // --- combos + combo_moves pair (task 4.4) ---
  //
  // The pair replicates the moves strangler-fig via two shared engines so the
  // per-entity methods carry only what differs (type, codec, pref/cursor keys):
  // [_dualWriteEntity] projects a flush's entries into the backend (pref-gated,
  // non-throwing, tombstone-for-delete — audit A1), and [_pullEntity] pulls a
  // delta under this entity's own cursor and merges each upsert LWW (H.1–H.4).

  /// Dual-write `combos` to the Appwrite shadow (task 4.4). See [dualWriteMoves].
  Future<void> dualWriteCombos(final Iterable<SyncLogData> entries) =>
      _dualWriteEntity(
        type: SyncEntityType.combo,
        prefKey: combosDualWritePrefKey,
        label: 'combo',
        entries: entries,
        recordFor: (final id) async =>
            comboToSyncRecord(await db.combosDao.getById(id)),
      );

  /// Dual-write `combo_moves` to the Appwrite shadow (task 4.4). Shares the
  /// pair's kill-switch with [dualWriteCombos].
  Future<void> dualWriteComboMoves(final Iterable<SyncLogData> entries) =>
      _dualWriteEntity(
        type: SyncEntityType.comboMove,
        prefKey: combosDualWritePrefKey,
        label: 'comboMove',
        entries: entries,
        recordFor: (final id) async => comboMoveToSyncRecord(
          await (db.select(db.comboMoves)..where((final t) => t.id.equals(id)))
              .getSingle(),
        ),
      );

  /// Generic dual-write engine (task 4.4): pref-gated, idempotent, non-throwing.
  /// An `insert`/`update` entry becomes an upsert via [recordFor]; a `delete`
  /// crosses as a tombstone, never a hard-delete. Any per-row or push failure is
  /// logged and swallowed so it never blocks the Firestore flush (audit A1).
  Future<void> _dualWriteEntity({
    required final SyncEntityType type,
    required final String prefKey,
    required final String label,
    required final Iterable<SyncLogData> entries,
    required final Future<SyncRecord> Function(String id) recordFor,
  }) async {
    final backend = syncBackend;
    if (backend == null || !(prefs.getBool(prefKey) ?? false)) return;

    final upserts = <SyncRecord>[];
    final deletes = <SyncTombstone>[];
    final now = DateTime.now().toUtc();
    for (final entry in entries) {
      try {
        if (entry.action == 'delete') {
          deletes.add(SyncTombstone(
            id: entry.entityId,
            type: type,
            deletedAt: now,
            clientOpId: 'dualwrite:$label:delete:${entry.entityId}',
          ));
        } else {
          upserts.add(await recordFor(entry.entityId));
        }
      } on Object catch (e) {
        debugPrint('[SyncService] dual-write skipped $label ${entry.entityId}: $e');
      }
    }

    if (upserts.isEmpty && deletes.isEmpty) return;
    try {
      await backend.push(type, upserts: upserts, deletes: deletes);
    } on Object catch (e) {
      debugPrint('[SyncService] $label dual-write push failed: $e');
    }
  }

  /// Dual-read `combos` (task 4.4). See [pullMovesFromBackend].
  Future<({int applied, int failed})?> pullCombosFromBackend() => _pullEntity(
        type: SyncEntityType.combo,
        prefKey: combosDualReadPrefKey,
        cursorKey: combosBackendCursorPrefKey,
        label: 'combo',
        merge: _mergeComboRecordLww,
      );

  /// Dual-read `combo_moves` (task 4.4). Shares the pair's read kill-switch but
  /// keeps its own cursor (distinct backend table, independent high-water mark).
  Future<({int applied, int failed})?> pullComboMovesFromBackend() =>
      _pullEntity(
        type: SyncEntityType.comboMove,
        prefKey: combosDualReadPrefKey,
        cursorKey: comboMovesBackendCursorPrefKey,
        label: 'comboMove',
        merge: _mergeComboMoveRecordLww,
      );

  /// Generic dual-read engine (task 4.4): pull [type]'s delta from this entity's
  /// own cursor and merge each upsert under [merge] — per-record fault isolated
  /// (H.3), in one transaction (H.4), advancing the cursor only after the merge
  /// commits (lossless retry, A2). Tombstones are not applied (upsert-only).
  /// Returns `null` when disabled so the caller falls back to Firestore.
  Future<({int applied, int failed})?> _pullEntity({
    required final SyncEntityType type,
    required final String prefKey,
    required final String cursorKey,
    required final String label,
    required final Future<bool> Function(SyncRecord) merge,
  }) async {
    final backend = syncBackend;
    if (backend == null || !(prefs.getBool(prefKey) ?? false)) return null;

    final cursorMs = prefs.getInt(cursorKey);
    final since = cursorMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(cursorMs, isUtc: true);

    final delta = await backend.pull(type, since: since);

    var applied = 0;
    var failed = 0;
    await db.transaction(() async {
      for (final record in delta.upserts) {
        try {
          if (await merge(record)) applied++;
        } on Object catch (e) {
          failed++;
          debugPrint('[SyncService] skipped malformed $label ${record.id}: $e');
        }
      }
    });

    final cursor = delta.cursor;
    if (cursor != null) {
      await prefs.setInt(cursorKey, cursor.millisecondsSinceEpoch);
    }
    return (applied: applied, failed: failed);
  }

  /// Merge one remote combo [record] iff it does not clobber a newer local edit
  /// — LWW compared at whole-second granularity (H.2/audit A3), as for moves.
  Future<bool> _mergeComboRecordLww(final SyncRecord record) async {
    final existing = await (db.select(db.combos)
          ..where((final t) => t.id.equals(record.id)))
        .getSingleOrNull();
    if (existing != null) {
      final localClock = existing.updatedAt ?? existing.createdAt;
      if (localClock.millisecondsSinceEpoch ~/ 1000 >=
          record.updatedAt.millisecondsSinceEpoch ~/ 1000) {
        return false;
      }
    }
    await db.into(db.combos).insertOnConflictUpdate(comboFromSyncRecord(record));
    return true;
  }

  /// Merge one remote combo-step [record] under LWW. combo_moves has no
  /// `createdAt`, so a (post-migration unreachable) null local clock is treated
  /// as epoch-0 — oldest-possible, never wins — matching the codec's guard.
  Future<bool> _mergeComboMoveRecordLww(final SyncRecord record) async {
    final existing = await (db.select(db.comboMoves)
          ..where((final t) => t.id.equals(record.id)))
        .getSingleOrNull();
    if (existing != null) {
      final localClock = existing.updatedAt ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      if (localClock.millisecondsSinceEpoch ~/ 1000 >=
          record.updatedAt.millisecondsSinceEpoch ~/ 1000) {
        return false;
      }
    }
    await db
        .into(db.comboMoves)
        .insertOnConflictUpdate(comboMoveFromSyncRecord(record));
    return true;
  }

  // --- reviews: append-only (task 4.5) ---
  //
  // Reviews are *not* an LWW record, so they do not use the shared strangler
  // engines: a review is an immutable event that only ever appends. Dual-write
  // therefore emits **upserts only** (never a tombstone — `reviewEvent` has no
  // deletes), and dual-read merges **insert-if-absent** (an already-present event
  // is never re-applied), keyed by the review's own id.

  /// Dual-write `reviews` to the Appwrite shadow as append-only `reviewEvents`
  /// (task 4.5). Pref-gated, non-throwing (audit A1): a no-op when the
  /// [reviewsDualWritePrefKey] kill-switch is off or no [syncBackend] is wired,
  /// and any per-row or push failure is logged and swallowed so it never blocks
  /// the Firestore flush. Only `create`/`update` entries project to an event via
  /// `review_codec`; a review with no identifiable entity is skipped, and there
  /// are no deletes to cross.
  Future<void> dualWriteReviews(final Iterable<SyncLogData> entries) async {
    final backend = syncBackend;
    if (backend == null || !(prefs.getBool(reviewsDualWritePrefKey) ?? false)) {
      return;
    }

    final upserts = <SyncRecord>[];
    for (final entry in entries) {
      if (entry.action == 'delete') continue; // append-only: nothing to delete
      try {
        final rows = await (db.select(db.reviews)
              ..where((final t) => t.id.equals(entry.entityId)))
            .get();
        if (rows.isEmpty) continue;
        final record = reviewToSyncRecord(rows.first);
        if (record != null) upserts.add(record);
      } on Object catch (e) {
        debugPrint('[SyncService] dual-write skipped review ${entry.entityId}: $e');
      }
    }

    if (upserts.isEmpty) return;
    try {
      await backend.push(SyncEntityType.reviewEvent, upserts: upserts);
    } on Object catch (e) {
      debugPrint('[SyncService] reviews dual-write push failed: $e');
    }
  }

  /// Dual-read `reviews` (task 4.5): pull the `reviewEvent` delta from this
  /// entity's own cursor and append each new event locally. Reuses the generic
  /// upsert-only [_pullEntity] engine (H.3 fault isolation, H.4 one transaction,
  /// A2 lossless cursor); the merge is insert-if-absent, not LWW. Returns `null`
  /// when disabled so the caller falls back to Firestore.
  Future<({int applied, int failed})?> pullReviewsFromBackend() => _pullEntity(
        type: SyncEntityType.reviewEvent,
        prefKey: reviewsDualReadPrefKey,
        cursorKey: reviewsBackendCursorPrefKey,
        label: 'review',
        merge: _mergeReviewRecordAppend,
      );

  /// Append one pulled review [record] iff its id is not already present — a
  /// review event is immutable, so a re-seen id is a no-op (idempotent by id,
  /// mirroring the server-side `clientOpId` dedup). Writes straight to Drift,
  /// bypassing the sync-aware decorator, so a remote-origin event is never
  /// re-enqueued as a local change. Returns whether a row was written.
  Future<bool> _mergeReviewRecordAppend(final SyncRecord record) async {
    final existing = await (db.select(db.reviews)
          ..where((final t) => t.id.equals(record.id)))
        .getSingleOrNull();
    if (existing != null) return false;
    await db.into(db.reviews).insert(reviewFromSyncRecord(record));
    return true;
  }

  // --- fsrs_cards: derived server-side, pull-only (task 4.6) ---
  //
  // The card is a reduction of the entity's `reviewEvents` log, derived by the
  // `reviews-append` Function with the *same* `fsrs` package the client runs, so
  // it is **never pushed** (no dual-write, no backfill) — only pulled. Reuses the
  // generic upsert-only [_pullEntity] engine (H.3 fault isolation, H.4 one
  // transaction, A2 lossless cursor); the merge is an LWW guard, not a blind
  // overwrite, so a pulled card never clobbers a fresher local review.

  /// Dual-read `fsrs_cards` (task 4.6): pull the derived-card delta from this
  /// entity's own cursor and apply each under [_mergeFsrsCardRecordLww]. Returns
  /// `null` when disabled so the caller falls back to Firestore.
  Future<({int applied, int failed})?> pullFsrsCardsFromBackend() =>
      _pullEntity(
        type: SyncEntityType.fsrsCard,
        prefKey: fsrsCardsDualReadPrefKey,
        cursorKey: fsrsCardsBackendCursorPrefKey,
        label: 'fsrsCard',
        merge: _mergeFsrsCardRecordLww,
      );

  /// Merge one pulled derived card [record] iff it does not clobber a fresher
  /// local review. The card's clock is its last-review time: the pulled
  /// [SyncRecord.updatedAt] is the newest `reviewedAt` the server has folded, and
  /// the local card's `lastReview` is the newest review applied on-device. If the
  /// local card reflects a strictly-later review than the server has folded (the
  /// dual-write of that review is still in flight), the pulled card is stale —
  /// skip it. Compared at whole-second granularity (H.2/A3, as for the LWW
  /// entities). A never-reviewed local card (`lastReview == null`) is treated as
  /// epoch-0, so any derived card (which has folded ≥ 1 event) wins.
  Future<bool> _mergeFsrsCardRecordLww(final SyncRecord record) async {
    final entityId = record.json['entityId'] as String;
    final entityType = record.json['entityType'] as String;
    final existing = await (db.select(db.fsrsCards)
          ..where((final t) =>
              t.entityId.equals(entityId) & t.entityType.equals(entityType)))
        .getSingleOrNull();
    if (existing != null) {
      final localClock = existing.lastReview ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      if (localClock.millisecondsSinceEpoch ~/ 1000 >=
          record.updatedAt.millisecondsSinceEpoch ~/ 1000) {
        return false;
      }
    }
    await db
        .into(db.fsrsCards)
        .insertOnConflictUpdate(fsrsCardFromSyncRecord(record));
    return true;
  }

  // --- decks + deck_moves pair (task 4.7; Appwrite-only per D11) ---
  //
  // Decks have no Firestore leg, so a flush's deck entries no-op through the
  // Firestore push loop (`_getLocalRecordBody` returns null for these tables)
  // and are shadowed to Appwrite only by these dual-writes — reusing the same
  // shared [_dualWriteEntity] / [_pullEntity] engines as the combos pair. The
  // pair shares its kill-switches but keeps two independent cursors.

  /// Dual-write `decks` to the Appwrite shadow (task 4.7). See [dualWriteCombos].
  Future<void> dualWriteDecks(final Iterable<SyncLogData> entries) =>
      _dualWriteEntity(
        type: SyncEntityType.deck,
        prefKey: decksDualWritePrefKey,
        label: 'deck',
        entries: entries,
        recordFor: (final id) async =>
            deckToSyncRecord((await db.decksDao.getById(id))!),
      );

  /// Dual-write `deck_moves` to the Appwrite shadow (task 4.7). The sync-log
  /// `entityId` is the composite `'$deckId:$moveId'` (the join has no synthetic
  /// id), split here to fetch the row.
  Future<void> dualWriteDeckMoves(final Iterable<SyncLogData> entries) =>
      _dualWriteEntity(
        type: SyncEntityType.deckMove,
        prefKey: decksDualWritePrefKey,
        label: 'deckMove',
        entries: entries,
        recordFor: (final id) async {
          final sep = id.indexOf(':');
          final deckId = id.substring(0, sep);
          final moveId = id.substring(sep + 1);
          return deckMoveToSyncRecord(
            await (db.select(db.deckMoves)
                  ..where((final t) =>
                      t.deckId.equals(deckId) & t.moveId.equals(moveId)))
                .getSingle(),
          );
        },
      );

  /// Dual-read `decks` (task 4.7). See [pullCombosFromBackend].
  Future<({int applied, int failed})?> pullDecksFromBackend() => _pullEntity(
        type: SyncEntityType.deck,
        prefKey: decksDualReadPrefKey,
        cursorKey: decksBackendCursorPrefKey,
        label: 'deck',
        merge: _mergeDeckRecordLww,
      );

  /// Dual-read `deck_moves` (task 4.7). Shares the pair's read kill-switch but
  /// keeps its own cursor (distinct backend table).
  Future<({int applied, int failed})?> pullDeckMovesFromBackend() =>
      _pullEntity(
        type: SyncEntityType.deckMove,
        prefKey: decksDualReadPrefKey,
        cursorKey: deckMovesBackendCursorPrefKey,
        label: 'deckMove',
        merge: _mergeDeckMoveRecordLww,
      );

  /// Merge one remote deck [record] under LWW at whole-second granularity
  /// (H.2/A3). `decks.updatedAt` is non-null, so no epoch fallback is needed.
  Future<bool> _mergeDeckRecordLww(final SyncRecord record) async {
    final existing = await (db.select(db.decks)
          ..where((final t) => t.id.equals(record.id)))
        .getSingleOrNull();
    if (existing != null) {
      if (existing.updatedAt.millisecondsSinceEpoch ~/ 1000 >=
          record.updatedAt.millisecondsSinceEpoch ~/ 1000) {
        return false;
      }
    }
    await db.into(db.decks).insertOnConflictUpdate(deckFromSyncRecord(record));
    return true;
  }

  /// Merge one remote deck-move [record] under LWW. `deck_moves` has no
  /// `createdAt`, so a (post-migration unreachable) null local clock is epoch-0
  /// — matching the codec's guard. Keyed on the composite `(deckId, moveId)`.
  Future<bool> _mergeDeckMoveRecordLww(final SyncRecord record) async {
    final deckId = record.json['deckId'] as String;
    final moveId = record.json['moveId'] as String;
    final existing = await (db.select(db.deckMoves)
          ..where((final t) =>
              t.deckId.equals(deckId) & t.moveId.equals(moveId)))
        .getSingleOrNull();
    if (existing != null) {
      final localClock = existing.updatedAt ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      if (localClock.millisecondsSinceEpoch ~/ 1000 >=
          record.updatedAt.millisecondsSinceEpoch ~/ 1000) {
        return false;
      }
    }
    await db
        .into(db.deckMoves)
        .insertOnConflictUpdate(deckMoveFromSyncRecord(record));
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
