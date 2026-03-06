// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fsrs_cards_dao.dart';

// ignore_for_file: type=lint
mixin _$FsrsCardsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FsrsCardsTable get fsrsCards => attachedDatabase.fsrsCards;
  $MovesTable get moves => attachedDatabase.moves;
  $CombosTable get combos => attachedDatabase.combos;
  FsrsCardsDaoManager get managers => FsrsCardsDaoManager(this);
}

class FsrsCardsDaoManager {
  final _$FsrsCardsDaoMixin _db;
  FsrsCardsDaoManager(this._db);
  $$FsrsCardsTableTableManager get fsrsCards =>
      $$FsrsCardsTableTableManager(_db.attachedDatabase, _db.fsrsCards);
  $$MovesTableTableManager get moves =>
      $$MovesTableTableManager(_db.attachedDatabase, _db.moves);
  $$CombosTableTableManager get combos =>
      $$CombosTableTableManager(_db.attachedDatabase, _db.combos);
}
