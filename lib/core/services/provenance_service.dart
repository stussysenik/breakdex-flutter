import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/provenance_events_dao.dart';

/// Service for recording data provenance events.
///
/// Each method wraps [ProvenanceEventsDao.insert] with pre-formatted
/// metadata. Timestamps are set automatically by the DAO table default.
class ProvenanceService {
  final ProvenanceEventsDao _dao;

  ProvenanceService(this._dao);

  String _makeId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return bytes.map((final b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> logCreated(
    final String entityType,
    final String entityId, {
    final Map<String, dynamic>? metadata,
  }) {
    return _dao.insert(
      ProvenanceEventsCompanion.insert(
        id: _makeId(),
        entityType: entityType,
        entityId: entityId,
        eventType: 'created',
        metadata: metadata != null ? Value(jsonEncode(metadata)) : const Value.absent(),
      ),
    );
  }

  Future<void> logReviewed(
    final String entityType,
    final String entityId,
    final String rating, {
    final String? fsrsState,
  }) {
    final meta = <String, dynamic>{
      'rating': rating,
    };
    if (fsrsState != null) {
      meta['fsrs_state'] = fsrsState;
    }

    return _dao.insert(
      ProvenanceEventsCompanion.insert(
        id: _makeId(),
        entityType: entityType,
        entityId: entityId,
        eventType: 'reviewed',
        metadata: Value(jsonEncode(meta)),
      ),
    );
  }

  Future<void> logEdited(
    final String entityType,
    final String entityId,
    final Map<String, dynamic> changes,
  ) {
    return _dao.insert(
      ProvenanceEventsCompanion.insert(
        id: _makeId(),
        entityType: entityType,
        entityId: entityId,
        eventType: 'edited',
        metadata: Value(jsonEncode({'changes': changes})),
      ),
    );
  }

  Future<void> logMilestone(
    final String entityType,
    final String entityId,
    final String milestone,
  ) {
    return _dao.insert(
      ProvenanceEventsCompanion.insert(
        id: _makeId(),
        entityType: entityType,
        entityId: entityId,
        eventType: 'milestone_reached',
        metadata: Value(jsonEncode({'milestone': milestone})),
      ),
    );
  }

  Future<void> logTagged(
    final String entityType,
    final String entityId,
    final String tag,
  ) {
    return _dao.insert(
      ProvenanceEventsCompanion.insert(
        id: _makeId(),
        entityType: entityType,
        entityId: entityId,
        eventType: 'tagged',
        metadata: Value(jsonEncode({'tag': tag})),
      ),
    );
  }

  Future<int> purgeExpiredEvents(final int retentionDays) {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    return _dao.purgeExpired(cutoff);
  }
}
