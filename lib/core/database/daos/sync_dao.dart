import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/sync_log.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncLog])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  Future<void> logChange({
    required String entityId,
    required String table,
    required String action,
    bool hasVideo = false,
  }) async {
    await into(syncLog).insertOnConflictUpdate(
      SyncLogCompanion.insert(
        entityId: entityId,
        entityTable: table,
        action: action,
        synced: const Value(false),
        videoSynced: Value(hasVideo ? false : true),
      ),
    );
  }

  Future<List<SyncLogData>> getPendingChanges() {
    return (select(syncLog)
          ..where((t) => t.synced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.changedAt)]))
        .get();
  }

  Stream<int> watchPendingCount() {
    final count = syncLog.entityId.count();
    final query = selectOnly(syncLog)
      ..addColumns([count])
      ..where(syncLog.synced.equals(false));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<void> markSynced(String entityId, String table, String action) {
    return (update(syncLog)
          ..where((t) =>
              t.entityId.equals(entityId) &
              t.entityTable.equals(table) &
              t.action.equals(action)))
        .write(const SyncLogCompanion(synced: Value(true)));
  }

  Future<List<SyncLogData>> getPendingVideoUploads() {
    return (select(syncLog)
          ..where(
              (t) => t.videoSynced.equals(false) & t.synced.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.changedAt)]))
        .get();
  }

  Future<void> markVideoSynced(String entityId, String table) {
    return (update(syncLog)
          ..where(
              (t) => t.entityId.equals(entityId) & t.entityTable.equals(table)))
        .write(const SyncLogCompanion(videoSynced: Value(true)));
  }

  Future<void> clearAll() => delete(syncLog).go();
}
