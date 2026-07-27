import 'package:drift/drift.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/tables/lab_entries.dart';

part 'lab_entries_dao.g.dart';

@DriftAccessor(tables: [LabEntries])
class LabEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$LabEntriesDaoMixin {
  LabEntriesDao(super.db);

  /// Watch entries for a specific lab or all entries (when [labId] is null),
  /// ordered by creation date descending (newest first).
  Stream<List<LabEntry>> watchByLab(final String? labId) {
    final query = select(labEntries)
      ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]);
    if (labId != null) {
      query.where((final t) => t.labId.equals(labId));
    }
    return query.watch();
  }

  /// Watch the most recent entries across all labs, limited to [limit] rows.
  Stream<List<LabEntry>> watchRecent(final int limit) => (select(labEntries)
        ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)])
        ..limit(limit))
      .watch();

  /// Insert a new lab entry.
  Future<void> insertEntry(final LabEntriesCompanion entry) =>
      into(labEntries).insert(entry);

  /// Delete a lab entry by ID.
  Future<void> deleteEntry(final String id) =>
      (delete(labEntries)..where((final t) => t.id.equals(id))).go();
}
