import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/milestones.dart';

part 'milestones_dao.g.dart';

@DriftAccessor(tables: [Milestones])
class MilestonesDao extends DatabaseAccessor<AppDatabase>
    with _$MilestonesDaoMixin {
  MilestonesDao(super.db);

  /// Watch milestones for a lab, ordered by creation date ascending.
  Stream<List<Milestone>> watchByLab(String labId) => (select(milestones)
        ..where((t) => t.labId.equals(labId))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();

  /// Insert a new milestone.
  Future<void> insertMilestone(MilestonesCompanion entry) =>
      into(milestones).insert(entry);

  /// Mark a milestone as completed (set completedAt to now).
  Future<void> complete(String id) =>
      (update(milestones)..where((t) => t.id.equals(id)))
          .write(MilestonesCompanion(completedAt: Value(DateTime.now())));

  /// Un-complete a milestone (clear completedAt).
  Future<void> uncomplete(String id) =>
      (update(milestones)..where((t) => t.id.equals(id)))
          .write(const MilestonesCompanion(completedAt: Value(null)));

  /// Delete a milestone by ID.
  Future<void> deleteMilestone(String id) =>
      (delete(milestones)..where((t) => t.id.equals(id))).go();
}
