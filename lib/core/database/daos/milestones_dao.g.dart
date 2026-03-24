// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestones_dao.dart';

// ignore_for_file: type=lint
mixin _$MilestonesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LabsTable get labs => attachedDatabase.labs;
  $MilestonesTable get milestones => attachedDatabase.milestones;
  MilestonesDaoManager get managers => MilestonesDaoManager(this);
}

class MilestonesDaoManager {
  final _$MilestonesDaoMixin _db;
  MilestonesDaoManager(this._db);
  $$LabsTableTableManager get labs =>
      $$LabsTableTableManager(_db.attachedDatabase, _db.labs);
  $$MilestonesTableTableManager get milestones =>
      $$MilestonesTableTableManager(_db.attachedDatabase, _db.milestones);
}
