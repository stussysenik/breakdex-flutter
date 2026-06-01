import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/features/flow/providers/flow_graph_providers.dart';

void main() {
  group('flow graph derived providers', () {
    late ProviderContainer container;

    setUp(() {
      final graphData = FlowGraphData(
        nodes: [
          GraphNode(
            id: 'move-a',
            name: 'Airflare',
            category: 'Power Moves',
            masteryState: 2,
          ),
          GraphNode(
            id: 'move-b',
            name: 'Swipe',
            category: 'Power Moves',
            masteryState: 1,
          ),
          GraphNode(
            id: 'move-c',
            name: 'Six-Step',
            category: 'Footwork',
            masteryState: 1,
          ),
          GraphNode(
            id: 'move-d',
            name: 'Baby Freeze',
            category: 'Freezes',
            masteryState: 0,
          ),
          GraphNode(
            id: 'move-e',
            name: 'Indian Step',
            category: 'Toprock',
            masteryState: 0,
          ),
        ],
        edges: const [
          GraphEdge(fromId: 'move-a', toId: 'move-b', affinity: 'natural'),
          GraphEdge(fromId: 'move-b', toId: 'move-a', affinity: 'possible'),
          GraphEdge(fromId: 'move-c', toId: 'move-b', affinity: 'stretch'),
          GraphEdge(fromId: 'move-b', toId: 'move-d', affinity: 'natural'),
        ],
      );

      container = ProviderContainer(
        overrides: [flowGraphDataProvider.overrideWith((final ref) => graphData)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('summary counts mastery mix, categories, and isolated nodes', () {
      final summary = container.read(flowGraphSummaryProvider);

      expect(summary.nodeCount, 5);
      expect(summary.edgeCount, 4);
      expect(summary.categoryCount, 4);
      expect(summary.masteredCount, 1);
      expect(summary.learningCount, 2);
      expect(summary.newCount, 2);
      expect(summary.isolatedCount, 1);
    });

    test('selected node details describe immediate routes and neighbors', () {
      container.read(selectedNodeProvider.notifier).state = 'move-b';

      final details = container.read(selectedFlowNodeDetailsProvider);

      expect(details, isNotNull);
      expect(details!.node.name, 'Swipe');
      expect(details.masteryLabel, 'Learning');
      expect(details.incomingCount, 2);
      expect(details.outgoingCount, 2);
      expect(details.neighborCount, 3);
      expect(details.reciprocalCount, 1);
      expect(details.sameCategoryCount, 1);
      expect(details.crossCategoryCount, 2);
      expect(details.naturalTransitionCount, 2);
      expect(details.possibleTransitionCount, 1);
      expect(details.stretchTransitionCount, 1);
      expect(details.neighborNames, ['Airflare', 'Baby Freeze', 'Six-Step']);
    });

    test('selection details are null when nothing is selected', () {
      expect(container.read(selectedFlowNodeDetailsProvider), isNull);
    });
  });
}
