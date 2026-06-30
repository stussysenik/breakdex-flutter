import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/move_note_entries.dart';

part 'move_note_entries_dao.g.dart';

@DriftAccessor(tables: [MoveNoteEntries])
class MoveNoteEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$MoveNoteEntriesDaoMixin {
  MoveNoteEntriesDao(super.db);

  Future<List<MoveNoteEntry>> getByMoveId(final String moveId) {
    return (select(moveNoteEntries)
          ..where((final t) => t.moveId.equals(moveId))
          ..orderBy([(final t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Live stream of a move's log entries — re-emits on every add/edit/delete
  /// so the detail screen updates instantly (no leave-and-return refresh).
  Stream<List<MoveNoteEntry>> watchByMoveId(final String moveId) {
    return (select(moveNoteEntries)
          ..where((final t) => t.moveId.equals(moveId))
          ..orderBy([
            (final t) => OrderingTerm.desc(t.createdAt),
            (final t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Future<void> addEntry({
    required final String id,
    required final String moveId,
    required final String body,
  }) {
    return into(moveNoteEntries).insert(
      MoveNoteEntriesCompanion.insert(
        id: id,
        moveId: moveId,
        body: body,
      ),
    );
  }

  Future<void> updateEntry(final String id, final String body) {
    return (update(moveNoteEntries)..where((final t) => t.id.equals(id))).write(
      MoveNoteEntriesCompanion(body: Value(body)),
    );
  }

  Future<void> deleteEntry(final String id) {
    return (delete(moveNoteEntries)..where((final t) => t.id.equals(id))).go();
  }
}
