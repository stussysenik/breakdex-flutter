import 'package:flutter/material.dart';

/// Computes a stable popover anchor for `share_plus` on iOS/iPadOS.
///
/// The returned rect is based on the triggering widget's render box when
/// available. If the widget is not laid out yet, a small fallback rect is
/// returned so the platform share sheet still has a valid origin.
Rect sharePositionOrigin(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    if (!rect.isEmpty) return rect;
  }

  final mediaQuery = MediaQuery.maybeOf(context);
  if (mediaQuery != null) {
    final center = mediaQuery.size.center(Offset.zero);
    return Rect.fromCenter(center: center, width: 1, height: 1);
  }

  return const Rect.fromLTWH(0, 0, 1, 1);
}
