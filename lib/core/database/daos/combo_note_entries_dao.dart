import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/combo_note_entries.dart';

part 'combo_note_entries_dao.g.dart';

@DriftAccessor(tables: [ComboNoteEntries])
class ComboNoteEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$ComboNoteEntriesDaoMixin {
  ComboNoteEntriesDao(super.db);

  Future<List<ComboNoteEntry>> getByComboId(final String comboId) {
    return (select(comboNoteEntries)
          ..where((final t) => t.comboId.equals(comboId))
          ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> addEntry({
    required final String id,
    required final String comboId,
    required final String body,
  }) {
    return into(comboNoteEntries).insert(
      ComboNoteEntriesCompanion.insert(
        id: id,
        comboId: comboId,
        body: body,
      ),
    );
  }

  Future<void> updateEntry(final String id, final String body) {
    return (update(comboNoteEntries)..where((final t) => t.id.equals(id))).write(
      ComboNoteEntriesCompanion(body: Value(body)),
    );
  }

  Future<void> deleteEntry(final String id) {
    return (delete(comboNoteEntries)..where((final t) => t.id.equals(id))).go();
  }
}
