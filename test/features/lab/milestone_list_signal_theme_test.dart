// Red/green proof for task 2.5a of `add-color-packs`.
//
// `milestone_list.dart` painted `AppColors.stateMastery` (#1F8A70) straight into
// a live decoration, so the `AccessiblePalette.deuteranopia` overlay — which
// publishes Okabe–Ito #009E73 for the same role — never reached those pixels.
// This pumps the widget under the deuteranopia theme and asserts the rendered
// decoration carries the overlay's value, not the raw constant.
//
// One test is the proof for the whole class of 114 migrated signal reads; the
// remaining sites are covered by the conformance ban (2.5c), not by 113 more
// widget tests.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/lab/providers/lab_providers.dart';
import 'package:breakdex/features/lab/widgets/milestone_list.dart';

void main() {
  const labId = 'lab-under-test';

  final completed = Milestone(
    id: 'm1',
    labId: labId,
    title: 'Freeze held for 5s',
    completedAt: DateTime(2026, 7, 30),
    createdAt: DateTime(2026, 7, 1),
  );

  Future<void> pump(final WidgetTester tester, final ThemeData theme) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          labMilestonesProvider(
            labId,
          ).overrideWith((final ref) => Stream.value([completed])),
        ],
        child: MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: SingleChildScrollView(child: MilestoneList(labId: labId)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Every color painted by the completed-milestone checkbox container.
  Set<int> checkboxColors(final WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(MilestoneList),
        matching: find.byWidgetPredicate(
          (final w) => w is Container && w.constraints?.maxWidth == 22,
        ),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    return {
      decoration.color!.toARGB32(),
      decoration.border!.top.color.toARGB32(),
    };
  }

  testWidgets(
    'completed-milestone signal follows the deuteranopia overlay',
    (final tester) async {
      await pump(
        tester,
        AppTheme.light(palette: AccessiblePalette.deuteranopia),
      );

      final painted = checkboxColors(tester);
      final safe = AppColors.deuterStateMastery.toARGB32() & 0x00FFFFFF;
      final unsafe = AppColors.stateMastery.toARGB32() & 0x00FFFFFF;

      for (final color in painted) {
        expect(
          color & 0x00FFFFFF,
          isNot(unsafe),
          reason:
              'raw AppColors.stateMastery (#1F8A70) reached the pixel — the '
              'AccessiblePalette overlay was bypassed',
        );
        expect(color & 0x00FFFFFF, safe);
      }
    },
  );

  testWidgets('standard palette still paints the standard mastery signal', (
    final tester,
  ) async {
    await pump(tester, AppTheme.light());

    for (final color in checkboxColors(tester)) {
      expect(color & 0x00FFFFFF, AppColors.stateMastery.toARGB32() & 0x00FFFFFF);
    }
  });
}
