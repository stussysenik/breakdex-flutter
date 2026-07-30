import 'dart:math' as math;
import 'dart:ui';

import 'package:breakdex/core/design/oklch.dart';
import 'package:flutter/painting.dart' show HSLColor, HSVColor;
import 'package:flutter_test/flutter_test.dart';

/// Half an 8-bit code point — below this, two colors render identically.
const _renderTolerance = 0.5 / 255;

void _expectSameColor(final Color actual, final Color expected) {
  expect(actual.r, closeTo(expected.r, _renderTolerance), reason: 'red');
  expect(actual.g, closeTo(expected.g, _renderTolerance), reason: 'green');
  expect(actual.b, closeTo(expected.b, _renderTolerance), reason: 'blue');
}

void main() {
  group('sRGB ↔ OKLCH conversion', () {
    test('known values match the published OKLab conversions', () {
      // Ottosson's OKLab as exposed by CSS Color 4's oklch() — the sRGB
      // primaries plus white are the fixed points every implementation is
      // checked against. Wrong matrices or a wrong transfer function fail here
      // before any ramp is derived on top of them.
      const cases = <(Color, double, double, double)>[
        (Color(0xFFFFFFFF), 1.0000000, 0.0000000, 0.00),
        (Color(0xFFFF0000), 0.6279554, 0.2576833, 29.23),
        (Color(0xFF00FF00), 0.8664396, 0.2948272, 142.50),
        (Color(0xFF0000FF), 0.4520137, 0.3132475, 264.05),
      ];

      for (final (color, lightness, chroma, hue) in cases) {
        final oklch = OklchColor.fromColor(color);
        expect(
          oklch.lightness,
          closeTo(lightness, 1e-4),
          reason: 'lightness of $color',
        );
        expect(oklch.chroma, closeTo(chroma, 1e-4), reason: 'chroma of $color');
        if (chroma > 0) {
          expect(oklch.hue, closeTo(hue, 0.05), reason: 'hue of $color');
        }
      }
    });

    test('black converts to zero lightness', () {
      final oklch = OklchColor.fromColor(const Color(0xFF000000));
      expect(oklch.lightness, closeTo(0, 1e-6));
      expect(oklch.chroma, closeTo(0, 1e-6));
    });

    test('achromatic colors report hue 0 rather than a numeric artifact', () {
      // atan2 on a chroma of ~1e-17 returns whatever the rounding produced.
      // Pinning it keeps a gray seed's ramp stable instead of hue-jittering.
      for (final gray in const [
        Color(0xFF000000),
        Color(0xFF808080),
        Color(0xFFF7F7F7),
        Color(0xFFFFFFFF),
      ]) {
        expect(OklchColor.fromColor(gray).hue, 0, reason: '$gray');
      }
    });

    test('round trip is lossless within rendering tolerance', () {
      // Every seed the shipped palettes use, plus the extremes and a mid gray.
      for (final color in const [
        Color(0xFF1F5EFF), // accent
        Color(0xFFE45D7A), // stateNew
        Color(0xFF1F8A70), // stateMastery
        Color(0xFFC23B2A), // actionAgain
        Color(0xFFB7791F), // actionHard
        Color(0xFF0D9F9A), // actionEasy
        Color(0xFF0B0D12), // lightText
        Color(0xFFF8FAFC), // lightBg
        Color(0xFF808080),
        Color(0xFF000000),
        Color(0xFFFFFFFF),
      ]) {
        _expectSameColor(OklchColor.fromColor(color).toColor(), color);
      }
    });

    test('round trip is lossless across a swept hue circle', () {
      // A hue-by-hue sweep catches a sign error in one matrix row that the
      // primaries alone can miss.
      for (var hue = 0; hue < 360; hue += 7) {
        final source = HSVColor.fromAHSV(1, hue.toDouble(), 0.8, 0.7).toColor();
        _expectSameColor(OklchColor.fromColor(source).toColor(), source);
      }
    });

    test('opacity is re-applied, not carried through the space', () {
      // Alpha is not part of OKLab; the conversion drops it and toColor puts it
      // back, so a translucent seed does not silently become opaque.
      final color = OklchColor.fromColor(
        const Color(0xFF1F5EFF),
      ).toColor(opacity: 0.5);
      expect(color.a, closeTo(0.5, 1e-6));
    });
  });

  group('gamut fitting', () {
    test('an unreachable chroma is spent, and the hue is not', () {
      // Chroma 0.4 at L 0.5 is outside sRGB for every hue. Reducing chroma at
      // fixed (L, h) desaturates; clipping RGB channels would rotate the hue.
      for (var hue = 0; hue < 360; hue += 15) {
        // The tolerances are float noise, not slack: the fit must not move hue
        // or lightness at all. A looser bound here is what let the boundary
        // overshoot ship — it drifted hue by 3.5° and passed.
        final requested = OklchColor(0.5, 0.4, hue.toDouble());
        final fitted = OklchColor.fromColor(requested.toColor());
        expect(fitted.hue, closeTo(hue.toDouble(), 1e-4), reason: 'hue at $hue');
        expect(
          fitted.lightness,
          closeTo(0.5, 1e-6),
          reason: 'lightness at $hue',
        );
        expect(
          fitted.chroma,
          lessThan(0.4),
          reason: 'chroma should have been reduced at $hue',
        );
      }
    });

    test('an in-gamut color is returned untouched', () {
      const requested = OklchColor(0.6, 0.05, 200);
      final fitted = OklchColor.fromColor(requested.toColor());
      expect(fitted.chroma, closeTo(0.05, 1e-3));
    });
  });

  group('rampFromSeed', () {
    const seeds = <Color>[
      Color(0xFF1F5EFF), // blue accent
      Color(0xFFE45D7A), // pink
      Color(0xFF1F8A70), // green
      Color(0xFFB7791F), // amber — the hue an HSL ramp handles worst
      Color(0xFF808080), // achromatic
    ];

    test('lightness is strictly monotonic, light to bold', () {
      for (final seed in seeds) {
        final ramp = rampFromSeed(seed);
        final lightness = ramp.steps.map(perceptualLightness).toList();
        for (var i = 1; i < lightness.length; i++) {
          expect(
            lightness[i],
            lessThan(lightness[i - 1]),
            reason: 'step $i of $seed must be bolder than step ${i - 1}',
          );
        }
      }
    });

    test('hue is stable across every step', () {
      // The ramp's whole claim is that a step is a weight, not a new color. Two
      // degrees is under a just-noticeable hue difference at these chromas, and
      // it absorbs the gamut fit at the extremes.
      for (final seed in seeds) {
        final seedHue = OklchColor.fromColor(seed).hue;
        if (OklchColor.fromColor(seed).chroma < 0.01) continue;
        for (final step in rampFromSeed(seed).steps) {
          final stepColor = OklchColor.fromColor(step);
          if (stepColor.chroma < 0.01) continue; // taper ends, hue is moot
          final delta = (stepColor.hue - seedHue).abs();
          expect(
            math.min(delta, 360 - delta),
            lessThan(2),
            reason: 'step $step drifted from hue $seedHue of $seed',
          );
        }
      }
    });

    test('an achromatic seed produces a grayscale ramp', () {
      for (final step in rampFromSeed(const Color(0xFF808080)).steps) {
        expect(OklchColor.fromColor(step).chroma, lessThan(1e-6));
      }
    });

    test('corresponding steps of different hues read as the same weight', () {
      // This is what a pack buys by deriving instead of listing hexes: step 4
      // of the amber ramp and step 4 of the blue ramp are the same weight, so
      // one contrast threshold applies to both.
      final ramps = seeds.map(rampFromSeed).toList();
      for (var step = 0; step < ramps.first.length; step++) {
        final lightness = ramps
            .map((final ramp) => perceptualLightness(ramp[step]))
            .toList();
        final spread =
            lightness.reduce(math.max) - lightness.reduce(math.min);
        expect(
          spread,
          lessThan(0.01),
          reason: 'step $step spans $spread of perceived lightness across hues',
        );
      }
    });

    test('step count is a parameter, not a constant', () {
      expect(rampFromSeed(const Color(0xFF1F5EFF), steps: 5).length, 5);
      expect(rampFromSeed(const Color(0xFF1F5EFF), steps: 12).length, 12);
    });
  });

  group('OKLCH vs HSL — the claim D2 rests on', () {
    // D2 chose OKLCH over HSL for one measurable reason. If HSL were good
    // enough, the ~140 lines of conversion in oklch.dart would be dead weight,
    // so the comparison is asserted rather than argued.
    const yellowHue = 60.0;
    const blueHue = 240.0;

    test('equal HSL lightness reads as very different brightness', () {
      final yellow = const HSLColor.fromAHSL(1, yellowHue, 1, 0.5).toColor();
      final blue = const HSLColor.fromAHSL(1, blueHue, 1, 0.5).toColor();
      final gap =
          (perceptualLightness(yellow) - perceptualLightness(blue)).abs();
      // Measured ~0.42 — nearly half the visible lightness range at the same
      // nominal HSL "lightness".
      expect(gap, greaterThan(0.3));
    });

    test('equal OKLCH lightness reads as the same brightness', () {
      final yellow = const OklchColor(0.6, 0.12, yellowHue).toColor();
      final blue = const OklchColor(0.6, 0.12, blueHue).toColor();
      final gap =
          (perceptualLightness(yellow) - perceptualLightness(blue)).abs();
      expect(gap, lessThan(0.01));
    });

    test('an HSL ramp is uneven across hues where the OKLCH ramp is not', () {
      // Same experiment at ramp scale: build both ramps for both hues and
      // compare how far apart the corresponding steps sit.
      const steps = 9;
      double worstSpread(final double Function(int step, double hue) build) {
        var worst = 0.0;
        for (var step = 0; step < steps; step++) {
          final spread = (build(step, yellowHue) - build(step, blueHue)).abs();
          worst = math.max(worst, spread);
        }
        return worst;
      }

      final hslWorst = worstSpread(
        (final step, final hue) => perceptualLightness(
          HSLColor.fromAHSL(1, hue, 0.7, 0.95 - 0.08 * step).toColor(),
        ),
      );
      final oklchWorst = worstSpread(
        (final step, final hue) => perceptualLightness(
          rampFromSeed(
            OklchColor(0.6, 0.12, hue).toColor(),
            steps: steps,
          )[step],
        ),
      );

      expect(hslWorst, greaterThan(0.15));
      expect(oklchWorst, lessThan(0.01));
    });
  });
}
