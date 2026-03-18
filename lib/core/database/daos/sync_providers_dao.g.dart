// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncProvidersDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncProvidersTable get syncProviders => attachedDatabase.syncProviders;
  SyncProvidersDaoManager get managers => SyncProvidersDaoManager(this);
}

class SyncProvidersDaoManager {
  final _$SyncProvidersDaoMixin _db;
  SyncProvidersDaoManager(this._db);
  $$SyncProvidersTableTableManager get syncProviders =>
      $$SyncProvidersTableTableManager(_db.attachedDatabase, _db.syncProviders);
}
