// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aura_dao.dart';

// ignore_for_file: type=lint
mixin _$AuraDaoMixin on DatabaseAccessor<AppDatabase> {
  $MovesTable get moves => attachedDatabase.moves;
  $AuraLinksTable get auraLinks => attachedDatabase.auraLinks;
  $AuraPresetsTable get auraPresets => attachedDatabase.auraPresets;
  AuraDaoManager get managers => AuraDaoManager(this);
}

class AuraDaoManager {
  final _$AuraDaoMixin _db;
  AuraDaoManager(this._db);
  $$MovesTableTableManager get moves =>
      $$MovesTableTableManager(_db.attachedDatabase, _db.moves);
  $$AuraLinksTableTableManager get auraLinks =>
      $$AuraLinksTableTableManager(_db.attachedDatabase, _db.auraLinks);
  $$AuraPresetsTableTableManager get auraPresets =>
      $$AuraPresetsTableTableManager(_db.attachedDatabase, _db.auraPresets);
}
