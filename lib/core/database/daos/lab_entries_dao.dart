import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/lab_entries.dart';

part 'lab_entries_dao.g.dart';

@DriftAccessor(tables: [LabEntries])
class LabEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$LabEntriesDaoMixin {
  LabEntriesDao(super.db);

  /// Watch entries for a specific lab or all entries (when [labId] is null),
  /// ordered by creation date descending (newest first).
  Stream<List<LabEntry>> watchByLab(String? labId) {
    final query = select(labEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (labId != null) {
      query.where((t) => t.labId.equals(labId));
    }
    return query.watch();
  }

  /// Watch the most recent entries across all labs, limited to [limit] rows.
  Stream<List<LabEntry>> watchRecent(int limit) => (select(labEntries)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(limit))
      .watch();

  /// Insert a new lab entry.
  Future<void> insertEntry(LabEntriesCompanion entry) =>
      into(labEntries).insert(entry);

  /// Delete a lab entry by ID.
  Future<void> deleteEntry(String id) =>
      (delete(labEntries)..where((t) => t.id.equals(id))).go();
}
