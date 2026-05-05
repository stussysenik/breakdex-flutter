import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/provenance_events.dart';

part 'provenance_events_dao.g.dart';

@DriftAccessor(tables: [ProvenanceEvents])
class ProvenanceEventsDao extends DatabaseAccessor<AppDatabase>
    with _$ProvenanceEventsDaoMixin {
  ProvenanceEventsDao(super.db);

  Future<void> insert(ProvenanceEventsCompanion entry) {
    return into(provenanceEvents).insert(entry);
  }

  Future<List<ProvenanceEvent>> getTimeline(
    String entityType,
    String entityId,
  ) {
    return (select(provenanceEvents)
      ..where((t) =>
          t.entityType.equals(entityType) & t.entityId.equals(entityId))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<ProvenanceEvent>> getTimelineRange(
    String entityType,
    String entityId,
    DateTime start,
    DateTime end,
  ) {
    return (select(provenanceEvents)
      ..where((t) =>
          t.entityType.equals(entityType) &
          t.entityId.equals(entityId) &
          t.timestamp.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<ProvenanceEvent>> getRecentActivity({int limit = 20}) {
    return (select(provenanceEvents)
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
      ..limit(limit))
        .get();
  }

  Future<List<ProvenanceEvent>> getEntityMilestones(
    String entityType,
    String entityId,
  ) {
    return (select(provenanceEvents)
      ..where((t) =>
          t.entityType.equals(entityType) &
          t.entityId.equals(entityId) &
          t.eventType.equals('milestone_reached'))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }

  Future<int> purgeExpired(DateTime olderThan) {
    return (delete(provenanceEvents)
          ..where((t) => t.timestamp.isSmallerThanValue(olderThan)))
        .go();
  }
}
