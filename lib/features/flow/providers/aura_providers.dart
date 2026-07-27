import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/database/daos/aura_dao.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';

// ---------------------------------------------------------------------------
// DAO provider — follows movesDaoProvider / labsDaoProvider pattern.
// ---------------------------------------------------------------------------

/// Provides the [AuraDao] singleton from the shared [AppDatabase].
///
/// All aura-related providers derive from this — one DAO, many reactive views.
final auraDaoProvider = Provider<AuraDao>((final ref) {
  return ref.watch(databaseProvider).auraDao;
});

// ---------------------------------------------------------------------------
// Link stream providers — reactive views into the move-transition graph.
// ---------------------------------------------------------------------------

/// Watches all outgoing aura links from a given move.
///
/// Example: if the user has rated "Toprock -> 6-Step" and "Toprock -> CC",
/// watching `auraLinksFromProvider('toprock-id')` emits both links.
/// Rebuilds automatically when links are added, updated, or deleted.
final auraLinksFromProvider =
    StreamProvider.family<List<AuraLink>, String>((final ref, final moveId) {
  return ref.watch(auraDaoProvider).watchLinksFrom(moveId);
});

/// Watches all incoming aura links arriving at a given move.
///
/// The inverse of [auraLinksFromProvider] — answers "which moves flow INTO
/// this one?" Useful for showing bidirectional transition data.
final auraLinksToProvider =
    StreamProvider.family<List<AuraLink>, String>((final ref, final moveId) {
  return ref.watch(auraDaoProvider).watchLinksTo(moveId);
});

// ---------------------------------------------------------------------------
// Preset providers — manage style configurations ("Power Style", etc.)
// ---------------------------------------------------------------------------

/// Reactive stream of all aura presets. Rebuilds on create/rename/delete.
///
/// Presets are like Pokemon teams — different link configurations for
/// different styles (power, footwork, freeze combos, etc.).
final auraPresetsProvider = StreamProvider<List<AuraPreset>>((final ref) {
  return ref.watch(auraDaoProvider).watchPresets();
});

/// The currently active aura preset (isDefault = 1), or null if none exists.
///
/// Used by the header chip and the preset picker to highlight the active
/// configuration. When the user switches presets, this re-evaluates.
final activeAuraProvider = FutureProvider<AuraPreset?>((final ref) {
  // Re-evaluate whenever presets change (activation, rename, delete).
  ref.watch(auraPresetsProvider);
  return ref.watch(auraDaoProvider).getActivePreset();
});

// ---------------------------------------------------------------------------
// Derived providers — higher-level queries built on top of raw links.
// ---------------------------------------------------------------------------

/// Returns the list of moves rated "natural" from the given move.
///
/// This is the key provider for Set Builder integration: when the user adds
/// a move to their set, the builder queries this to suggest what flows best
/// next — like a Pokemon type chart suggesting super-effective matchups.
///
/// Returns full [Move] objects (not just IDs) so the UI can display names
/// and categories without additional lookups.
final naturalNextMovesProvider =
    FutureProvider.family<List<Move>, String>((final ref, final moveId) async {
  // Watch the links stream so this auto-refreshes when ratings change.
  final linksAsync = ref.watch(auraLinksFromProvider(moveId));
  final links = linksAsync.valueOrNull ?? [];

  // Filter to only "natural" affinity links.
  final naturalIds = links
      .where((final link) => link.affinity == 'natural')
      .map((final link) => link.toMoveId)
      .toList();

  if (naturalIds.isEmpty) return [];

  // Batch-fetch the full Move objects for display.
  final movesDao = ref.watch(databaseProvider).movesDao;
  final allMoves = await movesDao.getAll();

  final idSet = naturalIds.toSet();
  return allMoves.where((final m) => idSet.contains(m.id)).toList();
});

/// Looks up the affinity between two specific moves (if any link exists).
///
/// Returns 'natural', 'possible', 'stretch', or null (unrated).
/// Used by [AuraTransitionIndicator] to show the colored dot between
/// two moves in a set sequence.
final auraAffinityProvider =
    FutureProvider.family<String?, ({String fromId, String toId})>(
        (final ref, final pair) async {
  final linksAsync = ref.watch(auraLinksFromProvider(pair.fromId));
  final links = linksAsync.valueOrNull ?? [];

  for (final link in links) {
    if (link.toMoveId == pair.toId) return link.affinity;
  }
  return null;
});
