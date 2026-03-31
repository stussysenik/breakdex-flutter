import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/flow/flow_screen.dart';
import 'package:breakdex/features/flow/providers/flow_graph_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FlowGraphData graphData;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'flow_coach_shown': true,
    });

    graphData = FlowGraphData(
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
  });

  Future<void> pumpFlowScreen(
    WidgetTester tester, {
    String? selectedNodeId,
    FlowViewMode mode = FlowViewMode.map,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(1179, 2556);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          pendingChangesCountProvider.overrideWith(
            (ref) => Stream<int>.value(0),
          ),
          isLoggedInProvider.overrideWith((ref) => false),
          flowGraphDataProvider.overrideWith((ref) => graphData),
          selectedNodeProvider.overrideWith((ref) => selectedNodeId),
          flowViewModeProvider.overrideWith((ref) => mode),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const FlowScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('shows the clearer mode explanation and honest entity note', (
    tester,
  ) async {
    await pumpFlowScreen(tester);

    expect(find.text('Whole practice network'), findsOneWidget);
    expect(
      find.textContaining('Moves are graphable now. Combo and set equations'),
      findsOneWidget,
    );
    expect(
      find.textContaining('See what connects, inspect one move at a time'),
      findsOneWidget,
    );
    expect(find.text('Moves'), findsWidgets);
    expect(find.text('Links'), findsOneWidget);
    expect(find.text('Zones'), findsWidgets);
  });

  testWidgets('shows the selected move inspector and its actions', (
    tester,
  ) async {
    await pumpFlowScreen(
      tester,
      selectedNodeId: 'move-b',
    );

    expect(find.text('Swipe'), findsOneWidget);
    expect(find.text('Power Moves'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
    expect(find.text('Cross-zone'), findsOneWidget);
    expect(find.text('Natural'), findsOneWidget);
    expect(find.textContaining('Connects with Airflare'), findsOneWidget);
    expect(find.text('Focus move'), findsOneWidget);
    expect(find.text('Open detail'), findsOneWidget);
  });
}
