// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moves_dao.dart';

// ignore_for_file: type=lint
mixin _$MovesDaoMixin on DatabaseAccessor<AppDatabase> {
  $MovesTable get moves => attachedDatabase.moves;
  MovesDaoManager get managers => MovesDaoManager(this);
}

class MovesDaoManager {
  final _$MovesDaoMixin _db;
  MovesDaoManager(this._db);
  $$MovesTableTableManager get moves =>
      $$MovesTableTableManager(_db.attachedDatabase, _db.moves);
}
