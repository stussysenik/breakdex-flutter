import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/combo_note_entries.dart';
import 'sync_dao.dart';

part 'combo_note_entries_dao.g.dart';

@DriftAccessor(tables: [ComboNoteEntries])
class ComboNoteEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$ComboNoteEntriesDaoMixin {
  ComboNoteEntriesDao(super.db);

  /// Dirty-tracking sink (task 4.9). See [MoveNoteEntriesDao] — note entries
  /// bypass the `SyncAware*` layer, so the sync-log hook lives here (D11:
  /// Appwrite-only). Remote-origin merges write straight to Drift, never here.
  SyncDao get _sync => attachedDatabase.syncDao;

  /// Stamp the LWW clock on write unless the caller already set one.
  ComboNoteEntriesCompanion _stamp(final ComboNoteEntriesCompanion entry) =>
      entry.updatedAt.present
          ? entry
          : entry.copyWith(updatedAt: Value(DateTime.now().toUtc()));

  Future<List<ComboNoteEntry>> getByComboId(final String comboId) {
    return (select(comboNoteEntries)
          ..where((final t) => t.comboId.equals(comboId) & t.deletedAt.isNull())
          ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Stream<List<ComboNoteEntry>> watchByComboId(final String comboId) {
    return (select(comboNoteEntries)
          ..where((final t) => t.comboId.equals(comboId) & t.deletedAt.isNull())
          ..orderBy([
            (final t) => OrderingTerm.desc(t.createdAt),
            (final t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  /// Most recent journal entries carrying a video reference, across all
  /// combos — the "RECENT TAKES" section of the library video picker.
  /// Excludes rows hidden by an inbound sync tombstone (task 4.9).
  Stream<List<ComboNoteEntry>> watchRecentTakeRefs({final int limit = 10}) {
    return (select(comboNoteEntries)
          ..where(
              (final t) => t.videoPath.isNotNull() & t.deletedAt.isNull())
          ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  /// Every live note entry — read-only, for the non-destructive backfill.
  Future<List<ComboNoteEntry>> getAll() =>
      (select(comboNoteEntries)..where((final t) => t.deletedAt.isNull())).get();

  Future<ComboNoteEntry?> getById(final String id) =>
      (select(comboNoteEntries)..where((final t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> addEntry({
    required final String id,
    required final String comboId,
    required final String body,
    final String kind = 'jot',
    final String? videoPath,
    final String? videoHash,
  }) async {
    await into(comboNoteEntries).insert(
      _stamp(ComboNoteEntriesCompanion.insert(
        id: id,
        comboId: comboId,
        body: body,
        kind: Value(kind),
        videoPath: Value(videoPath),
        videoHash: Value(videoHash),
      )),
    );
    await _sync.logChange(
        entityId: id, table: 'combo_note_entries', action: 'create');
  }

  Future<void> updateEntry(final String id, final String body) async {
    await (update(comboNoteEntries)..where((final t) => t.id.equals(id)))
        .write(_stamp(ComboNoteEntriesCompanion(body: Value(body))));
    await _sync.logChange(
        entityId: id, table: 'combo_note_entries', action: 'update');
  }

  Future<void> deleteEntry(final String id) async {
    // Hard-deletes locally + logs a tombstone (the 4.8 doctrine); a receiving
    // device soft-hides via `deletedAt`. See [MoveNoteEntriesDao.deleteEntry].
    await (delete(comboNoteEntries)..where((final t) => t.id.equals(id))).go();
    await _sync.logChange(
        entityId: id, table: 'combo_note_entries', action: 'delete');
  }
}
