// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combo_note_entries_dao.dart';

// ignore_for_file: type=lint
mixin _$ComboNoteEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CombosTable get combos => attachedDatabase.combos;
  $ComboNoteEntriesTable get comboNoteEntries =>
      attachedDatabase.comboNoteEntries;
  ComboNoteEntriesDaoManager get managers => ComboNoteEntriesDaoManager(this);
}

class ComboNoteEntriesDaoManager {
  final _$ComboNoteEntriesDaoMixin _db;
  ComboNoteEntriesDaoManager(this._db);
  $$CombosTableTableManager get combos =>
      $$CombosTableTableManager(_db.attachedDatabase, _db.combos);
  $$ComboNoteEntriesTableTableManager get comboNoteEntries =>
      $$ComboNoteEntriesTableTableManager(
        _db.attachedDatabase,
        _db.comboNoteEntries,
      );
}
