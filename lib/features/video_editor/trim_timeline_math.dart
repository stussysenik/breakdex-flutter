import 'dart:ui';

double trimHandleSensitivity({
  required double verticalLiftPx,
  double coarseSensitivity = 1.0,
  double fineSensitivity = 0.25,
  double fullLiftPx = 72,
}) {
  final t = (verticalLiftPx / fullLiftPx).clamp(0.0, 1.0).toDouble();
  return lerpDouble(coarseSensitivity, fineSensitivity, t)!;
}

double snapNormalizedToDuration(
  double normalized,
  int durationMs, {
  int quantumMs = 1,
}) {
  final clamped = normalized.clamp(0.0, 1.0).toDouble();
  if (durationMs <= 0 || quantumMs <= 1) {
    return clamped;
  }

  final ms = (clamped * durationMs).round();
  final snappedMs = ((ms / quantumMs).round() * quantumMs).clamp(0, durationMs);
  return snappedMs / durationMs;
}

/// Compute raw (unsnapped) normalized position after a drag delta.
/// Sensitivity scaling is applied but no frame-grid snapping —
/// prevents rounding error from accumulating across drag updates.
///
/// **Why this exists:** `applyTrimHandleDrag` snaps to a 33ms quantum on
/// every update. Because the snapped value becomes the *input* for the next
/// update, tiny rounding losses compound over dozens of frames-per-second of
/// dragging, causing the handle to creep leftward. This function keeps a
/// pristine floating-point accumulator that is only snapped for display.
double applyRawDrag({
  required double currentRaw,
  required double deltaDx,
  required double timelineWidth,
  required double verticalLiftPx,
  required double minValue,
  required double maxValue,
}) {
  if (timelineWidth <= 0) return currentRaw.clamp(minValue, maxValue).toDouble();
  final sensitivity = trimHandleSensitivity(verticalLiftPx: verticalLiftPx);
  final raw = currentRaw + (deltaDx / timelineWidth) * sensitivity;
  return raw.clamp(minValue, maxValue).toDouble();
}

double applyTrimHandleDrag({
  required double currentValue,
  required double deltaDx,
  required double timelineWidth,
  required double verticalLiftPx,
  required double minValue,
  required double maxValue,
  required int durationMs,
  int quantumMs = 1,
}) {
  final clampedCurrent = currentValue.clamp(minValue, maxValue).toDouble();
  if (timelineWidth <= 0) {
    return clampedCurrent;
  }

  final sensitivity = trimHandleSensitivity(verticalLiftPx: verticalLiftPx);
  final raw = clampedCurrent + (deltaDx / timelineWidth) * sensitivity;
  final snapped = snapNormalizedToDuration(
    raw,
    durationMs,
    quantumMs: quantumMs,
  );
  return snapped.clamp(minValue, maxValue).toDouble();
}
