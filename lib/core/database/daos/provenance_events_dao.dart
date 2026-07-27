import 'package:drift/drift.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/tables/provenance_events.dart';

part 'provenance_events_dao.g.dart';

@DriftAccessor(tables: [ProvenanceEvents])
class ProvenanceEventsDao extends DatabaseAccessor<AppDatabase>
    with _$ProvenanceEventsDaoMixin {
  ProvenanceEventsDao(super.db);

  Future<void> insert(final ProvenanceEventsCompanion entry) {
    return into(provenanceEvents).insert(entry);
  }

  Future<List<ProvenanceEvent>> getTimeline(
    final String entityType,
    final String entityId,
  ) {
    return (select(provenanceEvents)
      ..where((final t) =>
          t.entityType.equals(entityType) & t.entityId.equals(entityId))
      ..orderBy([(final t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<ProvenanceEvent>> getTimelineRange(
    final String entityType,
    final String entityId,
    final DateTime start,
    final DateTime end,
  ) {
    return (select(provenanceEvents)
      ..where((final t) =>
          t.entityType.equals(entityType) &
          t.entityId.equals(entityId) &
          t.timestamp.isBetweenValues(start, end))
      ..orderBy([(final t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<ProvenanceEvent>> getRecentActivity({final int limit = 20}) {
    return (select(provenanceEvents)
      ..orderBy([(final t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
      ..limit(limit))
        .get();
  }

  Future<List<ProvenanceEvent>> getEntityMilestones(
    final String entityType,
    final String entityId,
  ) {
    return (select(provenanceEvents)
      ..where((final t) =>
          t.entityType.equals(entityType) &
          t.entityId.equals(entityId) &
          t.eventType.equals('milestone_reached'))
      ..orderBy([(final t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }

  Future<int> purgeExpired(final DateTime olderThan) {
    return (delete(provenanceEvents)
          ..where((final t) => t.timestamp.isSmallerThanValue(olderThan)))
        .go();
  }
}
