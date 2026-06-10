// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combo_plans_dao.dart';

// ignore_for_file: type=lint
mixin _$ComboPlansDaoMixin on DatabaseAccessor<AppDatabase> {
  $CombosTable get combos => attachedDatabase.combos;
  $ComboPlansTable get comboPlans => attachedDatabase.comboPlans;
  $ComboNoteEntriesTable get comboNoteEntries =>
      attachedDatabase.comboNoteEntries;
  ComboPlansDaoManager get managers => ComboPlansDaoManager(this);
}

class ComboPlansDaoManager {
  final _$ComboPlansDaoMixin _db;
  ComboPlansDaoManager(this._db);
  $$CombosTableTableManager get combos =>
      $$CombosTableTableManager(_db.attachedDatabase, _db.combos);
  $$ComboPlansTableTableManager get comboPlans =>
      $$ComboPlansTableTableManager(_db.attachedDatabase, _db.comboPlans);
  $$ComboNoteEntriesTableTableManager get comboNoteEntries =>
      $$ComboNoteEntriesTableTableManager(
        _db.attachedDatabase,
        _db.comboNoteEntries,
      );
}
