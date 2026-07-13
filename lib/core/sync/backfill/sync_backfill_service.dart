import '../../database/daos/combos_dao.dart';
import '../../database/daos/decks_dao.dart';
import '../../database/daos/moves_dao.dart';
import '../../database/daos/reviews_dao.dart';
import '../codecs/combo_codec.dart';
import '../codecs/deck_codec.dart';
import '../codecs/move_codec.dart';
import '../codecs/review_codec.dart';
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
/// [SyncEntityType.move] (task 4.1), [SyncEntityType.combo] /
/// [SyncEntityType.comboMove] (task 4.4) — each an LWW entity whose
/// `*.updatedAt` clock exists — and the **append-only** [SyncEntityType.reviewEvent]
/// (task 4.5) are wired. The remaining descriptive entities gain a `backfillX()`
/// here as the strangler-fig advances. Each `backfillX()` requires its DAO, so a
/// caller supplies only the DAOs for the entities it backfills.
class SyncBackfillService {
  SyncBackfillService(
    this._backend,
    this._movesDao, {
    final CombosDao? combosDao,
    final ReviewsDao? reviewsDao,
    final DecksDao? decksDao,
    final int batchSize = 200,
  }) : assert(batchSize > 0, 'batchSize must be positive'),
       _combosDao = combosDao,
       _reviewsDao = reviewsDao,
       _decksDao = decksDao,
       _batchSize = batchSize;

  final SyncBackend _backend;
  final MovesDao _movesDao;
  final CombosDao? _combosDao;
  final ReviewsDao? _reviewsDao;
  final DecksDao? _decksDao;
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

  /// Read every local combo and upsert it into the backend shadow (task 4.4),
  /// with the same idempotent, non-destructive posture as [backfillMoves].
  Future<BackfillReport> backfillCombos() async {
    final dao = _combosDao;
    assert(dao != null, 'backfillCombos requires a CombosDao');
    final combos = await dao!.getAll();
    return _pushInBatches(
      SyncEntityType.combo,
      combos.map(comboToSyncRecord).toList(growable: false),
    );
  }

  /// Read every local combo step and upsert it into the backend shadow
  /// (task 4.4). Combo steps are structural rows keyed by their own id — a real
  /// delete crosses as a tombstone via the dual-write path, never here.
  Future<BackfillReport> backfillComboMoves() async {
    final dao = _combosDao;
    assert(dao != null, 'backfillComboMoves requires a CombosDao');
    final steps = await dao!.getAllComboMoves();
    return _pushInBatches(
      SyncEntityType.comboMove,
      steps.map(comboMoveToSyncRecord).toList(growable: false),
    );
  }

  /// Read every local review and upsert it into the backend shadow as an
  /// append-only `reviewEvent` (task 4.5). Same non-destructive, idempotent
  /// posture as [backfillMoves] — the review's own id is the `clientOpId`, so a
  /// replay is deduped server-side. A legacy row whose reviewed entity can no
  /// longer be identified encodes to `null` and is skipped (see `review_codec`).
  Future<BackfillReport> backfillReviews() async {
    final dao = _reviewsDao;
    assert(dao != null, 'backfillReviews requires a ReviewsDao');
    final reviews = await dao!.getAllOrdered();
    final records = reviews
        .map(reviewToSyncRecord)
        .whereType<SyncRecord>()
        .toList(growable: false);
    return _pushInBatches(SyncEntityType.reviewEvent, records);
  }

  /// Read every local deck and upsert it into the backend shadow (task 4.7),
  /// with the same idempotent, non-destructive posture as [backfillMoves].
  Future<BackfillReport> backfillDecks() async {
    final dao = _decksDao;
    assert(dao != null, 'backfillDecks requires a DecksDao');
    final decks = await dao!.getAll();
    return _pushInBatches(
      SyncEntityType.deck,
      decks.map(deckToSyncRecord).toList(growable: false),
    );
  }

  /// Read every local deck-move join and upsert it into the backend shadow
  /// (task 4.7). Structural rows keyed by the composite `(deckId, moveId)` — a
  /// real delete crosses as a tombstone via the dual-write path, never here.
  Future<BackfillReport> backfillDeckMoves() async {
    final dao = _decksDao;
    assert(dao != null, 'backfillDeckMoves requires a DecksDao');
    final joins = await dao!.getAllDeckMoves();
    return _pushInBatches(
      SyncEntityType.deckMove,
      joins.map(deckMoveToSyncRecord).toList(growable: false),
    );
  }

  /// Push [records] for [type] in [_batchSize] chunks; returns the report.
  Future<BackfillReport> _pushInBatches(
    final SyncEntityType type,
    final List<SyncRecord> records,
  ) async {
    var batches = 0;
    for (var i = 0; i < records.length; i += _batchSize) {
      final end = (i + _batchSize < records.length) ? i + _batchSize : records.length;
      await _backend.push(type, upserts: records.sublist(i, end));
      batches++;
    }
    return BackfillReport(
      entityType: type,
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
