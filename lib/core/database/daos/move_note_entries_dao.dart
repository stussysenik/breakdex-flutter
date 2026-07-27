import 'package:drift/drift.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/tables/move_note_entries.dart';
import 'package:breakdex/core/database/daos/sync_dao.dart';

part 'move_note_entries_dao.g.dart';

@DriftAccessor(tables: [MoveNoteEntries])
class MoveNoteEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$MoveNoteEntriesDaoMixin {
  MoveNoteEntriesDao(super.db);

  /// Dirty-tracking sink (task 4.9). Note entries bypass the `SyncAware*`
  /// repository layer, so the sync-log hook lives here — every user-initiated
  /// mutation logs to `sync_log` so the Appwrite dual-write can shadow it (D11:
  /// Appwrite-only, no Firestore leg). Remote-origin merges write straight to
  /// Drift (not via this DAO), so a pulled row is never re-enqueued.
  SyncDao get _sync => attachedDatabase.syncDao;

  /// Stamp the LWW clock on write unless the caller already set one.
  MoveNoteEntriesCompanion _stamp(final MoveNoteEntriesCompanion entry) =>
      entry.updatedAt.present
          ? entry
          : entry.copyWith(updatedAt: Value(DateTime.now().toUtc()));

  Future<List<MoveNoteEntry>> getByMoveId(final String moveId) {
    return (select(moveNoteEntries)
          ..where((final t) => t.moveId.equals(moveId) & t.deletedAt.isNull())
          ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Live stream of a move's log entries — re-emits on every add/edit/delete
  /// so the detail screen updates instantly (no leave-and-return refresh).
  /// Excludes rows hidden by an inbound sync tombstone (task 4.9).
  Stream<List<MoveNoteEntry>> watchByMoveId(final String moveId) {
    return (select(moveNoteEntries)
          ..where((final t) => t.moveId.equals(moveId) & t.deletedAt.isNull())
          ..orderBy([
            (final t) => OrderingTerm.desc(t.createdAt),
            (final t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  /// Every live note entry — read-only, for the non-destructive backfill.
  Future<List<MoveNoteEntry>> getAll() =>
      (select(moveNoteEntries)..where((final t) => t.deletedAt.isNull())).get();

  Future<MoveNoteEntry?> getById(final String id) =>
      (select(moveNoteEntries)..where((final t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> addEntry({
    required final String id,
    required final String moveId,
    required final String body,
  }) async {
    await into(moveNoteEntries).insert(
      _stamp(MoveNoteEntriesCompanion.insert(
        id: id,
        moveId: moveId,
        body: body,
      )),
    );
    await _sync.logChange(
        entityId: id, table: 'move_note_entries', action: 'create');
  }

  Future<void> updateEntry(final String id, final String body) async {
    await (update(moveNoteEntries)..where((final t) => t.id.equals(id)))
        .write(_stamp(MoveNoteEntriesCompanion(body: Value(body))));
    await _sync.logChange(
        entityId: id, table: 'move_note_entries', action: 'update');
  }

  Future<void> deleteEntry(final String id) async {
    // Hard-deletes locally + logs a tombstone (the 4.8 doctrine): the originating
    // device removes the row, the tombstone crosses, and a *receiving* device
    // soft-hides via `deletedAt` — never destroying state it might still want.
    await (delete(moveNoteEntries)..where((final t) => t.id.equals(id))).go();
    await _sync.logChange(
        entityId: id, table: 'move_note_entries', action: 'delete');
  }
}
