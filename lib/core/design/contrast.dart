/// WCAG contrast ratio — the readability gate for shipped packs and the live
/// readout in the per-role picker.
///
/// Deliberately separate from `oklch.dart`. OKLab lightness is a *perceptual*
/// quantity fitted to how a colour looks; WCAG contrast is defined on sRGB
/// **relative luminance**, a photometric quantity with its own coefficients and
/// its own transfer function. They answer different questions and disagree, so
/// deriving one from the other would be wrong in a way that still returns
/// plausible numbers.
///
/// The two thresholds that matter here (WCAG 2.1):
/// - **4.5:1** — normal-size text and images of text (SC 1.4.3, level AA).
/// - **3:1** — large text, and non-text UI components and graphical objects
///   whose shape must be discernible (SC 1.4.11).
///
/// Which side is foreground and which is background does not matter; the ratio
/// is symmetric by construction.
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

/// Contrast ratio between two opaque colours, in `[1, 21]`.
///
/// Alpha is ignored: a translucent colour's real contrast depends on whatever it
/// is composited over, which this function cannot know. Callers that tint must
/// composite first and pass the result, or the number is a comfortable fiction.
double contrastRatio(final Color a, final Color b) {
  final lumA = relativeLuminance(a);
  final lumB = relativeLuminance(b);
  final lighter = math.max(lumA, lumB);
  final darker = math.min(lumA, lumB);
  return (lighter + 0.05) / (darker + 0.05);
}

/// sRGB relative luminance per WCAG 2.1 — the ITU-R BT.709 luma coefficients
/// applied to linearised channels.
double relativeLuminance(final Color color) =>
    0.2126 * _linearize(color.r) +
    0.7152 * _linearize(color.g) +
    0.0722 * _linearize(color.b);

double _linearize(final double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

/// Whether [foreground] on [background] clears a threshold.
///
/// Used by the per-role picker to report pass/fail live. It reports; it does not
/// block — a user's own override is their informed choice on their own device,
/// while a pack **we** ship failing is our defect and is gated in CI.
bool meetsContrast(
  final Color foreground,
  final Color background, {
  final double minimum = 4.5,
}) => contrastRatio(foreground, background) >= minimum;
