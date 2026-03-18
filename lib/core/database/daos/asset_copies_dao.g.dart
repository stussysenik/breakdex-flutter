// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_copies_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetCopiesDaoMixin on DatabaseAccessor<AppDatabase> {
  $AssetManifestTable get assetManifest => attachedDatabase.assetManifest;
  $AssetCopiesTable get assetCopies => attachedDatabase.assetCopies;
  AssetCopiesDaoManager get managers => AssetCopiesDaoManager(this);
}

class AssetCopiesDaoManager {
  final _$AssetCopiesDaoMixin _db;
  AssetCopiesDaoManager(this._db);
  $$AssetManifestTableTableManager get assetManifest =>
      $$AssetManifestTableTableManager(_db.attachedDatabase, _db.assetManifest);
  $$AssetCopiesTableTableManager get assetCopies =>
      $$AssetCopiesTableTableManager(_db.attachedDatabase, _db.assetCopies);
}
