import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/services/fsrs_service.dart';
import 'package:breakdex/features/stats/providers/stats_providers.dart';
import 'package:breakdex/features/stats/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('progress screen leads with parent-first structure and queue', (
    tester,
  ) async {
    final bundle = StatsBundle(
      ratingDistribution: const {'GOOD': 6, 'AGAIN': 2},
      topMoveEntries: const [],
      topMoves: const [],
      currentStreak: 4,
      dailyCounts: const {},
      allMoves: const [],
      dueSummary: const DueSummary(
        newDue: 2,
        learningDue: 1,
        reviewDue: 0,
        totalDueToday: 3,
        dueTomorrow: 1,
      ),
      totalStateCounts: const TotalStateCounts(
        newCount: 2,
        learningCount: 1,
        reviewCount: 4,
        relearningCount: 0,
      ),
      overallRetention: 0.75,
      categoryMastery: const [],
      dailyBreakdown: const [],
      cardStats: [
        CardReviewStats(
          entityId: 'move-1',
          entityType: 'move',
          displayName: 'Airflare',
          category: 'power',
          shownCount: 8,
          againCount: 1,
          hardCount: 1,
          goodCount: 5,
          easyCount: 1,
          isDeleted: false,
          lastReviewedAt: DateTime(2026, 4, 3),
        ),
        CardReviewStats(
          entityId: 'move-2',
          entityType: 'move',
          displayName: 'Six-Step',
          category: 'footwork',
          shownCount: 4,
          againCount: 1,
          hardCount: 1,
          goodCount: 2,
          easyCount: 0,
          isDeleted: false,
          lastReviewedAt: DateTime(2026, 4, 2),
        ),
      ],
      reviewTimeline: const [],
      moveProgressGroups: [
        MoveProgressGroup(
          category: 'power',
          reviewedCount: 1,
          dueNowCount: 1,
          dueTodayCount: 1,
          dueTomorrowCount: 0,
          items: [
            MoveProgressItem(
              moveId: 'move-1',
              moveName: 'Airflare',
              category: 'power',
              stateLabel: 'Learning',
              statusLabel: 'Ready now',
              reviewCount: 8,
              dueBucket: ProgressDueBucket.now,
              lastReviewedAt: DateTime(2026, 4, 3),
            ),
          ],
        ),
      ],
      comboProgressGroups: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [statsBundleProvider.overrideWith((ref) async => bundle)],
        child: MaterialApp(theme: AppTheme.light(), home: const StatsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Start Here'), findsOneWidget);
    expect(find.text('Move Parents'), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);
  });
}
