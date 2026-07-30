// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/services/categories_service.dart';
import 'package:breakdex/features/lab/providers/lab_providers.dart';
import 'package:breakdex/features/flow/providers/flow_graph_providers.dart';
import 'package:breakdex/features/flow/widgets/flow_graph_legend.dart';

// ---------------------------------------------------------------------------
// Force-directed layout engine.
// ---------------------------------------------------------------------------

/// Runs a Barnes-Hut–inspired force simulation on a set of nodes and edges.
///
/// Forces applied each iteration:
/// 1. **Repulsion** (Coulomb's law): every pair of nodes repels each other
///    with force proportional to 1/distance^2. Prevents overlap and spreads
///    the graph into readable space.
/// 2. **Attraction** (Hooke's law): connected nodes attract along edges.
///    Natural links pull harder than stretch links, producing tighter clusters
///    for well-connected moves.
/// 3. **Centering**: a gentle pull toward the canvas center keeps the graph
///    from drifting off-screen.
/// 4. **Velocity damping**: each iteration reduces velocity by 10%, ensuring
///    the simulation converges instead of oscillating forever.
class _ForceLayout {
  const _ForceLayout();

  static double repulsionFor(final int nodeCount) => 8000 + nodeCount * 200;
  static const double attractionStrength = 0.001;
  static const double damping = 0.90;
  static const int iterations = 250;
  static const double idealEdgeLength = 80.0;
  static const double _canvasPadding = 30.0;

  /// Run the standard force-directed layout (Map / Focus modes).
  void run(
    final List<GraphNode> nodes,
    final List<GraphEdge> edges, {
    required final double width,
    required final double height,
  }) {
    if (nodes.isEmpty) return;
    final rng = Random(42);
    final cx = width / 2;
    final cy = height / 2;

    for (final node in nodes) {
      node.x = cx + (rng.nextDouble() - 0.5) * width * 0.6;
      node.y = cy + (rng.nextDouble() - 0.5) * height * 0.6;
      node.vx = 0;
      node.vy = 0;
    }

    _simulate(
      nodes,
      edges,
      width: width,
      height: height,
      repulsionMultiplier: 1.0,
      gravityFor: (_) => Offset(cx, cy),
      gravityStrength: 0.005,
    );
  }

  /// Category gravity ratios — fraction of canvas dimensions.
  static const Map<String, (double, double)> _categoryGravityRatios = {
    'Power Moves': (0.25, 0.25),
    'Footwork': (0.75, 0.25),
    'Freezes': (0.25, 0.75),
    'Toprock': (0.75, 0.75),
    'default': (0.50, 0.50),
  };

  /// Compute absolute gravity centers for a given canvas size.
  static Map<String, Offset> categoryGravity(final double w, final double h) =>
      {
        for (final e in _categoryGravityRatios.entries)
          e.key: Offset(w * e.value.$1, h * e.value.$2),
      };

  /// Cluster layout — per-category gravity instead of generic centering.
  void runClustered(
    final List<GraphNode> nodes,
    final List<GraphEdge> edges, {
    required final double width,
    required final double height,
  }) {
    if (nodes.isEmpty) return;
    final rng = Random(42);
    final cx = width / 2;
    final cy = height / 2;
    final gravityMap = categoryGravity(width, height);

    for (final node in nodes) {
      final gravity = gravityMap[node.category] ?? Offset(cx, cy);
      node.x = gravity.dx + (rng.nextDouble() - 0.5) * width * 0.3;
      node.y = gravity.dy + (rng.nextDouble() - 0.5) * height * 0.3;
      node.vx = 0;
      node.vy = 0;
    }

    _simulate(
      nodes,
      edges,
      width: width,
      height: height,
      repulsionMultiplier: 1.5,
      gravityFor: (final n) => gravityMap[n.category] ?? Offset(cx, cy),
      gravityStrength: 0.03,
    );
  }

  /// Shared simulation body — applies repulsion, edge attraction, gravity,
  /// and velocity damping for [iterations] ticks.
  void _simulate(
    final List<GraphNode> nodes,
    final List<GraphEdge> edges, {
    required final double width,
    required final double height,
    required final double repulsionMultiplier,
    required final Offset Function(GraphNode) gravityFor,
    required final double gravityStrength,
  }) {
    final nodeById = <String, GraphNode>{};
    for (final node in nodes) {
      nodeById[node.id] = node;
    }

    for (int iter = 0; iter < iterations; iter++) {
      final alpha = 1.0 - (iter / iterations);
      final scaledRepulsion =
          repulsionFor(nodes.length) * repulsionMultiplier * alpha;

      // Repulsion between all node pairs (O(n^2), fine for <200 nodes).
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final a = nodes[i];
          final b = nodes[j];
          final dx = b.x - a.x;
          final dy = b.y - a.y;
          var dist = sqrt(dx * dx + dy * dy);
          if (dist < 1) dist = 1;
          final force = scaledRepulsion / (dist * dist);
          final fx = (dx / dist) * force;
          final fy = (dy / dist) * force;
          a.vx -= fx;
          a.vy -= fy;
          b.vx += fx;
          b.vy += fy;
        }
      }

      // Edge attraction (Hooke's spring with rest length).
      for (final edge in edges) {
        final a = nodeById[edge.fromId];
        final b = nodeById[edge.toId];
        if (a == null || b == null) continue;
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 1) continue;
        final stiffness = switch (edge.affinity) {
          'natural' => attractionStrength * 3,
          'possible' => attractionStrength * 1.5,
          _ => attractionStrength,
        };
        final force = (dist - idealEdgeLength) * stiffness;
        final fx = (dx / dist) * force;
        final fy = (dy / dist) * force;
        a.vx += fx;
        a.vy += fy;
        b.vx -= fx;
        b.vy -= fy;
      }

      // Gravity — pulls nodes toward their target center.
      for (final node in nodes) {
        final target = gravityFor(node);
        node.vx += (target.dx - node.x) * gravityStrength;
        node.vy += (target.dy - node.y) * gravityStrength;
      }

      // Velocity damping + canvas clamping.
      for (final node in nodes) {
        node.vx *= damping;
        node.vy *= damping;
        node.x += node.vx;
        node.y += node.vy;
        node.x = node.x.clamp(_canvasPadding, width - _canvasPadding);
        node.y = node.y.clamp(_canvasPadding, height - _canvasPadding);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// CustomPainter — the actual rendering engine.
// ---------------------------------------------------------------------------

/// Paints the flow graph: dot grid background, edges, nodes, and labels.
///
/// Rendering is layered bottom-to-top:
/// 1. Dot grid (subtle orientation reference)
/// 2. Edges (lines between connected nodes)
/// 3. Node circles (filled with category color)
/// 4. Labels (move names below nodes)
///
/// Selection state dims non-connected elements to 15% opacity, creating a
/// spotlight effect on the selected node and its neighborhood.
class _FlowGraphPainter extends CustomPainter {
  _FlowGraphPainter({
    required this.nodes,
    required this.edges,
    required this.categoryColors,
    required this.selectedNodeId,
    required this.connectedNodeIds,
    required this.brightness,
    required this.ink,
    required this.separator,
    required this.accent,
    required this.unknownCategory,
    required this.viewMode,
    required this.zoomScale,
    this.multiSelectedIds = const {},
  });

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, Color> categoryColors;
  final String? selectedNodeId;
  final Set<String> connectedNodeIds;
  final Brightness brightness;

  // Resolved theme colors. A `CustomPainter` has no `BuildContext`, so these
  // are read once in `build` and passed down. Passing the *resolved* ink also
  // deletes the `brightness == Brightness.light ? light… : dark…` ternaries
  // this painter used to carry: the theme already answers that question, and
  // duplicating it here is what kept a pack and the accessibility overlay from
  // reaching the canvas.
  final Color ink;
  final Color separator;
  final Color accent;

  /// Fallback tint for a node whose category has no assigned color.
  final Color unknownCategory;

  final FlowViewMode viewMode;
  final double zoomScale;
  final Set<String> multiSelectedIds;

  /// Lazy node lookup — built once per paint cycle.
  late final Map<String, GraphNode> _nodeById = {
    for (final n in nodes) n.id: n,
  };

  // -- Constants for node sizing by mastery state --
  // Mastery nodes are the hero — large circle with a halo ring to reward
  // the learner visually. Learning nodes are mid-size. New nodes are tiny
  // and faded — they haven't earned screen real estate yet.
  static const double _radiusMastery = 17;
  static const double _radiusLearning = 12;
  static const double _radiusNew = 6;
  static const double _haloWidth = 3;
  static const double _haloGap = 2;

  /// Grid dot spacing — 24px matches AppSpacing.lg for visual consistency.
  static const double _gridSpacing = AppSpacing.lg;
  static const double _gridDotRadius = 1;

  double _radiusForMastery(final int masteryState) => switch (masteryState) {
    2 => _radiusMastery,
    1 => _radiusLearning,
    _ => _radiusNew,
  };

  @override
  void paint(final Canvas canvas, final Size size) {
    _drawDotGrid(canvas, size);
    if (viewMode == FlowViewMode.clusters) _drawCategoryLabels(canvas, size);
    _drawEdges(canvas);
    _drawNodes(canvas);
    _drawLabels(canvas, size);
  }

  /// Draws a subtle dot grid as a spatial reference layer.
  ///
  /// The dots are barely visible (6% opacity) — just enough to give the
  /// canvas a textured feel without competing with the graph data.
  void _drawDotGrid(final Canvas canvas, final Size size) {
    final dotColor = ink.withValues(alpha: 0.06);

    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += _gridSpacing) {
      for (double y = 0; y < size.height; y += _gridSpacing) {
        canvas.drawCircle(Offset(x, y), _gridDotRadius, paint);
      }
    }
  }

  /// Draws faded category names at gravity centers in Clusters mode.
  ///
  /// These labels provide spatial orientation — "Power Moves" in the
  /// top-left, "Footwork" top-right, etc. Drawn behind edges/nodes
  /// at low opacity so they don't compete with the graph data.
  void _drawCategoryLabels(final Canvas canvas, final Size size) {
    final textColor = ink.withValues(alpha: 0.22);

    final gravityMap = _ForceLayout.categoryGravity(size.width, size.height);

    for (final entry in gravityMap.entries) {
      final paragraphBuilder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: 1),
            )
            ..pushStyle(
              ui.TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            )
            ..addText(entry.key);

      final paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: 200));

      canvas.drawParagraph(
        paragraph,
        Offset(entry.value.dx - 100, entry.value.dy - 50),
      );
    }
  }

  /// Draws edges between connected nodes.
  ///
  /// Line style encodes affinity:
  /// - **natural**: solid, 1.5px — this transition flows effortlessly
  /// - **possible**: dashed (8px on, 4px off) — works with setup
  /// - **stretch**: dotted (3px on, 3px off) — risky/forced transition
  ///
  /// When a node is selected, connected edges turn blue and non-connected
  /// edges dim to 15% opacity. This "spotlight" effect uses the same
  /// accent blue as the rest of the app design system.
  void _drawEdges(final Canvas canvas) {
    // Detect parallel edge pairs for curve offset.
    final pairCount = <String, int>{};
    for (final edge in edges) {
      final key = [edge.fromId, edge.toId]..sort();
      final k = key.join('-');
      pairCount[k] = (pairCount[k] ?? 0) + 1;
    }

    for (final edge in edges) {
      final from = _nodeById[edge.fromId];
      final to = _nodeById[edge.toId];
      if (from == null || to == null) continue;

      final isConnected =
          selectedNodeId != null &&
          (edge.fromId == selectedNodeId || edge.toId == selectedNodeId);
      final isDimmed = selectedNodeId != null && !isConnected;

      // Affinity-based opacity tiers for unselected edges.
      Color edgeColor;
      if (isConnected) {
        edgeColor = accent;
      } else if (isDimmed) {
        edgeColor = separator.withValues(alpha: 0.15);
      } else {
        final alpha = switch (edge.affinity) {
          'natural' => 0.60,
          'possible' => 0.40,
          _ => 0.20,
        };
        edgeColor = separator.withValues(alpha: alpha);
      }

      final paint = Paint()
        ..color = edgeColor
        ..strokeWidth = isConnected ? 2.0 : 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final start = Offset(from.x, from.y);
      final end = Offset(to.x, to.y);

      // Curved edge for parallel pairs (A→B and B→A).
      final key = [edge.fromId, edge.toId]..sort();
      final isParallel = (pairCount[key.join('-')] ?? 0) > 1;

      if (isParallel) {
        final midX = (from.x + to.x) / 2;
        final midY = (from.y + to.y) / 2;
        // Offset control point perpendicular to the edge.
        final sign = edge.fromId.compareTo(edge.toId) < 0 ? 1.0 : -1.0;
        final perpX = -(to.y - from.y) * 0.1 * sign;
        final perpY = (to.x - from.x) * 0.1 * sign;
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(midX + perpX, midY + perpY, end.dx, end.dy);
        canvas.drawPath(path, paint);
      } else {
        switch (edge.affinity) {
          case 'natural':
            canvas.drawLine(start, end, paint);
          case 'possible':
            _drawDashedLine(
              canvas,
              start,
              end,
              paint,
              dashWidth: 8,
              gapWidth: 4,
            );
          default:
            _drawDashedLine(
              canvas,
              start,
              end,
              paint,
              dashWidth: 3,
              gapWidth: 3,
            );
        }
      }
    }
  }

  /// Draws a dashed or dotted line between two points.
  ///
  /// Uses a parametric walk along the line segment, alternating between
  /// drawing and skipping. This is cheaper than creating a Path with
  /// dashPathEffect (which allocates heavily) and sufficient for our
  /// line complexity.
  void _drawDashedLine(
    final Canvas canvas,
    final Offset start,
    final Offset end,
    final Paint paint, {
    required final double dashWidth,
    required final double gapWidth,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalLength = sqrt(dx * dx + dy * dy);
    if (totalLength < 1) return;

    final unitDx = dx / totalLength;
    final unitDy = dy / totalLength;
    final segmentLength = dashWidth + gapWidth;

    double distance = 0;
    while (distance < totalLength) {
      final dashEnd = min(distance + dashWidth, totalLength);
      canvas.drawLine(
        Offset(start.dx + unitDx * distance, start.dy + unitDy * distance),
        Offset(start.dx + unitDx * dashEnd, start.dy + unitDy * dashEnd),
        paint,
      );
      distance += segmentLength;
    }
  }

  /// Draws node circles with category-colored fills.
  ///
  /// Visual encoding by mastery:
  /// - **Mastery (2)**: Large circle + outer halo ring. The halo is the
  ///   category color at 20% opacity, creating a "glow" that signals
  ///   achievement. This is the visual reward for consistent practice.
  /// - **Learning (1)**: Mid-size solid circle. Full opacity category color.
  /// - **New (0)**: Tiny circle at 40% opacity. These moves haven't been
  ///   practiced yet — they're background noise until the learner engages.
  ///
  /// Selection dims non-connected nodes to 15% opacity, spotlighting the
  /// selected node's neighborhood.
  void _drawNodes(final Canvas canvas) {
    for (final node in nodes) {
      final radius = _radiusForMastery(node.masteryState);
      final baseColor =
          categoryColors[node.category] ?? unknownCategory;

      final isSelected = node.id == selectedNodeId;
      final isConnected = connectedNodeIds.contains(node.id);
      final isDimmed = selectedNodeId != null && !isSelected && !isConnected;

      // Compute effective color with selection-aware opacity.
      Color fillColor;
      if (isDimmed) {
        fillColor = baseColor.withValues(alpha: 0.15);
      } else if (node.masteryState == 0) {
        // New nodes are inherently faded — not yet earned.
        fillColor = baseColor.withValues(alpha: 0.40);
      } else {
        fillColor = baseColor;
      }

      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      final center = Offset(node.x, node.y);

      // Multi-select accent ring — drawn behind everything for selected nodes.
      final isMultiSelected = multiSelectedIds.contains(node.id);
      if (isMultiSelected) {
        final accentPaint = Paint()
          ..color = accent.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(center, radius + 5, accentPaint);
      }

      // Mastery halo ring — drawn behind the node circle.
      if (node.masteryState == 2 && !isDimmed) {
        final haloPaint = Paint()
          ..color = baseColor.withValues(alpha: isSelected ? 0.35 : 0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _haloWidth;

        canvas.drawCircle(
          center,
          radius + _haloGap + _haloWidth / 2,
          haloPaint,
        );
      }

      // Selected node gets a slight size boost for tactile feedback.
      final effectiveRadius = isSelected ? radius * 1.2 : radius;
      canvas.drawCircle(center, effectiveRadius, fillPaint);
    }
  }

  /// Draws text labels below nodes.
  ///
  /// Label visibility scales with mastery — new moves (radius < 8px) don't
  /// show labels to avoid clutter. This follows the information design
  /// principle of progressive disclosure: you earn screen space through
  /// practice.
  ///
  /// Typography follows the app's design system:
  /// - Mastery: 13px w600 — prominent, rewarding
  /// - Learning: 12px w500 — present but secondary
  /// - New: hidden — no label until the move is practiced
  void _drawLabels(final Canvas canvas, final Size size) {
    // Too zoomed out — labels are illegible, skip entirely.
    if (zoomScale < 0.5) return;

    final textColor = ink.withValues(alpha: 0.85);
    final maxLabelWidth = min(132.0, max(80.0, size.width * 0.18));

    // Build label candidates with priority sorting.
    final candidates =
        <
          ({
            GraphNode node,
            double x,
            double y,
            Rect rect,
            ui.Paragraph paragraph,
          })
        >[];
    for (final node in nodes) {
      final radius = _radiusForMastery(node.masteryState);
      if (radius < 8) continue; // tiny nodes get no labels

      final isSelected = node.id == selectedNodeId;
      final isConnected = connectedNodeIds.contains(node.id);
      final isDimmed = selectedNodeId != null && !isSelected && !isConnected;
      if (isDimmed) continue;

      final labelY = node.masteryState == 2
          ? node.y + radius + _haloGap + _haloWidth + 6
          : node.y + radius + 6;
      final fontSize = node.masteryState == 2 ? 13.0 : 12.0;
      final fontWeight = node.masteryState == 2
          ? FontWeight.w600
          : FontWeight.w500;
      final paragraphBuilder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                textAlign: TextAlign.center,
                maxLines: 1,
                ellipsis: '\u2026',
              ),
            )
            ..pushStyle(
              ui.TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: fontWeight,
                fontFamily: 'Inter',
              ),
            )
            ..addText(node.name);

      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: maxLabelWidth));

      final labelWidth = paragraph.longestLine;
      final labelHeight = paragraph.height;
      final labelX = (node.x - labelWidth / 2)
          .clamp(4.0, max(4.0, size.width - labelWidth - 4.0))
          .toDouble();
      final clampedY = labelY
          .clamp(4.0, max(4.0, size.height - labelHeight - 4.0))
          .toDouble();
      candidates.add((
        node: node,
        x: labelX,
        y: clampedY,
        rect: Rect.fromLTWH(
          labelX - 4,
          clampedY - 2,
          labelWidth + 8,
          labelHeight + 4,
        ),
        paragraph: paragraph,
      ));
    }

    // Mastery nodes first (they earned their labels), then multi-selected.
    candidates.sort((final a, final b) {
      final aBoost = multiSelectedIds.contains(a.node.id)
          ? 3
          : a.node.masteryState;
      final bBoost = multiSelectedIds.contains(b.node.id)
          ? 3
          : b.node.masteryState;
      return bBoost.compareTo(aBoost);
    });

    // Greedy collision-aware placement.
    final placed = <Rect>[];
    for (final c in candidates) {
      final overlaps = placed.any((final r) => r.overlaps(c.rect));
      if (overlaps) continue;
      placed.add(c.rect);
      canvas.drawParagraph(c.paragraph, Offset(c.x, c.y));
    }
  }

  @override
  bool shouldRepaint(covariant final _FlowGraphPainter oldDelegate) {
    return nodes != oldDelegate.nodes ||
        edges != oldDelegate.edges ||
        selectedNodeId != oldDelegate.selectedNodeId ||
        connectedNodeIds != oldDelegate.connectedNodeIds ||
        brightness != oldDelegate.brightness ||
        viewMode != oldDelegate.viewMode ||
        zoomScale != oldDelegate.zoomScale ||
        multiSelectedIds != oldDelegate.multiSelectedIds;
  }
}

// ---------------------------------------------------------------------------
// FlowGraphCanvas — the public widget.
// ---------------------------------------------------------------------------

/// Interactive force-directed flow graph rendered with CustomPainter.
///
/// This is the "Map" view of the Flow tab — a bird's-eye visualization of
/// all moves as colored nodes connected by transition edges. The layout
/// uses a force-directed simulation (repulsion + attraction + centering)
/// that converges in 150 iterations on init.
///
/// **Interaction model:**
/// - Pinch-to-zoom + pan via [InteractiveViewer] (0.3x to 3.0x)
/// - Tap a node to spotlight it: connected edges turn blue, everything
///   else dims to 15% opacity
/// - Tap empty space to clear the selection
///
/// **Visual encoding:**
/// - Node color = move category (user-configurable via CategoriesService)
/// - Node size = mastery state (mastery > learning > new)
/// - Edge style = affinity (solid/dashed/dotted for natural/possible/stretch)
class FlowGraphCanvas extends ConsumerStatefulWidget {
  const FlowGraphCanvas({super.key});

  @override
  ConsumerState<FlowGraphCanvas> createState() => _FlowGraphCanvasState();
}

class _FlowGraphCanvasState extends ConsumerState<FlowGraphCanvas> {
  final TransformationController _transformController =
      TransformationController();

  /// The laid-out nodes (positions computed by force simulation).
  List<GraphNode> _layoutNodes = [];

  /// All edges in the graph.
  List<GraphEdge> _layoutEdges = [];

  /// Stores the position from onDoubleTapDown so onDoubleTap can hit-test.
  Offset? _doubleTapPosition;

  /// Whether multi-select mode is active (entered via long-press on a node).
  bool _multiSelectMode = false;

  /// Set of node IDs currently selected for set creation.
  Set<String> _multiSelectedIds = {};

  /// Whether the legend overlay is visible (defaults to hidden).
  bool _showLegend = false;

  /// Tracks the last data identity to detect when we need to re-run layout.
  /// We use a simple hash of node IDs + edge pairs as a change sentinel.
  int _lastDataHash = 0;

  /// Canvas dimensions for the force layout.
  double get _canvasWidth => _dynamicCanvasSize;
  double get _canvasHeight => _dynamicCanvasSize;
  double _dynamicCanvasSize = 1400;

  /// Whether we've set the initial viewport fit.
  bool _hasSetInitialTransform = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  /// Builds a color lookup map from category name -> Color.
  ///
  /// Uses the user's custom categories from [categoriesProvider], which are
  /// stored in SharedPreferences with user-chosen colors. Falls back to
  /// [unknownCategory] for categories with no assigned color.
  Map<String, Color> _buildCategoryColors(final List<Category> categories) {
    return {for (final cat in categories) cat.name: cat.color};
  }

  /// Runs the force layout simulation on the current node/edge data.
  ///
  /// Only re-runs when the data actually changes (detected via hash).
  /// The simulation is O(n^2 * iterations) — fine for <200 nodes at 150
  /// iterations, which completes in ~10ms on modern phones.
  ///
  /// In [FlowViewMode.focus], filters to the selected node's ego graph
  /// (1-hop neighborhood). In [FlowViewMode.clusters], uses category
  /// gravity centers instead of generic centering.
  void _runLayoutIfNeeded(
    final List<GraphNode> rawNodes,
    final List<GraphEdge> edges,
    final FlowViewMode viewMode,
    final String? selectedNodeId,
  ) {
    // Compute a lightweight hash including view mode and selection so
    // layout recomputes when switching modes or selecting nodes.
    final hash = Object.hashAll([
      viewMode.index,
      selectedNodeId ?? '',
      ...rawNodes.map((final n) => n.id),
      ...edges.map((final e) => '${e.fromId}-${e.toId}'),
    ]);

    if (hash == _lastDataHash && _layoutNodes.isNotEmpty) return;
    _lastDataHash = hash;
    _hasSetInitialTransform = false; // re-fit viewport on layout change

    // --- Focus mode: ego graph of selected node + 1-hop neighbors ---
    List<GraphNode> filteredNodes;
    List<GraphEdge> filteredEdges;

    if (viewMode == FlowViewMode.focus) {
      if (selectedNodeId == null) {
        _layoutNodes = [];
        _layoutEdges = [];
        return;
      }
      // Collect 1-hop neighbor IDs.
      final neighborIds = <String>{selectedNodeId};
      for (final edge in edges) {
        if (edge.fromId == selectedNodeId) neighborIds.add(edge.toId);
        if (edge.toId == selectedNodeId) neighborIds.add(edge.fromId);
      }
      filteredNodes = rawNodes
          .where((final n) => neighborIds.contains(n.id))
          .toList();
      filteredEdges = edges
          .where(
            (final e) =>
                neighborIds.contains(e.fromId) && neighborIds.contains(e.toId),
          )
          .toList();
    } else {
      filteredNodes = rawNodes;
      filteredEdges = edges;
    }

    // Deep-copy nodes so the force layout can mutate positions without
    // affecting the provider's data.
    _layoutNodes = filteredNodes
        .map(
          (final n) => GraphNode(
            id: n.id,
            name: n.name,
            category: n.category,
            masteryState: n.masteryState,
          ),
        )
        .toList();
    _layoutEdges = filteredEdges;

    // Scale canvas to node count: 1400 base, +20 per node beyond 20.
    // 100 nodes → 1400 + 80*20 = 3000px canvas.
    _dynamicCanvasSize =
        1400 + (max(0, filteredNodes.length - 20) * 20).toDouble();

    if (viewMode == FlowViewMode.clusters) {
      const _ForceLayout().runClustered(
        _layoutNodes,
        _layoutEdges,
        width: _canvasWidth,
        height: _canvasHeight,
      );
    } else {
      const _ForceLayout().run(
        _layoutNodes,
        _layoutEdges,
        width: _canvasWidth,
        height: _canvasHeight,
      );
    }
  }

  /// Computes the set of node IDs directly connected to a given node.
  ///
  /// Used for the spotlight effect: when a node is tapped, only its
  /// immediate neighbors remain at full opacity. Everything else dims.
  Set<String> _computeConnectedIds(final String nodeId) {
    final connected = <String>{nodeId}; // include the node itself
    for (final edge in _layoutEdges) {
      if (edge.fromId == nodeId) connected.add(edge.toId);
      if (edge.toId == nodeId) connected.add(edge.fromId);
    }
    return connected;
  }

  /// Hit-tests a tap point against all nodes.
  ///
  /// Returns the ID of the first node whose center is within tap radius,
  /// or null if tapping empty space. Uses a generous hit area (node radius
  /// + 8px padding) for fat-finger friendliness.
  String? _hitTestNode(final Offset localPosition) {
    for (final node in _layoutNodes) {
      final effectiveRadius =
          switch (node.masteryState) {
            2 => _FlowGraphPainter._radiusMastery,
            1 => _FlowGraphPainter._radiusLearning,
            _ => _FlowGraphPainter._radiusNew,
          } +
          8; // padding for touch targets

      final dx = localPosition.dx - node.x;
      final dy = localPosition.dy - node.y;
      if (dx * dx + dy * dy <= effectiveRadius * effectiveRadius) {
        return node.id;
      }
    }
    return null;
  }

  /// Transform a screen-space point to canvas-space, accounting for
  /// pan/zoom from InteractiveViewer.
  Offset _screenToCanvas(final Offset screenPoint) {
    final inverse = Matrix4.inverted(_transformController.value);
    return MatrixUtils.transformPoint(inverse, screenPoint);
  }

  /// Reset spotlight selection state.
  void _clearSelection() {
    ref.read(selectedNodeProvider.notifier).state = null;
  }

  void _onTapUp(final TapUpDetails details) {
    final hitId = _hitTestNode(_screenToCanvas(details.localPosition));
    final selectedNodeId = ref.read(selectedNodeProvider);

    setState(() {
      // Multi-select mode: toggle nodes in/out of selection set.
      if (_multiSelectMode) {
        if (hitId == null) {
          _multiSelectMode = false;
          _multiSelectedIds = {};
        } else if (_multiSelectedIds.contains(hitId)) {
          _multiSelectedIds = {..._multiSelectedIds}..remove(hitId);
          HapticFeedback.selectionClick();
          if (_multiSelectedIds.isEmpty) _multiSelectMode = false;
        } else {
          _multiSelectedIds = {..._multiSelectedIds, hitId};
          HapticFeedback.selectionClick();
        }
        return;
      }

      // Normal mode: spotlight selection.
      if (hitId == null || hitId == selectedNodeId) {
        _clearSelection();
      } else {
        ref.read(selectedNodeProvider.notifier).state = hitId;
        HapticFeedback.selectionClick();
      }
    });
  }

  /// Long-press a node to enter multi-select mode for set creation.
  void _onLongPress(final LongPressStartDetails details) {
    final hitId = _hitTestNode(_screenToCanvas(details.localPosition));
    if (hitId == null) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _multiSelectMode = true;
      _multiSelectedIds = {hitId};
      _clearSelection();
    });
  }

  /// Creates a lab of type 'set' from the currently multi-selected nodes.
  Future<void> _createSetFromSelection() async {
    if (_multiSelectedIds.isEmpty) return;

    final name = await showDialog<String>(
      context: context,
      builder: (final ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Create Set'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Set name'),
            onSubmitted: (final v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty || !mounted) return;

    final labId = const Uuid().v4();
    final dao = ref.read(labsDaoProvider);
    await dao.insertLab(
      LabsCompanion.insert(id: labId, name: name, labType: const Value('set')),
    );

    // Add moves in the order they appear in the layout nodes list.
    final orderedIds = _layoutNodes
        .where((final n) => _multiSelectedIds.contains(n.id))
        .map((final n) => n.id)
        .toList();
    for (var i = 0; i < orderedIds.length; i++) {
      await dao.addMoveToLab(labId, orderedIds[i], i);
    }

    if (!mounted) return;
    setState(() {
      _multiSelectMode = false;
      _multiSelectedIds = {};
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Set '$name' created with ${orderedIds.length} moves"),
      ),
    );
    if (!mounted) return;
    unawaited(context.push('/lab/$labId'));
  }

  /// Double-tap a node to navigate to its move detail screen.
  ///
  /// Uses [_doubleTapPosition] captured in onDoubleTapDown since
  /// onDoubleTap doesn't provide position info directly. Navigates
  /// within the Flow tab so back returns to the graph.
  void _onDoubleTap() {
    if (_doubleTapPosition == null) return;
    final hitId = _hitTestNode(_screenToCanvas(_doubleTapPosition!));
    if (hitId != null) {
      HapticFeedback.mediumImpact();
      context.push('/flow/move/$hitId');
    }
  }

  /// Compact, accessible overlay button for graph utilities.
  Widget _overlayControlButton({
    required final VoidCallback onTap,
    required final AppIcon icon,
    required final String semanticsLabel,
    required final String semanticsIdentifier,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: semanticsLabel,
      identifier: semanticsIdentifier,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Ink(
            width: 36,
            height: 36,
            decoration: AppSurfaces.panel(context, radius: AppRadius.sm),
            child: AppIconView(icon, size: 18, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  /// Resets the viewport so the entire graph fits on screen — same calculation
  /// as the initial auto-fit but callable on demand (e.g. re-center button).
  void _zoomToFit() {
    if (_layoutNodes.isEmpty || !mounted) return;
    final viewportWidth = context.size?.width ?? 400;
    final viewportHeight = context.size?.height ?? 600;
    final scaleX = viewportWidth / _canvasWidth;
    final scaleY = viewportHeight / _canvasHeight;
    final fitScale = min(scaleX, scaleY) * 0.95;
    final clampedScale = fitScale.clamp(0.3, 1.0);
    final dx = (viewportWidth - _canvasWidth * clampedScale) / 2;
    final dy = (viewportHeight - _canvasHeight * clampedScale) / 2;

    // ignore: deprecated_member_use
    _transformController.value = Matrix4.identity()
      ..translate(dx, dy) // ignore: deprecated_member_use
      ..scale(clampedScale); // ignore: deprecated_member_use
  }

  Widget _emptyPlaceholder(final IconData icon, final String message) {
    final secondary = Theme.of(context).colorScheme.secondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: secondary.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: secondary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final graphData = ref.watch(flowGraphDataProvider);
    final viewMode = ref.watch(flowViewModeProvider);
    final selectedNodeId = ref.watch(selectedNodeProvider);
    final rawNodes = graphData.nodes;
    final edges = graphData.edges;
    final categories = ref.watch(categoriesProvider);
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColors = _buildCategoryColors(categories);
    final hasSelectedNode =
        selectedNodeId != null &&
        rawNodes.any((final node) => node.id == selectedNodeId);
    final effectiveSelectedNodeId = hasSelectedNode ? selectedNodeId : null;

    if (selectedNodeId != null && !hasSelectedNode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(selectedNodeProvider.notifier).state = null;
      });
    }

    // Run force layout (idempotent — only recomputes when data changes).
    _runLayoutIfNeeded(rawNodes, edges, viewMode, effectiveSelectedNodeId);
    final connectedNodeIds = effectiveSelectedNodeId == null
        ? const <String>{}
        : _computeConnectedIds(effectiveSelectedNodeId);

    // Auto-fit: zoom out so the entire graph is visible on first render.
    if (!_hasSetInitialTransform && _layoutNodes.isNotEmpty) {
      _hasSetInitialTransform = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _zoomToFit());
    }

    if (rawNodes.isEmpty) {
      return _emptyPlaceholder(
        AppIcon.discover.resolve(context),
        'Add moves to your library\nto see them mapped here.',
      );
    }

    if (viewMode == FlowViewMode.focus && effectiveSelectedNodeId == null) {
      return _emptyPlaceholder(
        AppIcon.glance.resolve(context),
        'Select a move in Map mode\nto see its connections here.',
      );
    }

    // Canvas background color from the design system.
    final canvasBg = colorScheme.surfaceContainerHighest;

    return Stack(
      children: [
        // Child 0: The graph canvas (zooms/pans via InteractiveViewer).
        ClipRect(
          child: Container(
            color: canvasBg,
            child: Semantics(
              identifier: 'flow-graph-canvas',
              label: 'Flow graph canvas',
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.3,
                maxScale: 3.0,
                boundaryMargin: const EdgeInsets.all(100),
                child: GestureDetector(
                  onTapUp: _onTapUp,
                  onLongPressStart: _onLongPress,
                  onDoubleTapDown: (final details) =>
                      _doubleTapPosition = details.localPosition,
                  onDoubleTap: _onDoubleTap,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: _canvasWidth,
                    height: _canvasHeight,
                    child: CustomPaint(
                      painter: _FlowGraphPainter(
                        nodes: _layoutNodes,
                        edges: _layoutEdges,
                        categoryColors: categoryColors,
                        selectedNodeId: effectiveSelectedNodeId,
                        connectedNodeIds: connectedNodeIds,
                        brightness: brightness,
                        ink: colorScheme.onSurface,
                        separator: colorScheme.outline,
                        accent: colorScheme.primary,
                        unknownCategory: colorScheme.secondary,
                        viewMode: viewMode,
                        zoomScale: _transformController.value
                            .getMaxScaleOnAxis(),
                        multiSelectedIds: _multiSelectedIds,
                      ),
                      size: Size(_canvasWidth, _canvasHeight),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Child 1: Legend overlay — outside InteractiveViewer so it stays
        // fixed in screen space while the graph zooms/pans beneath it.
        if (_layoutNodes.isNotEmpty && _showLegend)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: FlowGraphLegend(
              onDismiss: () => setState(() => _showLegend = false),
            ),
          ),

        // Child 2: Info toggle — re-shows the legend after dismissal.
        if (_layoutNodes.isNotEmpty)
          Positioned(
            top: 8,
            right: 8,
            child: _overlayControlButton(
              onTap: () => setState(() => _showLegend = !_showLegend),
              icon: AppIcon.help,
              semanticsLabel: _showLegend
                  ? 'Hide flow graph legend'
                  : 'Show flow graph legend',
              semanticsIdentifier: 'flow-legend-toggle',
            ),
          ),

        // Child 3: Re-center button — resets zoom/pan to fit the full graph.
        if (_layoutNodes.isNotEmpty)
          Positioned(
            top: 44,
            right: 8,
            child: _overlayControlButton(
              onTap: _zoomToFit,
              icon: AppIcon.glance,
              semanticsLabel: 'Recenter flow graph',
              semanticsIdentifier: 'flow-recenter',
            ),
          ),

        // Child 4: Multi-select bottom bar for set creation.
        if (_multiSelectMode)
          Positioned(
            bottom: AppSpacing.sm,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Cancel multi-select',
                      identifier: 'flow-selection-cancel',
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _multiSelectMode = false;
                          _multiSelectedIds = {};
                        }),
                        child: AppIconView(
                          AppIcon.close,
                          size: 20,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${_multiSelectedIds.length} selected',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: 'Create a set from selected moves',
                      identifier: 'flow-create-set',
                      child: GestureDetector(
                        onTap: _createSetFromSelection,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            'Create Set',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
