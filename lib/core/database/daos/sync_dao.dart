import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/sync_log.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncLog])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  Future<void> logChange({
    required final String entityId,
    required final String table,
    required final String action,
    final bool hasVideo = false,
  }) async {
    final existing =
        await (select(syncLog)..where(
              (final t) =>
                  t.entityId.equals(entityId) &
                  t.entityTable.equals(table) &
                  t.action.equals(action),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await into(syncLog).insert(
        SyncLogCompanion.insert(
          entityId: entityId,
          entityTable: table,
          action: action,
          synced: const Value(false),
          videoSynced: Value(hasVideo ? false : true),
        ),
      );
      return;
    }

    await (update(syncLog)..where(
          (final t) =>
              t.entityId.equals(entityId) &
              t.entityTable.equals(table) &
              t.action.equals(action),
        ))
        .write(
          SyncLogCompanion(
            changedAt: Value(DateTime.now()),
            synced: const Value(false),
            videoSynced: hasVideo ? const Value(false) : const Value.absent(),
          ),
        );
  }

  Future<List<SyncLogData>> getPendingChanges() {
    return (select(syncLog)
          ..where((final t) => t.synced.equals(false))
          ..orderBy([(final t) => OrderingTerm.asc(t.changedAt)]))
        .get();
  }

  Stream<int> watchPendingCount() {
    final count = syncLog.entityId.count();
    final query = selectOnly(syncLog)
      ..addColumns([count])
      ..where(syncLog.synced.equals(false));
    return query.map((final row) => row.read(count) ?? 0).watchSingle();
  }

  Future<void> markSynced(final String entityId, final String table, final String action) {
    return (update(syncLog)..where(
          (final t) =>
              t.entityId.equals(entityId) &
              t.entityTable.equals(table) &
              t.action.equals(action),
        ))
        .write(const SyncLogCompanion(synced: Value(true)));
  }

  Future<List<SyncLogData>> getPendingVideoUploads() {
    return (select(syncLog)
          ..where((final t) => t.videoSynced.equals(false) & t.synced.equals(true))
          ..orderBy([(final t) => OrderingTerm.asc(t.changedAt)]))
        .get();
  }

  Future<void> markVideoSynced(final String entityId, final String table) {
    return (update(syncLog)..where(
          (final t) => t.entityId.equals(entityId) & t.entityTable.equals(table),
        ))
        .write(const SyncLogCompanion(videoSynced: Value(true)));
  }

  Future<void> clearAll() => delete(syncLog).go();
}
