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
  Future<List<SyncOperation>> getQueued({final int limit = 10}) =>
      (select(syncOperations)
            ..where((final t) => t.status.equals('queued'))
            ..orderBy([
              (final t) => OrderingTerm.desc(t.priority),
              (final t) => OrderingTerm.asc(t.createdAt),
            ])
            ..limit(limit))
          .get();

  /// Operations currently in progress.
  Future<List<SyncOperation>> getInProgress() =>
      (select(syncOperations)
            ..where((final t) => t.status.equals('in_progress')))
          .get();

  /// Failed operations eligible for retry.
  Future<List<SyncOperation>> getRetryable() =>
      (select(syncOperations)
            ..where((final t) =>
                t.status.equals('failed') &
                t.retryCount.isSmallerThan(t.maxRetries)))
          .get();

  /// Watch count of queued + in_progress operations (for sync status UI).
  Stream<int> watchPendingCount() {
    final count = syncOperations.id.count();
    final query = selectOnly(syncOperations)
      ..addColumns([count])
      ..where(syncOperations.status.isIn(['queued', 'in_progress']));
    return query.map((final row) => row.read(count) ?? 0).watchSingle();
  }

  /// Watch all active operations for progress display.
  Stream<List<SyncOperation>> watchActive() =>
      (select(syncOperations)
            ..where(
                (final t) => t.status.isIn(['queued', 'in_progress', 'uploading']))
            ..orderBy([
              (final t) => OrderingTerm.desc(t.priority),
              (final t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  /// Check if an operation already exists for this hash + provider + type.
  Future<bool> operationExists({
    required final String contentHash,
    required final String providerId,
    required final String operationType,
  }) async {
    final existing = await (select(syncOperations)
          ..where((final t) =>
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

  Future<void> insertOperation(final SyncOperationsCompanion entry) =>
      into(syncOperations).insert(entry, mode: InsertMode.insertOrIgnore);

  /// Transition an operation to in_progress.
  Future<void> markInProgress(final String id) =>
      (update(syncOperations)..where((final t) => t.id.equals(id))).write(
        SyncOperationsCompanion(
          status: const Value('in_progress'),
          startedAt: Value(DateTime.now()),
        ),
      );

  /// Mark an operation as completed.
  Future<void> markCompleted(final String id) =>
      (update(syncOperations)..where((final t) => t.id.equals(id))).write(
        SyncOperationsCompanion(
          status: const Value('completed'),
          completedAt: Value(DateTime.now()),
        ),
      );

  /// Mark an operation as failed, incrementing retry count.
  Future<void> markFailed(final String id, final String errorMessage) async {
    final op = await (select(syncOperations)
          ..where((final t) => t.id.equals(id)))
        .getSingle();
    await (update(syncOperations)..where((final t) => t.id.equals(id))).write(
      SyncOperationsCompanion(
        status: const Value('failed'),
        errorMessage: Value(errorMessage),
        retryCount: Value(op.retryCount + 1),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Re-queue a failed operation for retry.
  Future<void> requeueForRetry(final String id) =>
      (update(syncOperations)..where((final t) => t.id.equals(id))).write(
        const SyncOperationsCompanion(
          status: Value('queued'),
          errorMessage: Value(null),
        ),
      );

  /// Update transfer progress.
  Future<void> updateProgress(final String id, final int bytesTransferred) =>
      (update(syncOperations)..where((final t) => t.id.equals(id))).write(
        SyncOperationsCompanion(
          bytesTransferred: Value(bytesTransferred),
        ),
      );

  /// Clean up completed operations older than [before].
  Future<void> cleanupCompleted(final DateTime before) =>
      (delete(syncOperations)
            ..where((final t) =>
                t.status.equals('completed') &
                t.completedAt.isSmallerThanValue(before)))
          .go();

  /// Delete all operations for a content hash (used by tombstone cleaner).
  Future<void> deleteByHash(final String contentHash) =>
      (delete(syncOperations)
            ..where((final t) => t.contentHash.equals(contentHash)))
          .go();
}
