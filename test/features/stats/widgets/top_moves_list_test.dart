import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/stats/providers/stats_providers.dart';
import 'package:breakdex/features/stats/widgets/top_moves_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('top moves list handles long metadata without overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'learning_state_labels':
          '{"NEW":"New","LEARNING":"Learning","MASTERY":"Mastery"}',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: Consumer(
          builder: (context, ref, _) {
            final stateColors = ref.watch(learningStateColorsProvider);
            return MaterialApp(
              theme: AppTheme.light(stateColors: stateColors),
              home: Scaffold(
                body: SizedBox(
                  width: 220,
                  child: TopMovesList(
                    topMoves: [
                      TopMoveInfo(
                        moveId: 'move-1',
                        moveName:
                            'Very Long Move Name That Should Still Stay Readable',
                        reviewCount: 14,
                        category: 'Power Moves',
                        fsrsStateLabel: LearningState.learning.displayText,
                        lastReviewed: DateTime(2026, 4, 3),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Power Moves'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
    expect(find.text('Apr 3'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
