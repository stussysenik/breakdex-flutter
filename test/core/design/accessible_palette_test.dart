import 'package:breakdex/core/design/color_packs.dart';
import 'package:breakdex/core/design/color_roles.dart';
import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/contrast.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/models/learning_state_colors.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/flashcard_review/widgets/rating_button_row.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/icon_finders.dart';

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

    // 2.4 — `error` is an AppColorRoleKind.signal, so the overlay owns it like
    // every other signal. It was hardwired to the classic `actionAgain` hex in
    // every mode, which leaked one unsafe red into both accessible palettes:
    // deuteranopia moved the "again" rating to Okabe–Ito vermillion while an
    // error surface stayed #C23B2A, and monochrome kept it while claiming no
    // color survives. Asserted per palette rather than "error == actionAgain",
    // so a pack seeding `error` independently stays free to under `standard`.
    test('every signal follows the overlay, `error` included', () {
      for (final build in <ThemeData Function(AccessiblePalette)>[
        (final p) => AppTheme.light(palette: p),
        (final p) => AppTheme.dark(palette: p),
      ]) {
        final deuter = build(AccessiblePalette.deuteranopia);
        expect(
          deuter.colorScheme.error,
          AppColors.deuterActionAgain,
          reason: 'deuteranopia must reach ColorScheme.error, not just the ramp',
        );

        final mono = build(AccessiblePalette.monochrome);
        expect(
          mono.colorScheme.error,
          _semanticOf(mono).actionAgain,
          reason: 'monochrome claims no color survives — error is not exempt',
        );
        expect(
          mono.colorScheme.error,
          isNot(AppColors.actionAgain),
          reason: 'the shipped red is exactly what a grayscale mode must drop',
        );
      }
    });

    // The overlay must not hand back an unreadable pair: whatever it names for
    // a failed condition, the ink on top of it is chosen for contrast, not
    // inherited from the pack that no longer owns the color.
    test('onError stays legible against whatever the overlay names', () {
      for (final palette in AccessiblePalette.values) {
        for (final theme in [
          AppTheme.light(palette: palette),
          AppTheme.dark(palette: palette),
        ]) {
          final scheme = theme.colorScheme;
          expect(
            contrastRatio(scheme.onError, scheme.error),
            greaterThanOrEqualTo(4.5),
            reason: 'onError on error, palette ${palette.name}',
          );
        }
      }
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
                localizationsDelegates:
                    AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
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
      expect(findAppIcon(AppIcon.close), findsOneWidget); // again
      expect(findAppIcon(AppIcon.forward), findsOneWidget); // hard
      expect(findAppIcon(AppIcon.check), findsOneWidget); // good
      expect(findAppIcon(AppIcon.star), findsOneWidget); // easy
      // ...as do the four text labels.
      expect(find.text('AGAIN'), findsOneWidget);
      expect(find.text('HARD'), findsOneWidget);
      expect(find.text('GOOD'), findsOneWidget);
      expect(find.text('EASY'), findsOneWidget);
    },
  );

  group('contrast — every shipped pack, both brightnesses', () {
    // D5: a pack **we** ship failing contrast is our defect and is gated here. A
    // user's own per-role override is not — the picker shows the ratio and
    // accepts the value either way.
    //
    // Pairs are chosen to match pixels that actually render. Thresholds are
    // WCAG 2.1: 4.5:1 for text (SC 1.4.3), 3:1 for graphical objects whose shape
    // must be discernible (SC 1.4.11). Signals get 3:1 rather than 4.5:1 because
    // none of them carries meaning alone — every one is paired with an icon and a
    // label, which is asserted separately above.
    const textPairs = <(AppColorRole, AppColorRole)>[
      (AppColorRole.text, AppColorRole.background),
      (AppColorRole.text, AppColorRole.card),
      (AppColorRole.text, AppColorRole.fill),
      (AppColorRole.secondaryText, AppColorRole.background),
      (AppColorRole.secondaryText, AppColorRole.card),
      (AppColorRole.secondaryText, AppColorRole.fill),
      (AppColorRole.onAccent, AppColorRole.accent),
      (AppColorRole.onError, AppColorRole.error),
    ];

    test('text clears 4.5:1 on every surface it renders on', () {
      for (final id in ColorPackId.values) {
        for (final brightness in Brightness.values) {
          final colors = ResolvedColors.of(id.pack, brightness);
          for (final (foreground, background) in textPairs) {
            final ratio = contrastRatio(colors[foreground], colors[background]);
            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason:
                  '${id.name}/${brightness.name}: ${foreground.name} on '
                  '${background.name} is ${ratio.toStringAsFixed(2)}:1',
            );
          }
        }
      }
    });

    test('every signal clears 3:1 on card and background', () {
      for (final id in ColorPackId.values) {
        for (final brightness in Brightness.values) {
          final colors = ResolvedColors.of(id.pack, brightness);
          for (final signal in AppColorRole.signals) {
            for (final surface in [
              AppColorRole.card,
              AppColorRole.background,
            ]) {
              final ratio = contrastRatio(colors[signal], colors[surface]);
              expect(
                ratio,
                greaterThanOrEqualTo(3),
                reason:
                    '${id.name}/${brightness.name}: ${signal.name} on '
                    '${surface.name} is ${ratio.toStringAsFixed(2)}:1',
              );
            }
          }
        }
      }
    });

    test('MEASURED, NOT GATED: actionEasy on fill is 2.98:1 in classic light', () {
      // Teal #0D9F9A on #F1F5F9. It fails 3:1 by 0.02, and it is recorded here
      // rather than gated for two reasons: no shipped surface paints a raw signal
      // on `fill` (rating pills composite the signal at alpha 0.10 over the
      // surface, so the real ratio is a different number), and moving a shipped
      // hex is a design decision, not a test's call. Tracked as add-color-packs
      // 4.5. If this assertion starts failing, the palette changed — re-measure
      // the whole table rather than editing the number.
      final classicLight = ResolvedColors.of(
        ColorPackId.classic.pack,
        Brightness.light,
      );
      expect(
        contrastRatio(
          classicLight[AppColorRole.actionEasy],
          classicLight[AppColorRole.fill],
        ),
        closeTo(2.98, 0.01),
      );
    });

    test('the accessibility overlays do not lower text contrast', () {
      // The overlay replaces signals; if it ever touched surfaces or ink, this
      // is where a regression would land.
      for (final palette in AccessiblePalette.values) {
        for (final theme in [
          AppTheme.light(palette: palette),
          AppTheme.dark(palette: palette),
        ]) {
          final scheme = theme.colorScheme;
          expect(
            contrastRatio(scheme.onSurface, scheme.surface),
            greaterThanOrEqualTo(4.5),
            reason: '${palette.name}: onSurface on surface',
          );
          expect(
            contrastRatio(scheme.onSurface, theme.scaffoldBackgroundColor),
            greaterThanOrEqualTo(4.5),
            reason: '${palette.name}: onSurface on scaffold',
          );
          expect(
            contrastRatio(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(4.5),
            reason: '${palette.name}: onPrimary on primary',
          );
        }
      }
    });
  });
}
