// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decks_dao.dart';

// ignore_for_file: type=lint
mixin _$DecksDaoMixin on DatabaseAccessor<AppDatabase> {
  $DecksTable get decks => attachedDatabase.decks;
  $MovesTable get moves => attachedDatabase.moves;
  $DeckMovesTable get deckMoves => attachedDatabase.deckMoves;
  DecksDaoManager get managers => DecksDaoManager(this);
}

class DecksDaoManager {
  final _$DecksDaoMixin _db;
  DecksDaoManager(this._db);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db.attachedDatabase, _db.decks);
  $$MovesTableTableManager get moves =>
      $$MovesTableTableManager(_db.attachedDatabase, _db.moves);
  $$DeckMovesTableTableManager get deckMoves =>
      $$DeckMovesTableTableManager(_db.attachedDatabase, _db.deckMoves);
}
