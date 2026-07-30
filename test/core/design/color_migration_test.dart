import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/design/color_packs.dart';
import 'package:breakdex/core/design/color_roles.dart';
import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/combo_detail/widgets/status_tag.dart';
import 'package:breakdex/features/lab/widgets/achievement_tile.dart';

/// What 2.5 actually had to prove.
///
/// The conformance gate proves no file *names* `AppColors` outside the
/// definition layer. That is a spelling check — it cannot tell whether the
/// migrated sites now render what the theme says. These tests take the two
/// helpers that were the migration's hardest shape (pure functions that had no
/// `BuildContext` at all) and the media-chrome seam, and assert the axes reach
/// them.
///
/// Each assertion is written against the value the *pre-migration* code
/// produced, so it fails on the old constants rather than merely passing on the
/// new ones: `#1F8A70` is the classic mastery green those call sites were
/// pinned to, and it is what the deuteranopia overlay is supposed to replace.
Future<T> _underTheme<T>(
  final WidgetTester tester,
  final ThemeData theme,
  final T Function(BuildContext context) read,
) async {
  late T value;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (final context) {
          value = read(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  // `MaterialApp` wraps its child in an `AnimatedTheme`, so a theme swap is
  // *lerped* — and `ThemeExtension.lerp` holds the old value for t < 0.5. A
  // single `pump()` therefore reads the PREVIOUS theme, which made the first
  // run of these tests report the classic green under deuteranopia and blame
  // the migration. Settling is what makes the read the theme under test.
  await tester.pumpAndSettle();
  return value;
}

void main() {
  group('migrated helpers follow the accessibility overlay', () {
    testWidgets('statusStyle landed/clean take the overlay signal', (
      final tester,
    ) async {
      final standard = await _underTheme(
        tester,
        AppTheme.light(),
        (final c) => statusStyle(c, 'landed').color,
      );
      final deuter = await _underTheme(
        tester,
        AppTheme.light(palette: AccessiblePalette.deuteranopia),
        (final c) => statusStyle(c, 'landed').color,
      );

      expect(standard, AppColors.stateMastery);
      expect(deuter, AppColors.deuterStateMastery);
      expect(
        deuter,
        isNot(AppColors.stateMastery),
        reason:
            'statusStyle was a top-level function with no BuildContext and '
            'read the constant; under deuteranopia it kept the unsafe green.',
      );
    });

    testWidgets('AchievementTile.tierColor takes the overlay signal', (
      final tester,
    ) async {
      final deuter = await _underTheme(
        tester,
        AppTheme.light(palette: AccessiblePalette.deuteranopia),
        (final c) => AchievementTile.tierColor(c, 'mastered'),
      );
      expect(deuter, AppColors.deuterStateMastery);
    });

    testWidgets('monochrome collapses a migrated signal to ink', (
      final tester,
    ) async {
      final mono = await _underTheme(
        tester,
        AppTheme.light(palette: AccessiblePalette.monochrome),
        (final c) => (
          statusStyle(c, 'landed').color,
          Theme.of(c).colorScheme.onSurface,
        ),
      );
      expect(
        mono.$1,
        mono.$2,
        reason: 'monochrome promises no color survives, including here',
      );
    });

    testWidgets('the domain enums no longer carry a color to bypass with', (
      final tester,
    ) async {
      // `LearningState`/`ReviewRating` used to hold a baked `Color` field, so a
      // widget reading `state.color` bypassed the theme without ever naming
      // `AppColors` — invisible to the conformance gate. The lookup is now on
      // the theme, and it moves with the overlay.
      final deuter = await _underTheme(
        tester,
        AppTheme.light(palette: AccessiblePalette.deuteranopia),
        (final c) => (
          AppSemanticTheme.of(c).colorForState(LearningState.mastery),
          AppSemanticTheme.of(c).colorForRating(ReviewRating.again),
        ),
      );
      expect(deuter.$1, AppColors.deuterStateMastery);
      expect(deuter.$2, AppColors.deuterActionAgain);
    });
  });

  group('media chrome follows the pack, never the app brightness', () {
    testWidgets('classic media chrome is the classic pack at dark', (
      final tester,
    ) async {
      final chrome = await _underTheme(
        tester,
        AppTheme.light(),
        AppMediaChrome.of,
      );
      final darkSide = ResolvedColors.of(
        ColorPackId.classic.pack,
        Brightness.dark,
      );
      expect(chrome.background, darkSide[AppColorRole.background]);
      expect(chrome.card, darkSide[AppColorRole.card]);
      expect(chrome.fill, darkSide[AppColorRole.fill]);
      expect(chrome.ink, darkSide[AppColorRole.text]);
    });

    testWidgets('it is identical under light and dark app themes', (
      final tester,
    ) async {
      final fromLight = await _underTheme(
        tester,
        AppTheme.light(),
        (final c) => AppMediaChrome.of(c).background,
      );
      final fromDark = await _underTheme(
        tester,
        AppTheme.dark(),
        (final c) => AppMediaChrome.of(c).background,
      );
      expect(
        fromLight,
        fromDark,
        reason:
            'a video surface stays dark under a bright photo — that intent is '
            'why the constants looked correct, and it must survive the fix',
      );
    });

    testWidgets('a pack substitution reaches it', (final tester) async {
      final classic = await _underTheme(
        tester,
        AppTheme.light(),
        (final c) => AppMediaChrome.of(c).background,
      );
      final mono = await _underTheme(
        tester,
        AppTheme.light(pack: ColorPackId.mono),
        (final c) => AppMediaChrome.of(c).background,
      );
      expect(
        mono,
        ResolvedColors.of(
          ColorPackId.mono.pack,
          Brightness.dark,
        )[AppColorRole.background],
      );
      expect(
        mono,
        isNot(classic),
        reason: 'this is the pixel the raw AppColors.darkBg sites could not '
            'give a pack',
      );
    });
  });
}
