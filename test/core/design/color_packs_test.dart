import 'package:breakdex/core/design/color_packs.dart';
import 'package:breakdex/core/design/color_roles.dart';
import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/models/learning_state_colors.dart';
import 'package:breakdex/core/models/rating_colors.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The role → constant mapping the pre-pack theme rendered, written out by hand.
///
/// Deliberately duplicated from `_ClassicColorPack` rather than derived from it:
/// a test that reads the same switch it is checking proves only that the switch
/// is self-consistent. These are the values `AppTheme` inlined before packs
/// existed, so an accidental edit to the pack shows up as a diff here.
const _classicLight = <AppColorRole, Color>{
  AppColorRole.background: AppColors.lightBg,
  AppColorRole.card: AppColors.lightCard,
  AppColorRole.fill: AppColors.lightFill,
  AppColorRole.separator: AppColors.lightSeparator,
  AppColorRole.text: AppColors.lightText,
  AppColorRole.secondaryText: AppColors.lightSecondary,
  AppColorRole.accent: AppColors.accent,
  AppColorRole.onAccent: Colors.white,
  AppColorRole.error: AppColors.actionAgain,
  AppColorRole.onError: Colors.white,
  AppColorRole.stateNew: AppColors.stateNew,
  AppColorRole.stateLearning: AppColors.stateLearning,
  AppColorRole.stateMastery: AppColors.stateMastery,
  AppColorRole.actionAgain: AppColors.actionAgain,
  AppColorRole.actionHard: AppColors.actionHard,
  AppColorRole.actionGood: AppColors.actionGood,
  AppColorRole.actionEasy: AppColors.actionEasy,
};

const _classicDark = <AppColorRole, Color>{
  AppColorRole.background: AppColors.darkBg,
  AppColorRole.card: AppColors.darkCard,
  AppColorRole.fill: AppColors.darkFill,
  AppColorRole.separator: AppColors.darkSeparator,
  AppColorRole.text: AppColors.darkText,
  AppColorRole.secondaryText: AppColors.darkSecondary,
  AppColorRole.accent: AppColors.accent,
  AppColorRole.onAccent: Colors.white,
  AppColorRole.error: AppColors.actionAgain,
  AppColorRole.onError: Colors.white,
  AppColorRole.stateNew: AppColors.stateNew,
  AppColorRole.stateLearning: AppColors.stateLearning,
  AppColorRole.stateMastery: AppColors.stateMastery,
  AppColorRole.actionAgain: AppColors.actionAgain,
  AppColorRole.actionHard: AppColors.actionHard,
  AppColorRole.actionGood: AppColors.actionGood,
  AppColorRole.actionEasy: AppColors.actionEasy,
};

AppSemanticTheme _semanticOf(final ThemeData theme) =>
    theme.extension<AppSemanticTheme>()!;

void main() {
  group('ColorPackId', () {
    test('an unknown or absent stored key resolves to classic', () {
      // A pack removed in a later release must not brick the app for whoever
      // had it selected.
      expect(ColorPackId.fromKey(null), ColorPackId.classic);
      expect(ColorPackId.fromKey(''), ColorPackId.classic);
      expect(ColorPackId.fromKey('seasonal-2027'), ColorPackId.classic);
      expect(ColorPackId.fromKey('CLASSIC'), ColorPackId.classic);
    });

    test('a known key round-trips through its stored form', () {
      for (final id in ColorPackId.values) {
        expect(ColorPackId.fromKey(id.key), id, reason: id.name);
      }
    });

    test('keys are unique and stable, not derived from the display name', () {
      expect(
        ColorPackId.values.map((final id) => id.key).toSet().length,
        ColorPackId.values.length,
      );
      expect(ColorPackId.classic.key, 'classic');
      expect(ColorPackId.mono.key, 'mono');
    });
  });

  group('pack completeness', () {
    test('every pack resolves every role at both brightnesses', () {
      for (final id in ColorPackId.values) {
        for (final brightness in Brightness.values) {
          for (final role in AppColorRole.values) {
            expect(
              () => id.pack.resolve(role, brightness),
              returnsNormally,
              reason: '${id.name} / ${brightness.name} / ${role.name}',
            );
          }
        }
      }
    });

    test('ResolvedColors is total by construction', () {
      for (final id in ColorPackId.values) {
        final colors = ResolvedColors.of(id.pack, Brightness.light);
        for (final role in AppColorRole.values) {
          expect(colors[role], isNotNull, reason: '${id.name} / ${role.name}');
        }
      }
    });
  });

  group('classic pack is byte-identical to the pre-pack rendering', () {
    test('every role matches the constant the old theme inlined', () {
      _classicLight.forEach((final role, final expected) {
        expect(
          ColorPackId.classic.pack.resolve(role, Brightness.light),
          expected,
          reason: 'light ${role.name}',
        );
      });
      _classicDark.forEach((final role, final expected) {
        expect(
          ColorPackId.classic.pack.resolve(role, Brightness.dark),
          expected,
          reason: 'dark ${role.name}',
        );
      });
    });

    test('the built ColorScheme matches the old slot-by-slot values', () {
      for (final (brightness, expected) in [
        (Brightness.light, _classicLight),
        (Brightness.dark, _classicDark),
      ]) {
        final scheme = (brightness == Brightness.light
                ? AppTheme.light()
                : AppTheme.dark())
            .colorScheme;
        expect(scheme.brightness, brightness);
        expect(scheme.primary, expected[AppColorRole.accent]);
        expect(scheme.onPrimary, expected[AppColorRole.onAccent]);
        expect(scheme.secondary, expected[AppColorRole.secondaryText]);
        expect(scheme.onSecondary, expected[AppColorRole.text]);
        expect(scheme.surface, expected[AppColorRole.card]);
        expect(scheme.onSurface, expected[AppColorRole.text]);
        expect(scheme.error, expected[AppColorRole.error]);
        expect(scheme.onError, expected[AppColorRole.onError]);
        expect(
          scheme.surfaceContainerHighest,
          expected[AppColorRole.fill],
        );
        expect(scheme.outline, expected[AppColorRole.separator]);
      }
    });

    test('the scaffold background is the background role, not the card', () {
      // These two were separate parameters in the old signature and are easy to
      // collapse by accident, because `surface` sounds like "the background".
      expect(AppTheme.light().scaffoldBackgroundColor, AppColors.lightBg);
      expect(AppTheme.dark().scaffoldBackgroundColor, AppColors.darkBg);
      expect(AppTheme.light().colorScheme.surface, AppColors.lightCard);
    });

    test('the semantic ramp matches the old defaults', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final semantic = _semanticOf(theme);
        expect(semantic.isMonoOutline, isFalse);
        expect(semantic.stateNew, AppColors.stateNew);
        expect(semantic.stateLearning, AppColors.stateLearning);
        expect(semantic.stateMastery, AppColors.stateMastery);
        expect(semantic.actionAgain, AppColors.actionAgain);
        expect(semantic.actionHard, AppColors.actionHard);
        expect(semantic.actionGood, AppColors.actionGood);
        expect(semantic.actionEasy, AppColors.actionEasy);
      }
    });

    test('the grayscale modes keep their pre-pack values', () {
      // monoOutline and the monochrome overlay both ran a hand-rolled `gray ?`
      // branch before packs; they now run the `mono` pack. Same pixels.
      for (final theme in [
        AppTheme.light(viewingMode: ViewingMode.monoOutline),
        AppTheme.light(palette: AccessiblePalette.monochrome),
      ]) {
        expect(theme.scaffoldBackgroundColor, AppColors.monoLightBg);
        expect(theme.colorScheme.surface, AppColors.monoLightCard);
        expect(
          theme.colorScheme.surfaceContainerHighest,
          AppColors.monoLightFill,
        );
        expect(theme.colorScheme.onSurface, AppColors.monoLightText);
        expect(theme.colorScheme.secondary, AppColors.monoLightSecondary);
        expect(theme.colorScheme.outline, AppColors.monoLightSeparator);
        // Accent tones to ink; what sits on it is the background, never a
        // hardcoded white.
        expect(theme.colorScheme.primary, AppColors.monoLightText);
        expect(theme.colorScheme.onPrimary, AppColors.monoLightBg);
      }
      final dark = AppTheme.dark(palette: AccessiblePalette.monochrome);
      expect(dark.scaffoldBackgroundColor, AppColors.monoDarkBg);
      expect(dark.colorScheme.primary, AppColors.monoDarkText);
      expect(dark.colorScheme.onPrimary, AppColors.monoDarkBg);
    });

    test(
      'grayscale still leaks one red through ColorScheme.error — 2.4, preserved',
      () {
        // Not an endorsement: `error` is hardwired to the "again" value in every
        // mode and follows no overlay, so monochrome shows one colored pixel and
        // deuteranopia keeps an unsafe red. Pinned here because 3.2 requires
        // byte-identity with the pre-pack build; the fix is add-color-packs 2.4,
        // and this assertion is what will go red when it lands.
        expect(
          AppTheme.light(palette: AccessiblePalette.monochrome)
              .colorScheme
              .error,
          AppColors.actionAgain,
        );
        expect(
          AppTheme.light(palette: AccessiblePalette.deuteranopia)
              .colorScheme
              .error,
          AppColors.actionAgain,
        );
      },
    );
  });

  group('mono pack', () {
    test('surfaces come from the existing grayscale ramp', () {
      final pack = ColorPackId.mono.pack;
      expect(pack.resolve(AppColorRole.background, Brightness.light),
          AppColors.monoLightBg);
      expect(pack.resolve(AppColorRole.card, Brightness.light),
          AppColors.monoLightCard);
      expect(pack.resolve(AppColorRole.fill, Brightness.light),
          AppColors.monoLightFill);
      expect(pack.resolve(AppColorRole.separator, Brightness.light),
          AppColors.monoLightSeparator);
      expect(pack.resolve(AppColorRole.background, Brightness.dark),
          AppColors.monoDarkBg);
      expect(pack.resolve(AppColorRole.card, Brightness.dark),
          AppColors.monoDarkCard);
    });

    test('no signal carries color — every one collapses to ink', () {
      final pack = ColorPackId.mono.pack;
      for (final brightness in Brightness.values) {
        final ink = pack.resolve(AppColorRole.text, brightness);
        for (final role in AppColorRole.signals) {
          expect(
            pack.resolve(role, brightness),
            ink,
            reason: '${role.name} / ${brightness.name}',
          );
        }
        expect(pack.resolve(AppColorRole.accent, brightness), ink);
      }
    });

    test('selecting it as a pack renders the grayscale surfaces', () {
      final theme = AppTheme.light(pack: ColorPackId.mono);
      expect(theme.scaffoldBackgroundColor, AppColors.monoLightBg);
      expect(theme.colorScheme.primary, AppColors.monoLightText);
      // A pack is not a viewing mode: the marker-outline flag stays off, so
      // surfaces are still filled.
      expect(_semanticOf(theme).isMonoOutline, isFalse);
    });
  });

  group('per-role overrides', () {
    const hotPink = Color(0xFFFF69B4);

    test('an override wins over the pack for that role only', () {
      final theme = AppTheme.light(
        overrides: const {AppColorRole.accent: hotPink},
      );
      expect(theme.colorScheme.primary, hotPink);
      // Everything else is untouched.
      expect(theme.colorScheme.surface, AppColors.lightCard);
      expect(_semanticOf(theme).stateMastery, AppColors.stateMastery);
    });

    test('an override reaches the semantic ramp, not just the ColorScheme', () {
      final theme = AppTheme.light(
        overrides: const {AppColorRole.actionGood: hotPink},
      );
      expect(_semanticOf(theme).actionGood, hotPink);
    });

    test('overrides apply on top of whichever pack is selected', () {
      final theme = AppTheme.light(
        pack: ColorPackId.mono,
        overrides: const {AppColorRole.accent: hotPink},
      );
      expect(theme.colorScheme.primary, hotPink);
      expect(theme.scaffoldBackgroundColor, AppColors.monoLightBg);
    });

    test('the typed convenience parameters fold into the same map', () {
      // `AppTheme.light(stateColors: …)` is sugar for three role overrides —
      // widget tests read better that way, and the two paths must not diverge.
      const custom = LearningStateColors(
        newState: hotPink,
        learning: hotPink,
        mastery: hotPink,
      );
      final viaTyped = AppTheme.light(stateColors: custom);
      final viaMap = AppTheme.light(
        overrides: const {
          AppColorRole.stateNew: hotPink,
          AppColorRole.stateLearning: hotPink,
          AppColorRole.stateMastery: hotPink,
        },
      );
      expect(_semanticOf(viaTyped).stateNew, _semanticOf(viaMap).stateNew);
      expect(_semanticOf(viaTyped).stateMastery, hotPink);
    });

    test('rating colors now reach the theme, closing the second source', () {
      // Before packs, rating overrides were applied inside
      // `rating_button_row.dart` and never reached `AppSemanticTheme`, so any
      // other consumer of `colorForRating` rendered the default.
      const custom = RatingColors(
        again: hotPink,
        hard: hotPink,
        good: hotPink,
        easy: hotPink,
      );
      expect(
        _semanticOf(AppTheme.light(ratingColors: custom)).actionEasy,
        hotPink,
      );
    });

    test('omitting a parameter means "use the pack", not "use classic"', () {
      // The trap the nullable defaults exist to avoid: a non-null default would
      // silently override every pack with the classic values.
      final theme = AppTheme.light(pack: ColorPackId.mono);
      expect(_semanticOf(theme).stateMastery, AppColors.monoLightText);
      expect(theme.colorScheme.primary, isNot(AppColors.accent));
    });
  });

  group('axis precedence — pack, then brightness, then overlay', () {
    const hotPink = Color(0xFFFF69B4);

    test('the overlay replaces signals the pack supplied', () {
      final theme = AppTheme.light(palette: AccessiblePalette.deuteranopia);
      final semantic = _semanticOf(theme);
      expect(semantic.stateMastery, AppColors.deuterStateMastery);
      expect(semantic.actionAgain, AppColors.deuterActionAgain);
    });

    test('a pack cannot defeat the deuteranopia guarantee', () {
      for (final id in ColorPackId.values) {
        final semantic = _semanticOf(
          AppTheme.light(pack: id, palette: AccessiblePalette.deuteranopia),
        );
        expect(semantic.stateNew, AppColors.deuterStateNew,
            reason: id.name);
        expect(semantic.actionEasy, AppColors.deuterActionEasy,
            reason: id.name);
      }
    });

    test('a per-role override cannot defeat it either', () {
      final semantic = _semanticOf(
        AppTheme.light(
          overrides: const {AppColorRole.actionGood: hotPink},
          palette: AccessiblePalette.deuteranopia,
        ),
      );
      expect(semantic.actionGood, AppColors.deuterActionGood);
    });

    test('the pack still supplies surfaces under deuteranopia', () {
      // The overlay owns signals only — a user on deuteranopia keeps their pack.
      final theme = AppTheme.light(
        pack: ColorPackId.mono,
        palette: AccessiblePalette.deuteranopia,
      );
      expect(theme.scaffoldBackgroundColor, AppColors.monoLightBg);
    });

    test('monochrome makes pack selection invisible', () {
      // Correct, and the reason the interface has to say so rather than letting
      // the user discover their selection did nothing.
      final classic = AppTheme.light(
        pack: ColorPackId.classic,
        palette: AccessiblePalette.monochrome,
      );
      final mono = AppTheme.light(
        pack: ColorPackId.mono,
        palette: AccessiblePalette.monochrome,
      );
      expect(classic.scaffoldBackgroundColor, mono.scaffoldBackgroundColor);
      expect(classic.colorScheme.primary, mono.colorScheme.primary);
      expect(
        _semanticOf(classic).stateMastery,
        _semanticOf(mono).stateMastery,
      );
    });

    test('returning to standard restores the pack and the overrides', () {
      // The non-destructive property, asserted end to end rather than trusted:
      // the overlay is applied at build time and stores nothing.
      const overrides = {AppColorRole.accent: hotPink};
      final before = AppTheme.light(
        pack: ColorPackId.mono,
        overrides: overrides,
      );
      final duringOverlay = AppTheme.light(
        pack: ColorPackId.mono,
        overrides: overrides,
        palette: AccessiblePalette.monochrome,
      );
      final after = AppTheme.light(
        pack: ColorPackId.mono,
        overrides: overrides,
        palette: AccessiblePalette.standard,
      );
      expect(duringOverlay.colorScheme.primary, AppColors.monoLightText);
      expect(after.colorScheme.primary, hotPink);
      expect(after.colorScheme.primary, before.colorScheme.primary);
      expect(
        after.scaffoldBackgroundColor,
        before.scaffoldBackgroundColor,
      );
    });
  });
}
