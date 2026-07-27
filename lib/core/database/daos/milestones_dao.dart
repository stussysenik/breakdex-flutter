import 'package:drift/drift.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/tables/milestones.dart';

part 'milestones_dao.g.dart';

@DriftAccessor(tables: [Milestones])
class MilestonesDao extends DatabaseAccessor<AppDatabase>
    with _$MilestonesDaoMixin {
  MilestonesDao(super.db);

  /// Watch milestones for a lab, ordered by creation date ascending.
  Stream<List<Milestone>> watchByLab(final String labId) => (select(milestones)
        ..where((final t) => t.labId.equals(labId))
        ..orderBy([(final t) => OrderingTerm.asc(t.createdAt)]))
      .watch();

  /// Insert a new milestone.
  Future<void> insertMilestone(final MilestonesCompanion entry) =>
      into(milestones).insert(entry);

  /// Mark a milestone as completed (set completedAt to now).
  Future<void> complete(final String id) =>
      (update(milestones)..where((final t) => t.id.equals(id)))
          .write(MilestonesCompanion(completedAt: Value(DateTime.now())));

  /// Un-complete a milestone (clear completedAt).
  Future<void> uncomplete(final String id) =>
      (update(milestones)..where((final t) => t.id.equals(id)))
          .write(const MilestonesCompanion(completedAt: Value(null)));

  /// Delete a milestone by ID.
  Future<void> deleteMilestone(final String id) =>
      (delete(milestones)..where((final t) => t.id.equals(id))).go();
}
