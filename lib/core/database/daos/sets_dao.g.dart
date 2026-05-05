// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sets_dao.dart';

// ignore_for_file: type=lint
mixin _$SetsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SetsTable get sets => attachedDatabase.sets;
  $SetItemsTable get setItems => attachedDatabase.setItems;
  SetsDaoManager get managers => SetsDaoManager(this);
}

class SetsDaoManager {
  final _$SetsDaoMixin _db;
  SetsDaoManager(this._db);
  $$SetsTableTableManager get sets =>
      $$SetsTableTableManager(_db.attachedDatabase, _db.sets);
  $$SetItemsTableTableManager get setItems =>
      $$SetItemsTableTableManager(_db.attachedDatabase, _db.setItems);
}
