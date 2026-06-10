// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combos_dao.dart';

// ignore_for_file: type=lint
mixin _$CombosDaoMixin on DatabaseAccessor<AppDatabase> {
  $CombosTable get combos => attachedDatabase.combos;
  $MovesTable get moves => attachedDatabase.moves;
  $ComboMovesTable get comboMoves => attachedDatabase.comboMoves;
  $ComboNoteEntriesTable get comboNoteEntries =>
      attachedDatabase.comboNoteEntries;
  $ComboPlansTable get comboPlans => attachedDatabase.comboPlans;
  CombosDaoManager get managers => CombosDaoManager(this);
}

class CombosDaoManager {
  final _$CombosDaoMixin _db;
  CombosDaoManager(this._db);
  $$CombosTableTableManager get combos =>
      $$CombosTableTableManager(_db.attachedDatabase, _db.combos);
  $$MovesTableTableManager get moves =>
      $$MovesTableTableManager(_db.attachedDatabase, _db.moves);
  $$ComboMovesTableTableManager get comboMoves =>
      $$ComboMovesTableTableManager(_db.attachedDatabase, _db.comboMoves);
  $$ComboNoteEntriesTableTableManager get comboNoteEntries =>
      $$ComboNoteEntriesTableTableManager(
        _db.attachedDatabase,
        _db.comboNoteEntries,
      );
  $$ComboPlansTableTableManager get comboPlans =>
      $$ComboPlansTableTableManager(_db.attachedDatabase, _db.comboPlans);
}
