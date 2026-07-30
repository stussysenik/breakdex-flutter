/// Perceptual color space for the color-pack ramps.
///
/// A pack declares a small seed set and derives its weight ramp instead of
/// listing every step as a hex. Derivation happens in OKLCH because equal steps
/// in HSL are not equal *perceived* steps: a yellow and a blue at HSL lightness
/// 0.5 differ by roughly a third of the visible lightness range, so an HSL ramp
/// reads uneven across hues. OKLab was fitted against perceptual datasets, so
/// one ramp definition produces steps that read evenly spaced for every hue —
/// and the step that clears a contrast threshold is the same step per hue,
/// which is what makes the contrast gate a property of the ramp rather than a
/// per-color accident.
///
/// The transform chain is sRGB → linear RGB → LMS → OKLab → OKLCH and back.
/// Coefficients are Björn Ottosson's published matrices (OKLab, 2020); they are
/// two matrix multiplies and a cube root either way, which is why no package is
/// added for them.
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

/// A color in cylindrical OKLab: perceptual lightness, chroma, hue angle.
///
/// [lightness] runs 0 (black) → 1 (white). [chroma] is unbounded in the space
/// but only a hue-dependent slice of it is reachable in sRGB — see
/// [toColor], which trades chroma away rather than hue when a value does not
/// fit. [hue] is degrees in `[0, 360)`.
class OklchColor {
  const OklchColor(this.lightness, this.chroma, this.hue);

  final double lightness;
  final double chroma;
  final double hue;

  /// Converts an sRGB color. Alpha is not part of the space and is dropped;
  /// callers that need it re-apply it after derivation.
  factory OklchColor.fromColor(final Color color) {
    final lab = _linearToOklab(
      _srgbToLinear(color.r),
      _srgbToLinear(color.g),
      _srgbToLinear(color.b),
    );
    final chroma = math.sqrt(lab.a * lab.a + lab.b * lab.b);
    // atan2 of a numerically-zero chroma is meaningless; pin achromatic colors
    // to hue 0 so round-tripping gray is stable rather than jittering by hue.
    final hue = chroma < _achromatic
        ? 0.0
        : (math.atan2(lab.b, lab.a) * 180 / math.pi + 360) % 360;
    return OklchColor(lab.l, chroma, hue);
  }

  OklchColor withLightness(final double lightness) =>
      OklchColor(lightness, chroma, hue);

  OklchColor withChroma(final double chroma) =>
      OklchColor(lightness, chroma, hue);

  /// Converts to sRGB, reducing chroma until the result is in gamut.
  ///
  /// Out-of-gamut values must be resolved somehow, and the choice is visible:
  /// clipping the RGB channels shifts hue (the clipped channel changes the
  /// ratio between the other two), while reducing chroma at fixed lightness and
  /// hue desaturates without moving the hue angle at all. The ramp's stated
  /// guarantee is hue stability across steps, so chroma is what gets spent.
  Color toColor({final double opacity = 1}) {
    final fitted = _fitToGamut();
    final (r, g, b) = _oklabToLinear(
      fitted.lightness,
      fitted.chroma * math.cos(fitted.hue * math.pi / 180),
      fitted.chroma * math.sin(fitted.hue * math.pi / 180),
    );
    return Color.from(
      alpha: opacity,
      red: _linearToSrgb(r),
      green: _linearToSrgb(g),
      blue: _linearToSrgb(b),
    );
  }

  /// Largest in-gamut chroma at this lightness and hue, found by bisection.
  ///
  /// The sRGB gamut boundary in OKLCH has no closed form, and in-gamut-ness is
  /// monotonic in chroma along a fixed (L, h) ray, so bisection is both correct
  /// and cheap. 24 iterations resolve chroma far below one 8-bit code point.
  OklchColor _fitToGamut() {
    if (_isInGamut(lightness, chroma, hue)) return this;
    var low = 0.0;
    var high = chroma;
    for (var i = 0; i < 24; i++) {
      final mid = (low + high) / 2;
      if (_isInGamut(lightness, mid, hue)) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return OklchColor(lightness, low, hue);
  }

  @override
  String toString() =>
      'oklch(${lightness.toStringAsFixed(4)} '
      '${chroma.toStringAsFixed(4)} ${hue.toStringAsFixed(2)})';
}

/// A derived weight ramp: light → bold, one hue, evenly spaced in perception.
///
/// [steps] are ordered light-first. Index 0 is the lightest tint and
/// `steps.length - 1` the boldest shade, so a pack names a weight by position
/// rather than by hex. The step count is not fixed by the mechanism — it falls
/// out of whichever pack is being written — so the guarantees asserted are
/// monotonic lightness and stable hue, not a particular length.
class ColorRamp {
  const ColorRamp(this.steps);

  final List<Color> steps;

  Color operator [](final int index) => steps[index];

  int get length => steps.length;
}

/// Derives a [ColorRamp] from one seed color.
///
/// Lightness is distributed linearly from [lightest] down to [boldest]; the
/// seed contributes hue and chroma, not position, so two seeds of different hue
/// produce ramps whose corresponding steps read as the same weight. Chroma is
/// tapered toward both ends: at L→0 and L→1 the reachable chroma of every hue
/// collapses to nothing, and a ramp that ignores that spends its extreme steps
/// on colors the gamut fit would flatten anyway.
///
/// Achromatic seeds stay achromatic — the taper multiplies a zero chroma — so
/// the same call produces the grayscale ramp a mono pack needs.
ColorRamp rampFromSeed(
  final Color seed, {
  final int steps = 9,
  final double lightest = 0.97,
  final double boldest = 0.22,
}) {
  assert(steps >= 2, 'a ramp needs at least two steps to have a direction');
  final base = OklchColor.fromColor(seed);
  return ColorRamp(
    List<Color>.generate(steps, (final index) {
      final t = index / (steps - 1);
      final lightness = lightest + (boldest - lightest) * t;
      return OklchColor(
        lightness,
        base.chroma * _chromaTaper(lightness),
        base.hue,
      ).toColor();
    }, growable: false),
  );
}

/// Chroma multiplier peaking mid-ramp and falling to 0 at both ends.
///
/// A raised cosine over the lightness range: `sin(πL)` reaches 1 at L = 0.5 and
/// 0 at both poles. The 0.35 exponent keeps the mid range nearly flat so only
/// the extremes are visibly desaturated — a linear taper washes out the whole
/// ramp, which is the "generated palettes look cheap" failure this avoids.
double _chromaTaper(final double lightness) =>
    math.pow(math.sin(lightness.clamp(0.0, 1.0) * math.pi), 0.35).toDouble();

// --- sRGB ↔ OKLab ---------------------------------------------------------

/// Below this, hue is numerically undefined and reported as 0.
const _achromatic = 1e-6;

/// Float noise on the gamut boundary, not a perceptual tolerance.
///
/// It is deliberately far below any visible slack. An earlier value of half an
/// 8-bit step measured in *linear* RGB let the bisection settle just outside
/// the boundary; the transfer function's slope near black is 12.92, so a linear
/// overshoot of 0.002 became six encoded code points, and the clamp in
/// [_linearToSrgb] then moved both hue (by 3.5°) and lightness — the two things
/// the fit exists to hold fixed. The bisection's lower bound is in gamut by
/// construction, so the clamp is now unreachable rather than merely small.
const _gamutEpsilon = 1e-9;

typedef _Oklab = ({double l, double a, double b});

double _srgbToLinear(final double channel) => channel <= 0.04045
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _linearToSrgb(final double channel) {
  final clamped = channel.clamp(0.0, 1.0);
  return clamped <= 0.0031308
      ? clamped * 12.92
      : 1.055 * math.pow(clamped, 1 / 2.4).toDouble() - 0.055;
}

_Oklab _linearToOklab(final double r, final double g, final double b) {
  final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return (
    l: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    a: 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    b: 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  );
}

(double, double, double) _oklabToLinear(
  final double lightness,
  final double a,
  final double b,
) {
  final l = _cube(
    lightness + 0.3963377774 * a + 0.2158037573 * b,
  );
  final m = _cube(lightness - 0.1055613458 * a - 0.0638541728 * b);
  final s = _cube(lightness - 0.0894841775 * a - 1.2914855480 * b);
  return (
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
  );
}

bool _isInGamut(final double lightness, final double chroma, final double hue) {
  final (r, g, b) = _oklabToLinear(
    lightness,
    chroma * math.cos(hue * math.pi / 180),
    chroma * math.sin(hue * math.pi / 180),
  );
  // Tested in linear RGB, where the gamut is the unit cube.
  bool inside(final double channel) =>
      channel >= -_gamutEpsilon && channel <= 1 + _gamutEpsilon;
  return inside(r) && inside(g) && inside(b);
}

/// Signed cube root — OKLab's nonlinearity is applied to values that can go
/// negative during a round trip, where `pow` returns NaN.
double _cbrt(final double value) => value < 0
    ? -math.pow(-value, 1 / 3).toDouble()
    : math.pow(value, 1 / 3).toDouble();

double _cube(final double value) => value * value * value;

/// Perceptual lightness of an sRGB color — the L of its OKLab form.
///
/// Named separately because the ramp tests and the HSL comparison in
/// `oklch_test.dart` both need "how light does this read" without constructing
/// a full [OklchColor].
double perceptualLightness(final Color color) => _linearToOklab(
  _srgbToLinear(color.r),
  _srgbToLinear(color.g),
  _srgbToLinear(color.b),
).l;
