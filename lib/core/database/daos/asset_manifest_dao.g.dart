// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_manifest_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetManifestDaoMixin on DatabaseAccessor<AppDatabase> {
  $AssetManifestTable get assetManifest => attachedDatabase.assetManifest;
  $AssetCopiesTable get assetCopies => attachedDatabase.assetCopies;
  $SyncOperationsTable get syncOperations => attachedDatabase.syncOperations;
  AssetManifestDaoManager get managers => AssetManifestDaoManager(this);
}

class AssetManifestDaoManager {
  final _$AssetManifestDaoMixin _db;
  AssetManifestDaoManager(this._db);
  $$AssetManifestTableTableManager get assetManifest =>
      $$AssetManifestTableTableManager(_db.attachedDatabase, _db.assetManifest);
  $$AssetCopiesTableTableManager get assetCopies =>
      $$AssetCopiesTableTableManager(_db.attachedDatabase, _db.assetCopies);
  $$SyncOperationsTableTableManager get syncOperations =>
      $$SyncOperationsTableTableManager(
        _db.attachedDatabase,
        _db.syncOperations,
      );
}
