import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/labs.dart';
import '../tables/lab_moves.dart';
import '../tables/lab_entries.dart';
import '../tables/milestones.dart';
import '../tables/moves.dart';

part 'labs_dao.g.dart';

/// Data class for a lab-move JOIN: the junction row paired with its full Move.
class LabMoveWithDetail {
  final LabMove labMove;
  final Move move;

  LabMoveWithDetail({required this.labMove, required this.move});
}

@DriftAccessor(tables: [Labs, LabMoves, LabEntries, Milestones, Moves])
class LabsDao extends DatabaseAccessor<AppDatabase> with _$LabsDaoMixin {
  LabsDao(super.db);

  /// Watch all labs ordered by most recently updated first.
  Stream<List<Lab>> watchAll() =>
      (select(labs)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  /// Watch labs filtered by type ('project' or 'set'), ordered by updatedAt.
  Stream<List<Lab>> watchByType(String labType) => (select(labs)
        ..where((t) => t.labType.equals(labType))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  /// Get all labs ordered by most recently updated first.
  Future<List<Lab>> getAll() =>
      (select(labs)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

  /// Get a single lab by ID, or null if not found.
  Future<Lab?> getById(String id) =>
      (select(labs)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Insert a new lab.
  Future<void> insertLab(LabsCompanion entry) => into(labs).insert(entry);

  /// Update an existing lab.
  Future<void> updateLab(LabsCompanion entry) =>
      (update(labs)..where((t) => t.id.equals(entry.id.value))).write(entry);

  /// Delete a lab by ID. LabMoves, LabEntries, and Milestones cascade-delete
  /// automatically via FK.
  Future<void> deleteLab(String id) =>
      (delete(labs)..where((t) => t.id.equals(id))).go();

  // -- LabMoves (moves within a lab) ------------------------------------------

  /// Watch moves in a lab joined with their full Move details, ordered by
  /// sequenceIndex ascending.
  Stream<List<LabMoveWithDetail>> watchLabMoves(String labId) {
    final query = select(labMoves).join([
      innerJoin(moves, moves.id.equalsExp(labMoves.moveId)),
    ])
      ..where(labMoves.labId.equals(labId))
      ..orderBy([OrderingTerm.asc(labMoves.sequenceIndex)]);

    return query.watch().map((rows) => rows
        .map((row) => LabMoveWithDetail(
              labMove: row.readTable(labMoves),
              move: row.readTable(moves),
            ))
        .toList());
  }

  /// Add a move to a lab at a given sequence index.
  Future<void> addMoveToLab(
          String labId, String moveId, int sequenceIndex) =>
      into(labMoves).insert(
        LabMovesCompanion.insert(
          labId: labId,
          moveId: moveId,
          sequenceIndex: sequenceIndex,
        ),
      );

  /// Remove a move from a lab.
  Future<void> removeMoveFromLab(String labId, String moveId) =>
      (delete(labMoves)
            ..where(
                (t) => t.labId.equals(labId) & t.moveId.equals(moveId)))
          .go();

  /// Reorder moves within a lab by writing new sequenceIndex values.
  ///
  /// [moveIds] is the desired order — each move gets its list index as the
  /// new sequenceIndex.
  Future<void> reorderLabMoves(String labId, List<String> moveIds) async {
    await transaction(() async {
      for (var i = 0; i < moveIds.length; i++) {
        await (update(labMoves)
              ..where((t) =>
                  t.labId.equals(labId) & t.moveId.equals(moveIds[i])))
            .write(LabMovesCompanion(sequenceIndex: Value(i)));
      }
    });
  }
}
