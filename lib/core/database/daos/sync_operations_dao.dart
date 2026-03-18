import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sync_operations.dart';

part 'sync_operations_dao.g.dart';

@DriftAccessor(tables: [SyncOperations])
class SyncOperationsDao extends DatabaseAccessor<AppDatabase>
    with _$SyncOperationsDaoMixin {
  SyncOperationsDao(super.db);

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Next operations to process, ordered by priority (desc) then creation time.
  Future<List<SyncOperation>> getQueued({int limit = 10}) =>
      (select(syncOperations)
            ..where((t) => t.status.equals('queued'))
            ..orderBy([
              (t) => OrderingTerm.desc(t.priority),
              (t) => OrderingTerm.asc(t.createdAt),
            ])
            ..limit(limit))
          .get();

  /// Operations currently in progress.
  Future<List<SyncOperation>> getInProgress() =>
      (select(syncOperations)
            ..where((t) => t.status.equals('in_progress')))
          .get();

  /// Failed operations eligible for retry.
  Future<List<SyncOperation>> getRetryable() =>
      (select(syncOperations)
            ..where((t) =>
                t.status.equals('failed') &
                t.retryCount.isSmallerThan(t.maxRetries)))
          .get();

  /// Watch count of queued + in_progress operations (for sync status UI).
  Stream<int> watchPendingCount() {
    final count = syncOperations.id.count();
    final query = selectOnly(syncOperations)
      ..addColumns([count])
      ..where(syncOperations.status.isIn(['queued', 'in_progress']));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Watch all active operations for progress display.
  Stream<List<SyncOperation>> watchActive() =>
      (select(syncOperations)
            ..where(
                (t) => t.status.isIn(['queued', 'in_progress', 'uploading']))
            ..orderBy([
              (t) => OrderingTerm.desc(t.priority),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  /// Check if an operation already exists for this hash + provider + type.
  Future<bool> operationExists({
    required String contentHash,
    required String providerId,
    required String operationType,
  }) async {
    final existing = await (select(syncOperations)
          ..where((t) =>
              t.contentHash.equals(contentHash) &
              t.providerId.equals(providerId) &
              t.operationType.equals(operationType) &
              t.status.isIn(['queued', 'in_progress'])))
        .get();
    return existing.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<void> insertOperation(SyncOperationsCompanion entry) =>
      into(syncOperations).insert(entry, mode: InsertMode.insertOrIgnore);

  /// Transition an operation to in_progress.
  Future<void> markInProgress(String id) =>
      (update(syncOperations)..where((t) => t.id.equals(id))).write(
        SyncOperationsCompanion(
          status: const Value('in_progress'),
          startedAt: Value(DateTime.now()),
        ),
      );

  /// Mark an operation as completed.
  Future<void> markCompleted(String id) =>
      (update(syncOperations)..where((t) => t.id.equals(id))).write(
        SyncOperationsCompanion(
          status: const Value('completed'),
          completedAt: Value(DateTime.now()),
        ),
      );

  /// Mark an operation as failed, incrementing retry count.
  Future<void> markFailed(String id, String errorMessage) async {
    final op = await (select(syncOperations)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    await (update(syncOperations)..where((t) => t.id.equals(id))).write(
      SyncOperationsCompanion(
        status: const Value('failed'),
        errorMessage: Value(errorMessage),
        retryCount: Value(op.retryCount + 1),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Re-queue a failed operation for retry.
  Future<void> requeueForRetry(String id) =>
      (update(syncOperations)..where((t) => t.id.equals(id))).write(
        const SyncOperationsCompanion(
          status: Value('queued'),
          errorMessage: Value(null),
        ),
      );

  /// Update transfer progress.
  Future<void> updateProgress(String id, int bytesTransferred) =>
      (update(syncOperations)..where((t) => t.id.equals(id))).write(
        SyncOperationsCompanion(
          bytesTransferred: Value(bytesTransferred),
        ),
      );

  /// Clean up completed operations older than [before].
  Future<void> cleanupCompleted(DateTime before) =>
      (delete(syncOperations)
            ..where((t) =>
                t.status.equals('completed') &
                t.completedAt.isSmallerThanValue(before)))
          .go();

  /// Delete all operations for a content hash (used by tombstone cleaner).
  Future<void> deleteByHash(String contentHash) =>
      (delete(syncOperations)
            ..where((t) => t.contentHash.equals(contentHash)))
          .go();
}
