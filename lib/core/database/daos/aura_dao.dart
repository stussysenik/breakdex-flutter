import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/aura_links.dart';
import '../tables/aura_presets.dart';

part 'aura_dao.g.dart';

@DriftAccessor(tables: [AuraLinks, AuraPresets])
class AuraDao extends DatabaseAccessor<AppDatabase> with _$AuraDaoMixin {
  AuraDao(super.db);

  // -- AuraLinks (move-to-move transitions) -----------------------------------

  /// Watch all aura links — used by the Flow Graph to build the full graph.
  ///
  /// Returns every link in the DB as a reactive stream. The Flow Graph canvas
  /// watches this to construct edges between nodes. Drift coalesces rapid
  /// inserts/deletes into a single emission, so the graph doesn't thrash.
  Stream<List<AuraLink>> watchAll() => select(auraLinks).watch();

  /// Watch all transition links originating from a move.
  Stream<List<AuraLink>> watchLinksFrom(String moveId) => (select(auraLinks)
        ..where((t) => t.fromMoveId.equals(moveId))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();

  /// Watch all transition links arriving at a move.
  Stream<List<AuraLink>> watchLinksTo(String moveId) => (select(auraLinks)
        ..where((t) => t.toMoveId.equals(moveId))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();

  /// Insert or update a link between two moves. On conflict (same PK pair)
  /// the affinity and notes are updated in place.
  Future<void> upsertLink(
    String fromMoveId,
    String toMoveId,
    String affinity, {
    String? notes,
  }) =>
      into(auraLinks).insertOnConflictUpdate(
        AuraLinksCompanion.insert(
          fromMoveId: fromMoveId,
          toMoveId: toMoveId,
          affinity: affinity,
          notes: Value(notes),
        ),
      );

  /// Delete a link between two moves.
  Future<void> deleteLink(String fromMoveId, String toMoveId) =>
      (delete(auraLinks)
            ..where((t) =>
                t.fromMoveId.equals(fromMoveId) &
                t.toMoveId.equals(toMoveId)))
          .go();

  // -- AuraPresets ------------------------------------------------------------

  /// Watch all aura presets as a reactive stream.
  Stream<List<AuraPreset>> watchPresets() => select(auraPresets).watch();

  /// Get the currently active preset (isDefault = 1), or null if none.
  Future<AuraPreset?> getActivePreset() => (select(auraPresets)
        ..where((t) => t.isDefault.equals(1)))
      .getSingleOrNull();

  /// Insert a new aura preset.
  Future<void> insertPreset(AuraPresetsCompanion entry) =>
      into(auraPresets).insert(entry);

  /// Set a preset as the active one. Clears isDefault on all others first,
  /// then sets isDefault = 1 on the target — done in a transaction for
  /// atomicity.
  Future<void> setActivePreset(String id) async {
    await transaction(() async {
      // Clear all presets
      await update(auraPresets)
          .write(const AuraPresetsCompanion(isDefault: Value(0)));
      // Activate the selected preset
      await (update(auraPresets)..where((t) => t.id.equals(id)))
          .write(const AuraPresetsCompanion(isDefault: Value(1)));
    });
  }
}
