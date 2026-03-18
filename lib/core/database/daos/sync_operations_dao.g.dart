// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_operations_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncOperationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncOperationsTable get syncOperations => attachedDatabase.syncOperations;
  SyncOperationsDaoManager get managers => SyncOperationsDaoManager(this);
}

class SyncOperationsDaoManager {
  final _$SyncOperationsDaoMixin _db;
  SyncOperationsDaoManager(this._db);
  $$SyncOperationsTableTableManager get syncOperations =>
      $$SyncOperationsTableTableManager(
        _db.attachedDatabase,
        _db.syncOperations,
      );
}
