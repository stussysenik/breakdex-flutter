// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'move_note_entries_dao.dart';

// ignore_for_file: type=lint
mixin _$MoveNoteEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $MovesTable get moves => attachedDatabase.moves;
  $MoveNoteEntriesTable get moveNoteEntries => attachedDatabase.moveNoteEntries;
  MoveNoteEntriesDaoManager get managers => MoveNoteEntriesDaoManager(this);
}

class MoveNoteEntriesDaoManager {
  final _$MoveNoteEntriesDaoMixin _db;
  MoveNoteEntriesDaoManager(this._db);
  $$MovesTableTableManager get moves =>
      $$MovesTableTableManager(_db.attachedDatabase, _db.moves);
  $$MoveNoteEntriesTableTableManager get moveNoteEntries =>
      $$MoveNoteEntriesTableTableManager(
        _db.attachedDatabase,
        _db.moveNoteEntries,
      );
}
