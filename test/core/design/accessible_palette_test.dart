import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/models/learning_state_colors.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/flashcard_review/widgets/rating_button_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Luminance-weighted grayscale — removes all hue/saturation from the subtree so
// the test literally renders "color removed".
const _grayscale = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];

AppSemanticTheme _semanticOf(final ThemeData theme) =>
    theme.extension<AppSemanticTheme>()!;

void main() {
  group('accessiblePaletteProvider', () {
    test('defaults to standard and persists a selection across a restart',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(accessiblePaletteProvider),
        AccessiblePalette.standard,
      );

      await container
          .read(accessiblePaletteProvider.notifier)
          .set(AccessiblePalette.deuteranopia);
      expect(prefs.getString('accessible_palette'), 'deuteranopia');

      // A fresh container over the same prefs = the restart case.
      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);
      expect(
        restarted.read(accessiblePaletteProvider),
        AccessiblePalette.deuteranopia,
      );
    });

    test('an unknown stored value falls back to standard', () async {
      SharedPreferences.setMockInitialValues({'accessible_palette': 'bogus'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(
        container.read(accessiblePaletteProvider),
        AccessiblePalette.standard,
      );
    });
  });

  group('AppTheme palette resolution', () {
    test('deuteranopia swaps the semantic ramp but leaves surfaces intact', () {
      final theme = AppTheme.light(palette: AccessiblePalette.deuteranopia);
      final semantic = _semanticOf(theme);

      expect(semantic.stateNew, AppColors.deuterStateNew);
      expect(semantic.stateLearning, AppColors.deuterStateLearning);
      expect(semantic.stateMastery, AppColors.deuterStateMastery);
      expect(semantic.actionAgain, AppColors.deuterActionAgain);
      expect(semantic.actionEasy, AppColors.deuterActionEasy);
      expect(semantic.isMonoOutline, isFalse);

      // Surfaces and accent are untouched by the color-blind-safe ramp.
      expect(theme.scaffoldBackgroundColor, AppColors.lightBg);
      expect(theme.colorScheme.primary, AppColors.accent);
    });

    test('monochrome grayscales surfaces and inks the semantic ramp', () {
      final theme = AppTheme.light(palette: AccessiblePalette.monochrome);
      final semantic = _semanticOf(theme);

      // Surfaces render from the grayscale ramp.
      expect(theme.scaffoldBackgroundColor, AppColors.monoLightBg);
      expect(theme.colorScheme.surface, AppColors.monoLightCard);
      // Accent is toned to ink so no color survives.
      expect(theme.colorScheme.primary, AppColors.monoLightText);
      // Every semantic signal collapses to ink...
      expect(semantic.stateNew, AppColors.monoLightText);
      expect(semantic.actionGood, AppColors.monoLightText);
      // ...but this is NOT the marker/outline aesthetic — surfaces stay filled.
      expect(semantic.isMonoOutline, isFalse);
    });

    test('standard is unchanged and returns exactly on toggle-off', () {
      // A baseline theme built before any palette was ever chosen.
      final baseline = AppTheme.light();
      // The same theme after selecting then clearing an accessible palette.
      final restored = AppTheme.light(palette: AccessiblePalette.standard);

      final base = _semanticOf(baseline);
      final back = _semanticOf(restored);
      expect(back.stateNew, base.stateNew);
      expect(back.actionAgain, base.actionAgain);
      expect(back.isMonoOutline, base.isMonoOutline);
      expect(restored.scaffoldBackgroundColor, baseline.scaffoldBackgroundColor);
      expect(restored.colorScheme.primary, baseline.colorScheme.primary);
      // The standard ramp still honors user-customized state colors.
      expect(base.stateNew, AppColors.stateNew);
    });

    test('standard still applies user-customized state colors', () {
      const custom = LearningStateColors(
        newState: Color(0xFF112233),
        learning: Color(0xFF445566),
        mastery: Color(0xFF778899),
      );
      final theme = AppTheme.light(stateColors: custom);
      expect(_semanticOf(theme).stateNew, const Color(0xFF112233));
    });
  });

  testWidgets(
    'rating signals stay distinguishable by icon + label with color removed',
    (final tester) async {
      // Force monochrome (all semantic colors collapse to ink) AND wrap the row
      // in a grayscale filter — color is genuinely gone, twice over.
      SharedPreferences.setMockInitialValues({
        'accessible_palette': 'monochrome',
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: Consumer(
            builder: (final context, final ref, final _) {
              final palette = ref.watch(accessiblePaletteProvider);
              return MaterialApp(
                theme: AppTheme.light(palette: palette),
                home: Scaffold(
                  body: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(_grayscale),
                    child: RatingButtonRow(onRate: (final _) {}),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Four distinct icon shapes survive the loss of color...
      expect(find.byIcon(Icons.close_rounded), findsOneWidget); // again
      expect(find.byIcon(Icons.trending_flat_rounded), findsOneWidget); // hard
      expect(find.byIcon(Icons.check_rounded), findsOneWidget); // good
      expect(find.byIcon(Icons.star_rounded), findsOneWidget); // easy
      // ...as do the four text labels.
      expect(find.text('AGAIN'), findsOneWidget);
      expect(find.text('HARD'), findsOneWidget);
      expect(find.text('GOOD'), findsOneWidget);
      expect(find.text('EASY'), findsOneWidget);
    },
  );
}
