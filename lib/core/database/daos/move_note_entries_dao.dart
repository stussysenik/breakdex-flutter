import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/move_note_entries.dart';

part 'move_note_entries_dao.g.dart';

@DriftAccessor(tables: [MoveNoteEntries])
class MoveNoteEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$MoveNoteEntriesDaoMixin {
  MoveNoteEntriesDao(super.db);

  Future<List<MoveNoteEntry>> getByMoveId(String moveId) {
    return (select(moveNoteEntries)
          ..where((t) => t.moveId.equals(moveId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> addEntry({
    required String id,
    required String moveId,
    required String body,
  }) {
    return into(moveNoteEntries).insert(
      MoveNoteEntriesCompanion.insert(
        id: id,
        moveId: moveId,
        body: body,
      ),
    );
  }

  Future<void> updateEntry(String id, String body) {
    return (update(moveNoteEntries)..where((t) => t.id.equals(id))).write(
      MoveNoteEntriesCompanion(body: Value(body)),
    );
  }

  Future<void> deleteEntry(String id) {
    return (delete(moveNoteEntries)..where((t) => t.id.equals(id))).go();
  }
}
