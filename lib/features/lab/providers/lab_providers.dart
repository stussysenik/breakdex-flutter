import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/database/daos/labs_dao.dart';
import 'package:breakdex/core/database/daos/lab_entries_dao.dart';
import 'package:breakdex/core/database/daos/milestones_dao.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';

// -- DAO providers ------------------------------------------------------------

/// Provides the [LabsDao] instance from the shared database.
///
/// Follows the same pattern as [movesDaoProvider] in `providers.dart` —
/// access the DAO lazily via the already-opened [AppDatabase] singleton.
final labsDaoProvider = Provider<LabsDao>((final ref) {
  return ref.watch(databaseProvider).labsDao;
});

/// Provides the [LabEntriesDao] instance from the shared database.
final labEntriesDaoProvider = Provider<LabEntriesDao>((final ref) {
  return ref.watch(databaseProvider).labEntriesDao;
});

/// Provides the [MilestonesDao] instance from the shared database.
final milestonesDaoProvider = Provider<MilestonesDao>((final ref) {
  return ref.watch(databaseProvider).milestonesDao;
});

// -- Stream providers ---------------------------------------------------------

/// Reactive stream of all labs, ordered by most recently updated.
///
/// Widgets that `ref.watch(labsStreamProvider)` will automatically rebuild
/// whenever a lab is created, updated, or deleted — no manual invalidation
/// needed. This mirrors `_movesStreamProvider` in the Arsenal tab.
final labsStreamProvider = StreamProvider<List<Lab>>((final ref) {
  return ref.watch(labsDaoProvider).watchAll();
});

/// Reactive stream of the 20 most recent lab entries across all labs.
///
/// Useful for the quick-log feed at the top of the Lab tab — shows recent
/// activity without requiring the user to open a specific lab.
final labEntriesStreamProvider = StreamProvider<List<LabEntry>>((final ref) {
  return ref.watch(labEntriesDaoProvider).watchRecent(20);
});

// -- View mode ----------------------------------------------------------------

/// Controls which sub-view the Lab tab displays.
///
/// The 3 modes cover the Lab workspace:
/// - **projects**: filtered list of project-type labs (default)
/// - **board**: kanban-style columns by status (Idea → Clean)
/// - **sets**: filtered list of set-type labs (performance sequences)
///
/// Aura moved to the standalone Flow tab; Calendar moved into Progress.
enum LabViewMode { projects, board, sets }

final labViewModeProvider = StateProvider<LabViewMode>(
  (_) => LabViewMode.projects,
);

// -- Detail screen providers --------------------------------------------------

/// Reactive stream of a single lab by ID. Returns null when the lab doesn't
/// exist (deleted from another screen, for example).
final labDetailProvider =
    StreamProvider.family<Lab?, String>((final ref, final labId) async* {
  final dao = ref.watch(labsDaoProvider);
  // watchAll filtered client-side for simplicity — Drift will emit on any
  // labs table change and we pluck the matching row.
  yield* dao.watchAll().map((final labs) {
    try {
      return labs.firstWhere((final l) => l.id == labId);
    } on Object catch (_) {
      return null;
    }
  });
});

/// Reactive stream of moves linked to a lab, ordered by sequenceIndex.
final labMovesProvider =
    StreamProvider.family<List<LabMoveWithDetail>, String>((final ref, final labId) {
  return ref.watch(labsDaoProvider).watchLabMoves(labId);
});

/// Reactive stream of milestones for a lab, ordered by createdAt ascending.
final labMilestonesProvider =
    StreamProvider.family<List<Milestone>, String>((final ref, final labId) {
  return ref.watch(milestonesDaoProvider).watchByLab(labId);
});

/// Reactive stream of lab entries for a specific lab, ordered newest first.
final labEntriesByLabProvider =
    StreamProvider.family<List<LabEntry>, String>((final ref, final labId) {
  return ref.watch(labEntriesDaoProvider).watchByLab(labId);
});
