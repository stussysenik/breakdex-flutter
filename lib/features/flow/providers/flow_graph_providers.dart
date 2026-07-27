import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/features/flow/providers/aura_providers.dart';

// ---------------------------------------------------------------------------
// Graph data model — nodes, edges, and the combined graph structure.
//
// These are plain Dart classes (not Drift entities) that the graph canvas
// consumes. The force-directed layout mutates x/y/vx/vy directly for
// performance — no immutable copies during 60fps simulation ticks.
// ---------------------------------------------------------------------------

/// A single node in the Flow Graph, representing one move.
///
/// Each node carries enough metadata for the renderer to color-code by
/// category and mastery state without additional lookups.
///
/// The [x], [y], [vx], [vy] fields are mutable so the force simulation
/// can update positions in-place during each tick — copying hundreds of
/// nodes per frame would tank performance. This is the standard pattern
/// used by D3-force and similar graph layout engines.
class GraphNode {
  /// The move's unique ID (matches [Move.id] in the database).
  final String id;

  /// Display name shown on the node label.
  final String name;

  /// Breaking category (e.g. "toprock", "footwork", "power", "freeze").
  /// Used for color-coding and cluster grouping.
  final String category;

  /// FSRS mastery state for this move:
  /// - 0 = new (never reviewed — no FSRS card exists)
  /// - 1 = learning (fsrsState == 0 or 1 — New or Learning)
  /// - 2 = review/mastered (fsrsState == 2 — graduated to Review)
  ///
  /// Maps the 4-state FSRS model (New=0, Learning=1, Review=2, Relearning=3)
  /// into a simpler 3-tier visual scale for the graph. Relearning (3) maps
  /// to learning (1) since the user is re-acquiring the move.
  final int masteryState;

  /// Current X position in canvas coordinates. Mutated by force simulation.
  double x;

  /// Current Y position in canvas coordinates. Mutated by force simulation.
  double y;

  /// X velocity for the force simulation (pixels/tick).
  double vx;

  /// Y velocity for the force simulation (pixels/tick).
  double vy;

  GraphNode({
    required this.id,
    required this.name,
    required this.category,
    required this.masteryState,
    this.x = 0,
    this.y = 0,
    this.vx = 0,
    this.vy = 0,
  });
}

/// A directed edge in the Flow Graph, representing an aura link between
/// two moves.
///
/// Edges encode transition affinity — how naturally one move flows into
/// another. The renderer draws edges differently per affinity:
/// - natural: solid line, full opacity
/// - possible: dashed line, medium opacity
/// - stretch: dotted line, low opacity
class GraphEdge {
  /// Source node ID (matches [AuraLink.fromMoveId]).
  final String fromId;

  /// Target node ID (matches [AuraLink.toMoveId]).
  final String toId;

  /// Transition affinity rating: 'natural', 'possible', or 'stretch'.
  /// Determines edge styling and force strength — natural links pull
  /// nodes closer together than stretch links.
  final String affinity;

  const GraphEdge({
    required this.fromId,
    required this.toId,
    required this.affinity,
  });
}

/// The complete graph structure consumed by the Flow Graph canvas.
///
/// Holds parallel lists of nodes and edges. The force simulation reads
/// and mutates this structure in-place each tick, then the CustomPainter
/// reads the current positions to render.
///
/// This is intentionally a mutable container — graph layout is inherently
/// stateful (positions evolve over time via physics simulation). Treating
/// it as immutable would require copying hundreds of nodes per frame.
class FlowGraphData {
  /// All nodes (moves) in the graph.
  final List<GraphNode> nodes;

  /// All edges (aura links) in the graph.
  final List<GraphEdge> edges;

  const FlowGraphData({required this.nodes, required this.edges});

  /// Empty graph — used as the initial/loading state.
  static const empty = FlowGraphData(nodes: [], edges: []);
}

/// Aggregated graph metrics for the Flow header and analytics summary.
class FlowGraphSummary {
  const FlowGraphSummary({
    required this.nodeCount,
    required this.edgeCount,
    required this.categoryCount,
    required this.masteredCount,
    required this.learningCount,
    required this.newCount,
    required this.isolatedCount,
  });

  final int nodeCount;
  final int edgeCount;
  final int categoryCount;
  final int masteredCount;
  final int learningCount;
  final int newCount;
  final int isolatedCount;
}

/// Computed detail model for the currently selected node.
class SelectedFlowNodeDetails {
  const SelectedFlowNodeDetails({
    required this.node,
    required this.incomingCount,
    required this.outgoingCount,
    required this.neighborCount,
    required this.reciprocalCount,
    required this.sameCategoryCount,
    required this.naturalTransitionCount,
    required this.possibleTransitionCount,
    required this.stretchTransitionCount,
    required this.neighborNames,
  });

  final GraphNode node;
  final int incomingCount;
  final int outgoingCount;
  final int neighborCount;
  final int reciprocalCount;
  final int sameCategoryCount;
  final int naturalTransitionCount;
  final int possibleTransitionCount;
  final int stretchTransitionCount;
  final List<String> neighborNames;

  int get crossCategoryCount => neighborCount - sameCategoryCount;

  String get masteryLabel => switch (node.masteryState) {
    2 => 'Mastered',
    1 => 'Learning',
    _ => 'New',
  };
}

// ---------------------------------------------------------------------------
// View mode + filter enums — control what the graph canvas displays.
// ---------------------------------------------------------------------------

/// Controls the graph layout algorithm and visual presentation.
///
/// - [map]: Full force-directed graph showing all nodes and edges.
///   The "god view" — see how your entire arsenal connects.
/// - [focus]: Ego graph centered on the selected node. Shows only
///   direct neighbors (1-hop). Like inspecting one Pokemon's type chart.
/// - [clusters]: Category-grouped layout. Nodes cluster by category
///   with inter-category edges visible. Reveals which categories
///   bridge together vs. stay isolated.
enum FlowViewMode { map, focus, clusters }

/// Filters which entity types appear as nodes in the graph.
///
/// Currently the graph only supports moves (since aura links are
/// move-to-move), but this enum future-proofs for combos and sets.
enum FlowFilter { all, moves, combos, sets }

// ---------------------------------------------------------------------------
// Providers — reactive state that feeds the graph canvas.
// ---------------------------------------------------------------------------

/// The currently selected node ID, or null if nothing is selected.
///
/// Tapping a node in the graph sets this. The canvas highlights the
/// selected node and its edges. In Focus mode, this determines the
/// ego graph center. Setting to null clears the selection.
final selectedNodeProvider = StateProvider<String?>((final ref) => null);

/// The active view mode (Map / Focus / Clusters).
///
/// Persisted in widget state (not SharedPreferences) since it's a
/// transient UI preference, not a user setting worth persisting.
final flowViewModeProvider = StateProvider<FlowViewMode>(
  (final ref) => FlowViewMode.map,
);

/// The active entity filter (All / Moves / Combos / Sets).
///
/// Controls which node types are visible. When set to [FlowFilter.moves],
/// only move nodes appear. Combo/set support is a future extension.
final flowFilterProvider = StateProvider<FlowFilter>((final ref) => FlowFilter.all);

/// Reactive provider that combines moves, aura links, and FSRS cards
/// into a [FlowGraphData] structure ready for the graph canvas.
///
/// This is the main data pipeline for the Flow Graph:
///
/// ```
///   moveRepository.watchAll()  ──┐
///   auraDao.watchAll()         ──┼──▶ FlowGraphData { nodes, edges }
///   fsrsCardsDao.watchAll()    ──┘
/// ```
///
/// Each input is a reactive stream. When any source emits (move added,
/// link created, review processed), this provider recomputes and the
/// graph canvas rebuilds.
///
/// **Mastery state mapping:**
/// If a move has no FSRS card → masteryState = 0 (new).
/// If fsrsState is 0 (New) or 1 (Learning) or 3 (Relearning) → 1 (learning).
/// If fsrsState is 2 (Review) → 2 (mastered).
final flowGraphDataProvider = Provider<FlowGraphData>((final ref) {
  // --- Source 1: All moves (nodes) ---
  // moveRepositoryProvider returns a MoveRepository (sync provider), but
  // we need its reactive stream. _movesStreamProvider wraps watchAll()
  // as a StreamProvider so we can watch it here.
  final moves = ref.watch(_movesStreamProvider).valueOrNull ?? [];

  // --- Source 2: All aura links (edges) ---
  final links = ref.watch(_auraLinksStreamProvider).valueOrNull ?? [];

  // --- Source 3: FSRS cards (mastery state per move) ---
  // Build a lookup map: entityId → fsrsState for O(1) access per node.
  final fsrsCards = ref.watch(fsrsCardsRefreshProvider).valueOrNull ?? [];
  final masteryMap = <String, int>{};
  for (final card in fsrsCards) {
    if (card.entityType == 'move') {
      masteryMap[card.entityId] = card.fsrsState;
    }
  }

  // --- Combine into graph structure ---
  final nodes = moves.map((final move) {
    final fsrsState = masteryMap[move.id];
    final mastery = _fsrsStateToMastery(fsrsState);

    return GraphNode(
      id: move.id,
      name: move.name,
      category: move.category,
      masteryState: mastery,
    );
  }).toList();

  final edges = links.map((final link) {
    return GraphEdge(
      fromId: link.fromMoveId,
      toId: link.toMoveId,
      affinity: link.affinity,
    );
  }).toList();

  return FlowGraphData(nodes: nodes, edges: edges);
});

/// Aggregates top-level Flow metrics for the compact dashboard row.
final flowGraphSummaryProvider = Provider<FlowGraphSummary>((final ref) {
  final graphData = ref.watch(flowGraphDataProvider);

  var masteredCount = 0;
  var learningCount = 0;
  var newCount = 0;
  final categories = <String>{};
  final linkedNodeIds = <String>{};

  for (final node in graphData.nodes) {
    categories.add(node.category);
    switch (node.masteryState) {
      case 2:
        masteredCount++;
        break;
      case 1:
        learningCount++;
        break;
      default:
        newCount++;
    }
  }

  for (final edge in graphData.edges) {
    linkedNodeIds
      ..add(edge.fromId)
      ..add(edge.toId);
  }

  return FlowGraphSummary(
    nodeCount: graphData.nodes.length,
    edgeCount: graphData.edges.length,
    categoryCount: categories.length,
    masteredCount: masteredCount,
    learningCount: learningCount,
    newCount: newCount,
    isolatedCount: graphData.nodes
        .where((final node) => !linkedNodeIds.contains(node.id))
        .length,
  );
});

/// Provides the selected node plus its graph-local connection profile.
final selectedFlowNodeDetailsProvider = Provider<SelectedFlowNodeDetails?>((
  final ref,
) {
  final selectedId = ref.watch(selectedNodeProvider);
  if (selectedId == null) return null;

  final graphData = ref.watch(flowGraphDataProvider);
  final nodeById = {for (final node in graphData.nodes) node.id: node};
  final node = nodeById[selectedId];
  if (node == null) return null;

  final incomingIds = <String>{};
  final outgoingIds = <String>{};
  var naturalTransitionCount = 0;
  var possibleTransitionCount = 0;
  var stretchTransitionCount = 0;

  for (final edge in graphData.edges) {
    final touchesNode = edge.fromId == selectedId || edge.toId == selectedId;
    if (!touchesNode) continue;

    if (edge.fromId == selectedId) {
      outgoingIds.add(edge.toId);
    }
    if (edge.toId == selectedId) {
      incomingIds.add(edge.fromId);
    }

    switch (edge.affinity) {
      case 'natural':
        naturalTransitionCount++;
      case 'possible':
        possibleTransitionCount++;
      default:
        stretchTransitionCount++;
    }
  }

  final neighborIds = {...incomingIds, ...outgoingIds};
  final reciprocalCount = incomingIds.intersection(outgoingIds).length;
  final sameCategoryCount = neighborIds
      .where((final id) => nodeById[id]?.category == node.category)
      .length;
  final neighborNames =
      neighborIds.map((final id) => nodeById[id]?.name).whereType<String>().toList()
        ..sort((final a, final b) => a.compareTo(b));

  return SelectedFlowNodeDetails(
    node: node,
    incomingCount: incomingIds.length,
    outgoingCount: outgoingIds.length,
    neighborCount: neighborIds.length,
    reciprocalCount: reciprocalCount,
    sameCategoryCount: sameCategoryCount,
    naturalTransitionCount: naturalTransitionCount,
    possibleTransitionCount: possibleTransitionCount,
    stretchTransitionCount: stretchTransitionCount,
    neighborNames: neighborNames,
  );
});

/// Maps the 4-state FSRS model to a 3-tier visual mastery scale.
///
/// FSRS states: New(0), Learning(1), Review(2), Relearning(3)
/// Graph tiers: new(0), learning(1), strong(2)
///
/// Relearning maps to learning because the user forgot the move and
/// is re-acquiring it — visually it should look "in progress", not strong.
int _fsrsStateToMastery(final int? fsrsState) {
  if (fsrsState == null) return 0; // No FSRS card → new
  switch (fsrsState) {
    case 0: // FSRS New
    case 1: // FSRS Learning
    case 3: // FSRS Relearning
      return 1; // learning
    case 2: // FSRS Review (graduated)
      return 2; // strong
    default:
      return 0; // safety fallback
  }
}

// ---------------------------------------------------------------------------
// Internal stream providers — bridge between repository streams and
// the synchronous Provider that builds FlowGraphData.
//
// Riverpod's Provider.watch() can only watch other providers, not raw
// streams. These StreamProviders wrap the repository/DAO streams so
// flowGraphDataProvider can watch them reactively.
// ---------------------------------------------------------------------------

/// Internal: reactive stream of all moves from the repository.
final _movesStreamProvider = StreamProvider<List<Move>>((final ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});

/// Internal: reactive stream of all aura links from the DAO.
final _auraLinksStreamProvider = StreamProvider<List<AuraLink>>((final ref) {
  return ref.watch(auraDaoProvider).watchAll();
});
