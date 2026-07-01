import '../../database/daos/moves_dao.dart';
import '../../database/database.dart';
import '../sync_backend.dart';

/// Non-destructive backfill of local Drift metadata into a [SyncBackend] shadow
/// (task 1.4 of `add-convex-sync-backend`).
///
/// **Safety posture.** This service is *read-only against Drift*: it calls only
/// query methods on the DAOs and never an insert/update/delete. It pushes every
/// local row to the backend as an upsert so the shadow becomes a faithful copy;
/// nothing here (and nothing the backend does) mutates or deletes a local row.
/// That invariant is what makes running against real data safe — proven by the
/// snapshot-equality tests in `sync_backfill_service_test.dart`.
///
/// Only [SyncEntityType.move] is wired today — it is the one entity whose
/// last-writer-wins clock (`moves.updatedAt`) exists. The remaining descriptive
/// entities gain their own `updatedAt` and a `backfillX()` here as the
/// strangler-fig advances (tasks 2.2–2.5).
class SyncBackfillService {
  SyncBackfillService(
    this._backend,
    this._movesDao, {
    final int batchSize = 200,
  }) : assert(batchSize > 0, 'batchSize must be positive'),
       _batchSize = batchSize;

  final SyncBackend _backend;
  final MovesDao _movesDao;
  final int _batchSize;

  /// Read every local move (including archived) and upsert it into the backend
  /// shadow in batches. Idempotent: re-running pushes the same deterministic
  /// [SyncRecord.clientOpId]s, and the backend reconciles last-writer-wins on
  /// [SyncRecord.updatedAt], so a replay is a no-op.
  Future<BackfillReport> backfillMoves() async {
    // Archived moves are soft-deleted locally (reversible via restoreMove), not
    // hard-deleted — so they cross as upserts carrying their archive metadata,
    // never as tombstones. A tombstone means a real delete, which backfill
    // never fabricates.
    final moves = await _movesDao.getAllIncludingArchived();
    final records = moves.map(moveToSyncRecord).toList(growable: false);

    var batches = 0;
    for (var i = 0; i < records.length; i += _batchSize) {
      final end = (i + _batchSize < records.length) ? i + _batchSize : records.length;
      await _backend.push(SyncEntityType.move, upserts: records.sublist(i, end));
      batches++;
    }

    return BackfillReport(
      entityType: SyncEntityType.move,
      recordCount: records.length,
      batchCount: batches,
    );
  }
}

/// Immutable summary of one backfill pass — enough to log and assert against.
class BackfillReport {
  const BackfillReport({
    required this.entityType,
    required this.recordCount,
    required this.batchCount,
  });

  final SyncEntityType entityType;
  final int recordCount;
  final int batchCount;
}

/// Project a [Move] onto its provider-neutral [SyncRecord].
///
/// The payload is JSON-safe by construction (the HTTP transport `jsonEncode`s
/// it): every field is a String / num / bool / null. In particular
/// [Move.videoFileSize] is a `BigInt` — not JSON-encodable and lossy past 2^53
/// as a JS number — so it is carried as a lossless decimal string, and every
/// [DateTime] is carried as ms-since-epoch. Video *bytes* never appear here;
/// `videoPath`/`contentHash` are pointers.
SyncRecord moveToSyncRecord(final Move m) => SyncRecord(
  id: m.id,
  type: SyncEntityType.move,
  json: moveToSyncJson(m),
  // Post-v23 every row has updatedAt; fall back to createdAt defensively so a
  // pre-migration row can never push a null clock.
  updatedAt: m.updatedAt ?? m.createdAt,
  clientOpId: 'backfill:move:${m.id}',
);

/// The JSON-safe descriptive payload for a move (see [moveToSyncRecord]).
Map<String, Object?> moveToSyncJson(final Move m) => {
  'name': m.name,
  'learningState': m.learningState,
  'category': m.category,
  'videoPath': m.videoPath,
  'originalVideoName': m.originalVideoName,
  'managedAlbumAssetId': m.managedAlbumAssetId,
  'managedAlbumFilename': m.managedAlbumFilename,
  'managedAlbumName': m.managedAlbumName,
  'notes': m.notes,
  'imagePaths': m.imagePaths,
  'contentHash': m.contentHash,
  'count': m.count,
  'videoFileSize': m.videoFileSize?.toString(),
  'archivedAt': m.archivedAt?.millisecondsSinceEpoch,
  'archiveReason': m.archiveReason,
  'videoCreationDate': m.videoCreationDate?.millisecondsSinceEpoch,
  'createdAt': m.createdAt.millisecondsSinceEpoch,
};
