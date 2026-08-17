// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'package:breakdex/core/platform/io.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';
import 'package:breakdex/core/sync/cloud_provider.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/sync_dao.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/domain/failures/failure.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:breakdex/core/sync/codecs/move_codec.dart';
import 'package:breakdex/core/sync/codecs/combo_codec.dart';
import 'package:breakdex/core/sync/codecs/review_codec.dart';
import 'package:breakdex/core/sync/codecs/fsrs_card_codec.dart';
import 'package:breakdex/core/sync/codecs/deck_codec.dart';
import 'package:breakdex/core/sync/codecs/note_entry_codec.dart';
import 'package:breakdex/core/sync/backfill/sync_backfill_service.dart';
import 'package:breakdex/core/utils/diagnostics.dart';

class SyncService {
  final SyncDao syncDao;
  final AppDatabase db;
  final SharedPreferences prefs;

  /// Canonical metadata backend (Appwrite) — the only backend. Firebase was
  /// the legacy backend and is now removed for release.
  final SyncBackend? syncBackend;

  /// Every-entity backfill composed for production provisioning. Nullable:
  /// `activateSync()` is a no-op when null (e.g. in tests that don't override
  /// it); the live [syncServiceProvider] wires it from
  /// [fullBackfillServiceProvider].
  final SyncBackfillService? syncBackfillService;

  SyncService({
    required this.syncDao,
    required this.db,
    required this.prefs,
    this.syncBackend,
    this.syncBackfillService,
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

  /// Kill-switches + cursors for the note-entry **pair** (task 4.9),
  /// **Appwrite-only** (D11): note entries never had a Firestore leg. Mirrors the
  /// decks pair — one shared write + one shared read switch, but two independent
  /// cursors (`moveNoteEntries`/`comboNoteEntries` are distinct backend tables).
  /// Off by default; flipping a switch off is the instant rollback.
  static const String noteEntriesDualWritePrefKey =
      'sync.noteEntries.dualWrite.enabled';
  static const String noteEntriesDualReadPrefKey =
      'sync.noteEntries.dualRead.enabled';
  static const String moveNoteEntriesBackendCursorPrefKey =
      'sync.moveNoteEntries.backend.cursor';
  static const String comboNoteEntriesBackendCursorPrefKey =
      'sync.comboNoteEntries.backend.cursor';

  TaskEither<AppFailure, Unit> pushMetadata(final void Function(int, int, String) onProgress) {
    return TaskEither.tryCatch(
      () async {
        final pending = await syncDao.getPendingChanges();
        if (pending.isEmpty) return unit;

        onProgress(pending.length, pending.length, pending.last.entityTable);

        // Appwrite is the canonical metadata backend (Firebase was the legacy
        // backend, removed for release — see excise-firebase-and-restore-compile-speed).
        // Every push is a non-throwing dual-write to the Appwrite shadow: pref-
        // gated OFF until activateSync() flips the kill-switches, so a push is a
        // silent no-op in local-only mode and a live shadow write once synced.
        await dualWriteMoves(pending.where((final e) => e.entityTable == 'moves'));
        await dualWriteCombos(pending.where((final e) => e.entityTable == 'combos'));
        await dualWriteComboMoves(
          pending.where((final e) => e.entityTable == 'combo_moves'),
        );
        await dualWriteReviews(
          pending.where((final e) => e.entityTable == 'reviews'),
        );
        await dualWriteDecks(
          pending.where((final e) => e.entityTable == 'decks'),
        );
        await dualWriteDeckMoves(
          pending.where((final e) => e.entityTable == 'deck_moves'),
        );
        await dualWriteMoveNoteEntries(
          pending.where((final e) => e.entityTable == 'move_note_entries'),
        );
        await dualWriteComboNoteEntries(
          pending.where((final e) => e.entityTable == 'combo_note_entries'),
        );

        // Mark everything synced — the dual-writes above are idempotent and
        // LWW-safe, so a markSynced here is a bookkeeping ack, not a data claim.
        for (final entry in pending) {
          await syncDao.markSynced(entry.entityId, entry.entityTable, entry.action);
        }
        return unit;
      },
      (final error, final stackTrace) => AppFailure.sync('Pushing metadata failed: $error'),
    );
  }

  TaskEither<AppFailure, Unit> uploadVideos(
    final void Function(int, int, String) onProgress, {
    required final List<CloudProvider> providers,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (providers.isEmpty) return unit;
        final pending = await syncDao.getPendingVideoUploads();
        if (pending.isEmpty) return unit;

        // Pick the first provider that supports resumable upload (GDrive, S3 —
        // not every provider needs video byte storage). Firebase Storage was
        // the legacy sink; CloudProvider is the abstraction that replaced it.
        final sink = providers.firstWhere(
          (final p) => p.capabilities.contains(CloudProviderCapability.resumableUpload),
          orElse: () => providers.first,
        );

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

            final remotePath = '${entry.entityTable}/${entry.entityId}.mp4';
            await sink.upload(
              localPath: absolutePath,
              remotePath: remotePath,
              onProgress: (final sent, final total) {
                DiagnosticsLog.debug('Sync',
                    'upload ${entry.entityId} $sent/$total');
              },
            );
            await syncDao.markVideoSynced(entry.entityId, entry.entityTable);
          } on Object catch (e) {
            debugPrint('[SyncService] video upload failed for '
                '${entry.entityId}: $e');
          }
        }
        return unit;
      },
      (final error, final stackTrace) => AppFailure.sync('Uploading videos failed: $error'),
    );
  }

  TaskEither<AppFailure, Unit> pullRemote() {
    return TaskEither.tryCatch(
      () async {
        // Appwrite is the canonical metadata backend. Every pull goes through
        // the SyncBackend contract; each entity is kill-switch-gated (off in
        // local-only, ON after activateSync()) and owns its own cursor, so a
        // backend hiccup on one entity never blocks the rest.
        final results = <String, ({int applied, int failed})>{};

        final moves = await pullMovesFromBackend();
        if (moves != null) results['move'] = moves;

        final combos = await pullCombosFromBackend();
        if (combos != null) results['combo'] = combos;

        final comboMoves = await pullComboMovesFromBackend();
        if (comboMoves != null) results['comboMove'] = comboMoves;

        final reviews = await pullReviewsFromBackend();
        if (reviews != null) results['review'] = reviews;

        final fsrsCards = await pullFsrsCardsFromBackend();
        if (fsrsCards != null) results['fsrsCard'] = fsrsCards;

        final decks = await pullDecksFromBackend();
        if (decks != null) results['deck'] = decks;

        final deckMoves = await pullDeckMovesFromBackend();
        if (deckMoves != null) results['deckMove'] = deckMoves;

        final moveNotes = await pullMoveNoteEntriesFromBackend();
        if (moveNotes != null) results['moveNoteEntry'] = moveNotes;

        final comboNotes = await pullComboNoteEntriesFromBackend();
        if (comboNotes != null) results['comboNoteEntry'] = comboNotes;

        final totalApplied = results.values.fold(0, (final sum, final r) => sum + r.applied);
        DiagnosticsLog.info('Sync', 'pull complete — $totalApplied row(s) applied '
            'across ${results.length} entities: ${results.keys.join(", ")}');
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

  TaskEither<AppFailure, Unit> downloadVideos(
    final void Function(int, int, String) onProgress, {
    required final List<CloudProvider> providers,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (providers.isEmpty) return unit;
        final sink = providers.firstWhere(
          (final p) => p.capabilities.contains(CloudProviderCapability.resumableUpload),
          orElse: () => providers.first,
        );

        final docsDir = await getApplicationDocumentsDirectory();
        final movesDir = Directory(p.join(docsDir.path, 'Moves'));
        final combosDir = Directory(p.join(docsDir.path, 'Combos'));

        // Discover remote video assets and download any that are missing or
        // unrecoverable locally. The CloudProvider abstraction handles the byte
        // transfer; we reconcile against Drift truth.
        final remoteAssets = await sink.list(directory: 'moves');
        for (var i = 0; i < remoteAssets.length; i++) {
          final asset = remoteAssets[i];
          final moveId = p.basenameWithoutExtension(asset.remotePath);
          onProgress(i + 1, remoteAssets.length, moveId);

          try {
            final localMove = await db.movesDao.getById(moveId);
            final existingPath = localMove.videoPath;
            if (existingPath != null &&
                existingPath.isNotEmpty &&
                await File(VideoPathResolver.toAbsolute(existingPath)).exists()) {
              continue; // already have it
            }
            if (!await movesDir.exists()) await movesDir.create(recursive: true);
            final localPath = p.join(movesDir.path, '$moveId.mp4');

            await sink.download(remotePath: asset.remotePath, localPath: localPath);

            await (db.update(db.moves)..where((final t) => t.id.equals(moveId))).write(
              MovesCompanion(videoPath: Value(VideoPathResolver.toRelative(localPath))),
            );
          } on Object catch (e) {
            debugPrint('[SyncService] move video download failed for $moveId: $e');
          }
        }

        final remoteCombos = await sink.list(directory: 'combos');
        for (var i = 0; i < remoteCombos.length; i++) {
          final asset = remoteCombos[i];
          final comboId = p.basenameWithoutExtension(asset.remotePath);
          onProgress(i + 1, remoteCombos.length, comboId);

          try {
            final localCombo = await db.combosDao.getById(comboId);
            final existingPath = localCombo.activeVideoPath;
            if (existingPath != null &&
                existingPath.isNotEmpty &&
                await File(VideoPathResolver.toAbsolute(existingPath)).exists()) {
              continue;
            }
            if (!await combosDir.exists()) await combosDir.create(recursive: true);
            final localPath = p.join(combosDir.path, '$comboId.mp4');

            await sink.download(remotePath: asset.remotePath, localPath: localPath);

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
  /// Inbound tombstones are applied as a reversible soft-hide (task 4.8): a
  /// delete on another device sets `deletedAt` via [_applyMoveTombstone] — the
  /// row and its video bytes are preserved, only hidden from every read path.
  /// Upserts merge first so a create+delete in one delta ends hidden. No hard
  /// delete ever crosses the boundary.
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
      for (final tombstone in delta.deletes) {
        try {
          if (await _applyMoveTombstone(tombstone)) applied++;
        } on Object catch (e) {
          failed++;
          debugPrint('[SyncService] skipped tombstone move ${tombstone.id}: $e');
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
    if (backend == null || !(prefs.getBool(prefKey) ?? false)) {
      // The most common "sync is broken" report is a closed gate, not a failure.
      // Silence here is indistinguishable from a bug, so name which gate shut.
      DiagnosticsLog.debug(
        'Sync',
        'push skipped $label — ${backend == null ? 'no backend' : 'pref $prefKey off'}',
      );
      return;
    }

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
        DiagnosticsLog.warn(
          'Sync',
          'push encode failed $label ${entry.entityId}: $e',
        );
      }
    }

    if (upserts.isEmpty && deletes.isEmpty) return;
    try {
      await backend.push(type, upserts: upserts, deletes: deletes);
      DiagnosticsLog.info(
        'Sync',
        'push ok $label — ${upserts.length} upsert(s), ${deletes.length} delete(s)',
      );
    } on Object catch (e) {
      DiagnosticsLog.error('Sync', 'push FAILED $label: $e');
    }
  }

  /// Dual-read `combos` (task 4.4). See [pullMovesFromBackend].
  Future<({int applied, int failed})?> pullCombosFromBackend() => _pullEntity(
        type: SyncEntityType.combo,
        prefKey: combosDualReadPrefKey,
        cursorKey: combosBackendCursorPrefKey,
        label: 'combo',
        merge: _mergeComboRecordLww,
        applyDelete: _applyComboTombstone,
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
        applyDelete: _applyComboMoveTombstone,
      );

  /// Generic dual-read engine (task 4.4): pull [type]'s delta from this entity's
  /// own cursor and merge each upsert under [merge] — per-record fault isolated
  /// (H.3), in one transaction (H.4), advancing the cursor only after the merge
  /// commits (lossless retry, A2). Inbound tombstones are applied via
  /// [applyDelete] (task 4.8) as a reversible soft-hide, never a hard-delete;
  /// upserts merge first so a create+delete in the same delta ends hidden. When
  /// [applyDelete] is null the entity ignores deletes (upsert-only).
  /// Returns `null` when disabled so the caller falls back to Firestore.
  Future<({int applied, int failed})?> _pullEntity({
    required final SyncEntityType type,
    required final String prefKey,
    required final String cursorKey,
    required final String label,
    required final Future<bool> Function(SyncRecord) merge,
    final Future<bool> Function(SyncTombstone)? applyDelete,
  }) async {
    final backend = syncBackend;
    if (backend == null || !(prefs.getBool(prefKey) ?? false)) return null;
    return _pullAndMergeEntity(
      backend: backend,
      type: type,
      cursorKey: cursorKey,
      label: label,
      merge: merge,
      applyDelete: applyDelete,
    );
  }

  /// The gate-free core of a dual-read: pull [type]'s delta from its own cursor
  /// and merge under LWW (H.3 fault-isolated, H.4 one transaction, A2 lossless
  /// cursor advance). [_pullEntity] wraps this behind the per-entity kill-switch
  /// for the *incremental* live cycle; [hydrateAllFromBackend] calls it directly
  /// for a deliberate full seed. Same merge, same cursor plumbing either way.
  Future<({int applied, int failed})> _pullAndMergeEntity({
    required final SyncBackend backend,
    required final SyncEntityType type,
    required final String cursorKey,
    required final String label,
    required final Future<bool> Function(SyncRecord) merge,
    final Future<bool> Function(SyncTombstone)? applyDelete,
  }) async {
    final cursorMs = prefs.getInt(cursorKey);
    final since = cursorMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(cursorMs, isUtc: true);

    final delta = await backend.pull(type, since: since);
    DiagnosticsLog.debug(
      'Sync',
      'pull $label since=${since?.toIso8601String() ?? 'never'} '
          '→ ${delta.upserts.length} upsert(s), ${delta.deletes.length} delete(s)',
    );

    var applied = 0;
    var failed = 0;
    await db.transaction(() async {
      for (final record in delta.upserts) {
        try {
          if (await merge(record)) applied++;
        } on Object catch (e) {
          failed++;
          DiagnosticsLog.warn('Sync', 'skipped malformed $label ${record.id}: $e');
        }
      }
      if (applyDelete != null) {
        for (final tombstone in delta.deletes) {
          try {
            if (await applyDelete(tombstone)) applied++;
          } on Object catch (e) {
            failed++;
            DiagnosticsLog.warn(
                'Sync', 'skipped tombstone $label ${tombstone.id}: $e');
          }
        }
      }
    });

    final cursor = delta.cursor;
    if (cursor != null) {
      await prefs.setInt(cursorKey, cursor.millisecondsSinceEpoch);
    }
    return (applied: applied, failed: failed);
  }

  /// Force-pull every entity from the canonical backend into local Drift — the
  /// inbound mirror of the outbound backfill ([SyncBackfillService]). Where the
  /// live dual-read is gated per-entity (the staged cutover kill-switches, off by
  /// default), a hydrate is a *deliberate* seed: it merges every table regardless
  /// of those switches, under the same LWW/append rules and cursors. Its reason
  /// to exist is the fresh device — a just-signed-in web client whose local Drift
  /// starts empty must be able to see the user's library without first flipping
  /// cutover flags. Idempotent (a re-run is LWW-safe; same-second local rows are
  /// skipped, never clobbered) and a no-op when no backend is wired.
  ///
  /// Returns a per-entity `(label, applied, failed)` report (also the dev-panel /
  /// M.3-parity evidence). Never partial-fails the whole run: one entity's error
  /// is caught and surfaced as a `failed` count so the rest still hydrate.
  Future<List<({String label, int applied, int failed})>>
      hydrateAllFromBackend() async {
    final backend = syncBackend;
    if (backend == null) {
      DiagnosticsLog.warn('Sync', 'hydrate skipped — no backend wired');
      return const [];
    }
    final hydrate = StageLogger.begin('hydrateAllFromBackend', subsystem: 'Sync');

    final reports = <({String label, int applied, int failed})>[];
    Future<void> run(
      final SyncEntityType type,
      final String cursorKey,
      final String label,
      final Future<bool> Function(SyncRecord) merge, [
      final Future<bool> Function(SyncTombstone)? applyDelete,
    ]) async {
      try {
        final r = await _pullAndMergeEntity(
          backend: backend,
          type: type,
          cursorKey: cursorKey,
          label: label,
          merge: merge,
          applyDelete: applyDelete,
        );
        reports.add((label: label, applied: r.applied, failed: r.failed));
        hydrate.stage(label, {'applied': r.applied, 'failed': r.failed});
      } on Object catch (e) {
        DiagnosticsLog.error('Sync', 'hydrate $label FAILED: $e');
        reports.add((label: label, applied: 0, failed: -1));
      }
    }

    // Dependency order (parents before their join rows), matching the backfill.
    await run(SyncEntityType.move, movesBackendCursorPrefKey, 'move',
        _mergeMoveRecordLww, _applyMoveTombstone);
    await run(SyncEntityType.combo, combosBackendCursorPrefKey, 'combo',
        _mergeComboRecordLww, _applyComboTombstone);
    await run(SyncEntityType.comboMove, comboMovesBackendCursorPrefKey,
        'comboMove', _mergeComboMoveRecordLww, _applyComboMoveTombstone);
    await run(SyncEntityType.reviewEvent, reviewsBackendCursorPrefKey, 'review',
        _mergeReviewRecordAppend);
    await run(SyncEntityType.fsrsCard, fsrsCardsBackendCursorPrefKey, 'fsrsCard',
        _mergeFsrsCardRecordLww);
    await run(SyncEntityType.deck, decksBackendCursorPrefKey, 'deck',
        _mergeDeckRecordLww, _applyDeckTombstone);
    await run(SyncEntityType.deckMove, deckMovesBackendCursorPrefKey, 'deckMove',
        _mergeDeckMoveRecordLww, _applyDeckMoveTombstone);
    await run(SyncEntityType.moveNoteEntry, moveNoteEntriesBackendCursorPrefKey,
        'moveNoteEntry', _mergeMoveNoteEntryRecordLww,
        _applyMoveNoteEntryTombstone);
    await run(SyncEntityType.comboNoteEntry,
        comboNoteEntriesBackendCursorPrefKey, 'comboNoteEntry',
        _mergeComboNoteEntryRecordLww, _applyComboNoteEntryTombstone);

    final applied = reports.fold(0, (final a, final r) => a + r.applied);
    final failed = reports.where((final r) => r.failed != 0).length;
    hydrate.complete('$applied row(s) applied across ${reports.length} entities'
        '${failed == 0 ? '' : ', $failed entity/entities with failures'}');
    return reports;
  }

  // --- Production first-login provisioning (add-first-user-production-provisioning) ---

  /// Flip every per-entity dual-write kill-switch at once (production path).
  /// Writes each key via `SharedPreferences.setBool`; no other behavior.
  /// Skips `fsrsCards` (derived server-side, no write key). See spec
  /// `SyncService batch pref setters`.
  Future<void> setDualWriteAll({required final bool enabled}) async {
    await prefs.setBool(movesDualWritePrefKey, enabled);
    await prefs.setBool(combosDualWritePrefKey, enabled);
    await prefs.setBool(reviewsDualWritePrefKey, enabled);
    await prefs.setBool(decksDualWritePrefKey, enabled);
    await prefs.setBool(noteEntriesDualWritePrefKey, enabled);
  }

  /// Flip every per-entity dual-read kill-switch at once (production path).
  /// Writes each key via `SharedPreferences.setBool`; no other behavior.
  /// Includes `fsrsCards` (read-only entity). See spec
  /// `SyncService batch pref setters`.
  Future<void> setDualReadAll({required final bool enabled}) async {
    await prefs.setBool(movesDualReadPrefKey, enabled);
    await prefs.setBool(combosDualReadPrefKey, enabled);
    await prefs.setBool(reviewsDualReadPrefKey, enabled);
    await prefs.setBool(fsrsCardsDualReadPrefKey, enabled);
    await prefs.setBool(decksDualReadPrefKey, enabled);
    await prefs.setBool(noteEntriesDualReadPrefKey, enabled);
  }

  /// All-or-nothing production activation: compose the eight `backfill*()`
  /// calls via the injected [SyncBackfillService]; on full success flip every
  /// dual-write then dual-read pref ON; on any throw change NO prefs and let
  /// the exception propagate. Returns the list of `BackfillReport`. No-op
  /// (returns `const []`) when no backfill service is wired.
  Future<List<BackfillReport>> activateSync() async {
    final backfill = syncBackfillService;
    if (backfill == null) return const [];

    final reports = <BackfillReport>[];
    reports.add(await backfill.backfillMoves());
    reports.add(await backfill.backfillCombos());
    reports.add(await backfill.backfillComboMoves());
    reports.add(await backfill.backfillReviews());
    reports.add(await backfill.backfillDecks());
    reports.add(await backfill.backfillDeckMoves());
    reports.add(await backfill.backfillMoveNoteEntries());
    reports.add(await backfill.backfillComboNoteEntries());

    await setDualWriteAll(enabled: true);
    await setDualReadAll(enabled: true);
    return reports;
  }

  // --- Inbound tombstone application (task 4.8) ---
  //
  // A delete on device A crosses as a [SyncTombstone]; device B applies it as a
  // reversible soft-hide (set `deletedAt`), never a hard-delete, so a delete
  // elsewhere never destroys videos/rows (brownfield: never orphan user state).
  // Each apply writes straight to Drift — bypassing the sync-aware DAO — so a
  // remote-origin hide is never re-enqueued as a local change, and touches only
  // `deletedAt` so the LWW clock is preserved. All are no-ops (return false) on
  // an absent, already-hidden (idempotent replay), or LWW-losing row.

  /// True when a tombstone dated [remoteDeletedAt] should hide a local row whose
  /// LWW clock is [localClock]. Mirrors the upsert LWW (H.2/A3): whole-second
  /// granularity, delete wins only when *strictly newer*, so a same-second or
  /// later local re-edit keeps the row visible — never destroy on a tie, the
  /// data-safety default. A null local clock is epoch-old, so the delete wins.
  bool _tombstoneWins(
    final DateTime? localClock,
    final DateTime remoteDeletedAt,
  ) {
    final localSec = (localClock?.millisecondsSinceEpoch ?? 0) ~/ 1000;
    final remoteSec = remoteDeletedAt.millisecondsSinceEpoch ~/ 1000;
    return remoteSec > localSec;
  }

  Future<bool> _applyMoveTombstone(final SyncTombstone t) async {
    final existing = await (db.select(db.moves)
          ..where((final r) => r.id.equals(t.id)))
        .getSingleOrNull();
    if (existing == null || existing.deletedAt != null) return false;
    if (!_tombstoneWins(existing.updatedAt ?? existing.createdAt, t.deletedAt)) {
      return false;
    }
    await (db.update(db.moves)..where((final r) => r.id.equals(t.id)))
        .write(MovesCompanion(deletedAt: Value(t.deletedAt)));
    return true;
  }

  Future<bool> _applyComboTombstone(final SyncTombstone t) async {
    final existing = await (db.select(db.combos)
          ..where((final r) => r.id.equals(t.id)))
        .getSingleOrNull();
    if (existing == null || existing.deletedAt != null) return false;
    if (!_tombstoneWins(existing.updatedAt ?? existing.createdAt, t.deletedAt)) {
      return false;
    }
    await (db.update(db.combos)..where((final r) => r.id.equals(t.id)))
        .write(CombosCompanion(deletedAt: Value(t.deletedAt)));
    return true;
  }

  Future<bool> _applyComboMoveTombstone(final SyncTombstone t) async {
    final existing = await (db.select(db.comboMoves)
          ..where((final r) => r.id.equals(t.id)))
        .getSingleOrNull();
    if (existing == null || existing.deletedAt != null) return false;
    if (!_tombstoneWins(existing.updatedAt, t.deletedAt)) return false;
    await (db.update(db.comboMoves)..where((final r) => r.id.equals(t.id)))
        .write(ComboMovesCompanion(deletedAt: Value(t.deletedAt)));
    return true;
  }

  Future<bool> _applyDeckTombstone(final SyncTombstone t) async {
    final existing = await (db.select(db.decks)
          ..where((final r) => r.id.equals(t.id)))
        .getSingleOrNull();
    if (existing == null || existing.deletedAt != null) return false;
    if (!_tombstoneWins(existing.updatedAt, t.deletedAt)) return false;
    await (db.update(db.decks)..where((final r) => r.id.equals(t.id)))
        .write(DecksCompanion(deletedAt: Value(t.deletedAt)));
    return true;
  }

  Future<bool> _applyDeckMoveTombstone(final SyncTombstone t) async {
    // Composite wire id 'deckId:moveId' (UUIDs are colon-free — unambiguous).
    final parts = t.id.split(':');
    if (parts.length != 2) return false;
    final deckId = parts[0];
    final moveId = parts[1];
    final existing = await (db.select(db.deckMoves)
          ..where(
              (final r) => r.deckId.equals(deckId) & r.moveId.equals(moveId)))
        .getSingleOrNull();
    if (existing == null || existing.deletedAt != null) return false;
    if (!_tombstoneWins(existing.updatedAt, t.deletedAt)) return false;
    await (db.update(db.deckMoves)
          ..where(
              (final r) => r.deckId.equals(deckId) & r.moveId.equals(moveId)))
        .write(DeckMovesCompanion(deletedAt: Value(t.deletedAt)));
    return true;
  }

  Future<bool> _applyMoveNoteEntryTombstone(final SyncTombstone t) async {
    final existing = await (db.select(db.moveNoteEntries)
          ..where((final r) => r.id.equals(t.id)))
        .getSingleOrNull();
    if (existing == null || existing.deletedAt != null) return false;
    if (!_tombstoneWins(existing.updatedAt ?? existing.createdAt, t.deletedAt)) {
      return false;
    }
    await (db.update(db.moveNoteEntries)..where((final r) => r.id.equals(t.id)))
        .write(MoveNoteEntriesCompanion(deletedAt: Value(t.deletedAt)));
    return true;
  }

  Future<bool> _applyComboNoteEntryTombstone(final SyncTombstone t) async {
    final existing = await (db.select(db.comboNoteEntries)
          ..where((final r) => r.id.equals(t.id)))
        .getSingleOrNull();
    if (existing == null || existing.deletedAt != null) return false;
    if (!_tombstoneWins(existing.updatedAt ?? existing.createdAt, t.deletedAt)) {
      return false;
    }
    await (db.update(db.comboNoteEntries)..where((final r) => r.id.equals(t.id)))
        .write(ComboNoteEntriesCompanion(deletedAt: Value(t.deletedAt)));
    return true;
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
        applyDelete: _applyDeckTombstone,
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
        applyDelete: _applyDeckMoveTombstone,
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

  // --- note-entry pair (task 4.9; Appwrite-only per D11) ---
  //
  // MoveNoteEntries/ComboNoteEntries never had a Firestore leg, so a flush's
  // note entries no-op through the Firestore push loop and are shadowed only via
  // these Appwrite dual-writes, driven by the same shared [_dualWriteEntity] /
  // [_pullEntity] engines as the decks pair. Both tables carry a synthetic id,
  // so the wire identity is that id (no composite key).

  /// Dual-write `moveNoteEntries` to the Appwrite shadow (task 4.9).
  Future<void> dualWriteMoveNoteEntries(final Iterable<SyncLogData> entries) =>
      _dualWriteEntity(
        type: SyncEntityType.moveNoteEntry,
        prefKey: noteEntriesDualWritePrefKey,
        label: 'moveNoteEntry',
        entries: entries,
        recordFor: (final id) async => moveNoteEntryToSyncRecord(
          (await db.moveNoteEntriesDao.getById(id))!,
        ),
      );

  /// Dual-write `comboNoteEntries` to the Appwrite shadow (task 4.9). Shares the
  /// pair's write kill-switch with [dualWriteMoveNoteEntries].
  Future<void> dualWriteComboNoteEntries(final Iterable<SyncLogData> entries) =>
      _dualWriteEntity(
        type: SyncEntityType.comboNoteEntry,
        prefKey: noteEntriesDualWritePrefKey,
        label: 'comboNoteEntry',
        entries: entries,
        recordFor: (final id) async => comboNoteEntryToSyncRecord(
          (await db.comboNoteEntriesDao.getById(id))!,
        ),
      );

  /// Dual-read `moveNoteEntries` (task 4.9). See [pullDecksFromBackend].
  Future<({int applied, int failed})?> pullMoveNoteEntriesFromBackend() =>
      _pullEntity(
        type: SyncEntityType.moveNoteEntry,
        prefKey: noteEntriesDualReadPrefKey,
        cursorKey: moveNoteEntriesBackendCursorPrefKey,
        label: 'moveNoteEntry',
        merge: _mergeMoveNoteEntryRecordLww,
        applyDelete: _applyMoveNoteEntryTombstone,
      );

  /// Dual-read `comboNoteEntries` (task 4.9). Shares the pair's read kill-switch
  /// but keeps its own cursor (distinct backend table).
  Future<({int applied, int failed})?> pullComboNoteEntriesFromBackend() =>
      _pullEntity(
        type: SyncEntityType.comboNoteEntry,
        prefKey: noteEntriesDualReadPrefKey,
        cursorKey: comboNoteEntriesBackendCursorPrefKey,
        label: 'comboNoteEntry',
        merge: _mergeComboNoteEntryRecordLww,
        applyDelete: _applyComboNoteEntryTombstone,
      );

  /// Merge one remote move note [record] under LWW at whole-second granularity
  /// (H.2/A3). A (post-v27-migration unreachable) null local clock falls back to
  /// `createdAt`, matching the codec's guard.
  Future<bool> _mergeMoveNoteEntryRecordLww(final SyncRecord record) async {
    final existing = await (db.select(db.moveNoteEntries)
          ..where((final t) => t.id.equals(record.id)))
        .getSingleOrNull();
    if (existing != null) {
      final localClock = existing.updatedAt ?? existing.createdAt;
      if (localClock.millisecondsSinceEpoch ~/ 1000 >=
          record.updatedAt.millisecondsSinceEpoch ~/ 1000) {
        return false;
      }
    }
    await db
        .into(db.moveNoteEntries)
        .insertOnConflictUpdate(moveNoteEntryFromSyncRecord(record));
    return true;
  }

  /// Merge one remote combo note [record] under LWW. See
  /// [_mergeMoveNoteEntryRecordLww].
  Future<bool> _mergeComboNoteEntryRecordLww(final SyncRecord record) async {
    final existing = await (db.select(db.comboNoteEntries)
          ..where((final t) => t.id.equals(record.id)))
        .getSingleOrNull();
    if (existing != null) {
      final localClock = existing.updatedAt ?? existing.createdAt;
      if (localClock.millisecondsSinceEpoch ~/ 1000 >=
          record.updatedAt.millisecondsSinceEpoch ~/ 1000) {
        return false;
      }
    }
    await db
        .into(db.comboNoteEntries)
        .insertOnConflictUpdate(comboNoteEntryFromSyncRecord(record));
    return true;
  }

  // --- Private Helpers ---

  String _learningStateFromFsrs(final int fsrsState) => switch (fsrsState) {
    2 => 'MASTERY',
    1 || 3 => 'LEARNING',
    _ => 'NEW',
  };
}
