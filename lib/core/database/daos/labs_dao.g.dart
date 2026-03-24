// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'labs_dao.dart';

// ignore_for_file: type=lint
mixin _$LabsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LabsTable get labs => attachedDatabase.labs;
  $MovesTable get moves => attachedDatabase.moves;
  $LabMovesTable get labMoves => attachedDatabase.labMoves;
  $LabEntriesTable get labEntries => attachedDatabase.labEntries;
  $MilestonesTable get milestones => attachedDatabase.milestones;
  LabsDaoManager get managers => LabsDaoManager(this);
}

class LabsDaoManager {
  final _$LabsDaoMixin _db;
  LabsDaoManager(this._db);
  $$LabsTableTableManager get labs =>
      $$LabsTableTableManager(_db.attachedDatabase, _db.labs);
  $$MovesTableTableManager get moves =>
      $$MovesTableTableManager(_db.attachedDatabase, _db.moves);
  $$LabMovesTableTableManager get labMoves =>
      $$LabMovesTableTableManager(_db.attachedDatabase, _db.labMoves);
  $$LabEntriesTableTableManager get labEntries =>
      $$LabEntriesTableTableManager(_db.attachedDatabase, _db.labEntries);
  $$MilestonesTableTableManager get milestones =>
      $$MilestonesTableTableManager(_db.attachedDatabase, _db.milestones);
}
