// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provenance_events_dao.dart';

// ignore_for_file: type=lint
mixin _$ProvenanceEventsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProvenanceEventsTable get provenanceEvents =>
      attachedDatabase.provenanceEvents;
  ProvenanceEventsDaoManager get managers => ProvenanceEventsDaoManager(this);
}

class ProvenanceEventsDaoManager {
  final _$ProvenanceEventsDaoMixin _db;
  ProvenanceEventsDaoManager(this._db);
  $$ProvenanceEventsTableTableManager get provenanceEvents =>
      $$ProvenanceEventsTableTableManager(
        _db.attachedDatabase,
        _db.provenanceEvents,
      );
}
