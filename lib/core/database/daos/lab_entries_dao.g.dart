// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lab_entries_dao.dart';

// ignore_for_file: type=lint
mixin _$LabEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LabsTable get labs => attachedDatabase.labs;
  $LabEntriesTable get labEntries => attachedDatabase.labEntries;
  LabEntriesDaoManager get managers => LabEntriesDaoManager(this);
}

class LabEntriesDaoManager {
  final _$LabEntriesDaoMixin _db;
  LabEntriesDaoManager(this._db);
  $$LabsTableTableManager get labs =>
      $$LabsTableTableManager(_db.attachedDatabase, _db.labs);
  $$LabEntriesTableTableManager get labEntries =>
      $$LabEntriesTableTableManager(_db.attachedDatabase, _db.labEntries);
}
