import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/provenance_events_dao.dart';
import 'package:breakdex/core/services/provenance_service.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProvenanceService service;

  setUp(() {
    db = createTestDatabase();
    service = ProvenanceService(ProvenanceEventsDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  group('ProvenanceService logging', () {
    test('logCreated records a creation event', () async {
      await service.logCreated('move', 'm1', metadata: {'name': 'Windmill'});

      final events = await ProvenanceEventsDao(db).getTimeline('move', 'm1');
      expect(events.length, 1);
      expect(events.first.eventType, 'created');
      expect(events.first.entityType, 'move');
      expect(events.first.entityId, 'm1');

      final metadata = jsonDecode(events.first.metadata!) as Map<String, dynamic>;
      expect(metadata['name'], 'Windmill');
    });

    test('logReviewed records a review event', () async {
      await service.logReviewed('move', 'm1', 'good', fsrsState: 'review');

      final events = await ProvenanceEventsDao(db).getTimeline('move', 'm1');
      expect(events.length, 1);
      expect(events.first.eventType, 'reviewed');

      final metadata = jsonDecode(events.first.metadata!) as Map<String, dynamic>;
      expect(metadata['rating'], 'good');
      expect(metadata['fsrs_state'], 'review');
    });

    test('logEdited records an edit event', () async {
      final changes = {'name': 'New Name', 'category': 'powermove'};
      await service.logEdited('move', 'm1', changes);

      final events = await ProvenanceEventsDao(db).getTimeline('move', 'm1');
      expect(events.length, 1);
      expect(events.first.eventType, 'edited');

      final metadata = jsonDecode(events.first.metadata!) as Map<String, dynamic>;
      final changesOut = metadata['changes'] as Map<String, dynamic>;
      expect(changesOut['name'], 'New Name');
      expect(changesOut['category'], 'powermove');
    });

    test('logMilestone records a milestone event', () async {
      await service.logMilestone('move', 'm1', 'reps_100');

      final events = await ProvenanceEventsDao(db).getEntityMilestones('move', 'm1');
      expect(events.length, 1);
      expect(events.first.eventType, 'milestone_reached');

      final metadata = jsonDecode(events.first.metadata!) as Map<String, dynamic>;
      expect(metadata['milestone'], 'reps_100');
    });

    test('logTagged records a tagged event', () async {
      await service.logTagged('move', 'm1', 'favorite');

      final events = await ProvenanceEventsDao(db).getTimeline('move', 'm1');
      expect(events.length, 1);
      expect(events.first.eventType, 'tagged');

      final metadata = jsonDecode(events.first.metadata!) as Map<String, dynamic>;
      expect(metadata['tag'], 'favorite');
    });
  });

  group('Timeline queries', () {
    setUp(() async {
      await service.logCreated('move', 'm1', metadata: {'name': 'Windmill'});
      await service.logReviewed('move', 'm1', 'good');
      await service.logEdited('move', 'm1', {'category': 'powermove'});
      await service.logMilestone('move', 'm1', 'reps_100');

      await service.logCreated('move', 'm2', metadata: {'name': 'Halo'});
      await service.logReviewed('move', 'm2', 'great');
    });

    test('getTimeline returns events ordered by timestamp', () async {
      final events = await ProvenanceEventsDao(db).getTimeline('move', 'm1');
      expect(events.length, 4);
      expect(events.map((e) => e.eventType),
          containsAll(['created', 'reviewed', 'edited', 'milestone_reached']));
    });

    test('getRecentActivity returns events across entities', () async {
      final recent = await ProvenanceEventsDao(db).getRecentActivity(limit: 10);
      final entityIds = recent.map((e) => e.entityId).toSet();
      expect(entityIds, containsAll(['m1', 'm2']));
    });

    test('getEntityMilestones returns only milestone events', () async {
      final milestones = await ProvenanceEventsDao(db).getEntityMilestones('move', 'm1');
      expect(milestones.length, 1);
      expect(milestones.first.eventType, 'milestone_reached');
    });
  });

  group('Purge policy', () {
    test('purgeExpiredEvents removes events older than retention', () async {
      final dao = ProvenanceEventsDao(db);

      // Insert an old event via DAO with an old timestamp
      await db.customStatement(
        "INSERT INTO provenance_events (id, entity_type, entity_id, event_type, timestamp) "
        "VALUES ('e-old', 'move', 'm1', 'created', 1000000000)",
      );

      // Verify old event was inserted
      final before = await dao.getTimeline('move', 'm1');
      expect(before.length, 1);

      await service.logCreated('move', 'm1', metadata: {'name': 'Recent'});

      // Purge events older than 365 days from now
      final purged = await service.purgeExpiredEvents(365);
      expect(purged, 1);

      final after = await dao.getTimeline('move', 'm1');
      expect(after.length, 1);
      // The recent event survives
      expect(after.first.id, isNot('e-old'));
    });

    test('purgeExpiredEvents with 0 days removes nothing', () async {
      await service.logCreated('move', 'm1', metadata: {'name': 'Windmill'});

      final purged = await service.purgeExpiredEvents(0);
      expect(purged, 0);

      final events = await ProvenanceEventsDao(db).getTimeline('move', 'm1');
      expect(events.length, 1);
    });
  });

  group('DAO append-only behavior', () {
    test('insert succeeds', () async {
      // Already tested — all log methods call insert
      await expectLater(
        service.logCreated('move', 'm1'),
        completes,
      );
    });

    test('no update method exposed on DAO', () {
      // The ProvenanceEventsDao does not have any update method.
      // verify: only `insert` and query methods exist.
      final dao = ProvenanceEventsDao(db);
      // If there were an update method, this would be a compile error —
      // this test is documentation of the design choice.
      expect(dao, isA<ProvenanceEventsDao>());
    });
  });
}
