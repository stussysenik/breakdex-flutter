import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/combo_note_entries.dart';

part 'combo_note_entries_dao.g.dart';

@DriftAccessor(tables: [ComboNoteEntries])
class ComboNoteEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$ComboNoteEntriesDaoMixin {
  ComboNoteEntriesDao(super.db);

  Future<List<ComboNoteEntry>> getByComboId(String comboId) {
    return (select(comboNoteEntries)
          ..where((t) => t.comboId.equals(comboId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> addEntry({
    required String id,
    required String comboId,
    required String body,
  }) {
    return into(comboNoteEntries).insert(
      ComboNoteEntriesCompanion.insert(
        id: id,
        comboId: comboId,
        body: body,
      ),
    );
  }

  Future<void> updateEntry(String id, String body) {
    return (update(comboNoteEntries)..where((t) => t.id.equals(id))).write(
      ComboNoteEntriesCompanion(body: Value(body)),
    );
  }

  Future<void> deleteEntry(String id) {
    return (delete(comboNoteEntries)..where((t) => t.id.equals(id))).go();
  }
}
