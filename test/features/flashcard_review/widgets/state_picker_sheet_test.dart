import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/flashcard_review/widgets/state_picker_sheet.dart';

Widget buildTestApp({
  required final LearningState currentState,
  required final String moveName,
  final ValueChanged<LearningState>? onSelected,
  required final SharedPreferences prefs,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      theme: ThemeData(
        extensions: const [
          AppSemanticTheme(
            isMonoOutline: false,
            stateNew: Color(0xFF6366F1),
            stateLearning: Color(0xFFF59E0B),
            stateMastery: Color(0xFF10B981),
            actionAgain: Color(0xFFEF4444),
            actionHard: Color(0xFFF97316),
            actionGood: Color(0xFF22C55E),
            actionEasy: Color(0xFF3B82F6),
          ),
        ],
      ),
      home: Scaffold(
        body: StatePickerSheet(
          currentState: currentState,
          moveName: moveName,
          onSelected: onSelected,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('onSelected callback is invoked when tapping a state option',
      (final tester) async {
    final prefs = await SharedPreferences.getInstance();
    LearningState? captured;
    await tester.pumpWidget(buildTestApp(
      currentState: LearningState.newState,
      moveName: 'Windmill',
      onSelected: (final state) => captured = state,
      prefs: prefs,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practicing'));
    await tester.pumpAndSettle();

    expect(captured, LearningState.learning);
  });

  testWidgets('onSelected captures mastery state when tapped', (final tester) async {
    final prefs = await SharedPreferences.getInstance();
    LearningState? captured;
    await tester.pumpWidget(buildTestApp(
      currentState: LearningState.learning,
      moveName: 'Flare',
      onSelected: (final state) => captured = state,
      prefs: prefs,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Strong'));
    await tester.pumpAndSettle();

    expect(captured, LearningState.mastery);
  });

  testWidgets('onSelected captures newState when tapped', (final tester) async {
    final prefs = await SharedPreferences.getInstance();
    LearningState? captured;
    await tester.pumpWidget(buildTestApp(
      currentState: LearningState.mastery,
      moveName: 'Halo',
      onSelected: (final state) => captured = state,
      prefs: prefs,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();

    expect(captured, LearningState.newState);
  });

  testWidgets('renders all three learning state options', (final tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildTestApp(
      currentState: LearningState.newState,
      moveName: 'Test Move',
      onSelected: (_) {},
      prefs: prefs,
    ));
    await tester.pumpAndSettle();

    expect(find.text('New'), findsOneWidget);
    expect(find.text('Practicing'), findsOneWidget);
    expect(find.text('Strong'), findsOneWidget);
  });

  testWidgets('current state shows a check circle indicator', (final tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildTestApp(
      currentState: LearningState.learning,
      moveName: 'Test Move',
      onSelected: (_) {},
      prefs: prefs,
    ));
    await tester.pumpAndSettle();

    final checkIcons = find.byIcon(Icons.check_circle);
    expect(checkIcons, findsOneWidget);
  });

  testWidgets('modal path uses Navigator.pop when onSelected is null',
      (final tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    final prefs = await SharedPreferences.getInstance();
    LearningState? result;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        theme: ThemeData(
          extensions: const [
            AppSemanticTheme(
              isMonoOutline: false,
              stateNew: Color(0xFF6366F1),
              stateLearning: Color(0xFFF59E0B),
              stateMastery: Color(0xFF10B981),
              actionAgain: Color(0xFFEF4444),
              actionHard: Color(0xFFF97316),
              actionGood: Color(0xFF22C55E),
              actionEasy: Color(0xFF3B82F6),
            ),
          ],
        ),
        home: Builder(
          builder: (final context) => ElevatedButton(
            onPressed: () async {
              result = await StatePickerSheet.show(
                context,
                currentState: LearningState.newState,
                moveName: 'Test',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practicing'));
    await tester.pumpAndSettle();

    expect(result, LearningState.learning);
    expect(find.text('Open'), findsOneWidget);
  });
}
