import 'dart:math' as math;

import 'package:flutter/widgets.dart';

@immutable
class VideoEditViewport {
  const VideoEditViewport({
    required this.size,
    required this.orientedVideoSize,
    required this.minScale,
    required this.maxScale,
  });

  final Size size;
  final Size orientedVideoSize;
  final double minScale;
  final double maxScale;

  Matrix4 initialTransform() {
    final dx = (size.width - orientedVideoSize.width * minScale) / 2;
    final dy = (size.height - orientedVideoSize.height * minScale) / 2;
    return _matrix(scale: minScale, tx: dx, ty: dy);
  }

  Matrix4 clampTransform(Matrix4 transform) {
    final requestedScale = _matrixScale(transform);
    final scale = requestedScale.clamp(minScale, maxScale).toDouble();
    final contentWidth = orientedVideoSize.width * scale;
    final contentHeight = orientedVideoSize.height * scale;
    final translation = transform.getTranslation();

    final tx = _clampAxisTranslation(
      translation.x,
      viewportExtent: size.width,
      contentExtent: contentWidth,
    );
    final ty = _clampAxisTranslation(
      translation.y,
      viewportExtent: size.height,
      contentExtent: contentHeight,
    );

    return _matrix(scale: scale, tx: tx, ty: ty);
  }

  Rect normalizedCropRect(Matrix4 transform) {
    final clamped = clampTransform(transform);
    final scale = _matrixScale(clamped);
    final translation = clamped.getTranslation();

    final left = (-translation.x / scale)
        .clamp(0.0, orientedVideoSize.width)
        .toDouble();
    final top = (-translation.y / scale)
        .clamp(0.0, orientedVideoSize.height)
        .toDouble();
    final right = ((size.width - translation.x) / scale)
        .clamp(left, orientedVideoSize.width)
        .toDouble();
    final bottom = ((size.height - translation.y) / scale)
        .clamp(top, orientedVideoSize.height)
        .toDouble();

    return Rect.fromLTRB(
      left / orientedVideoSize.width,
      top / orientedVideoSize.height,
      right / orientedVideoSize.width,
      bottom / orientedVideoSize.height,
    );
  }

  static Matrix4 _matrix({
    required double scale,
    required double tx,
    required double ty,
  }) {
    final matrix = Matrix4.diagonal3Values(scale, scale, 1);
    matrix.setTranslationRaw(tx, ty, 0);
    return matrix;
  }

  static double _clampAxisTranslation(
    double translation, {
    required double viewportExtent,
    required double contentExtent,
  }) {
    if (contentExtent <= viewportExtent) {
      return (viewportExtent - contentExtent) / 2;
    }
    return translation.clamp(viewportExtent - contentExtent, 0.0).toDouble();
  }

  static double _matrixScale(Matrix4 matrix) {
    final storage = matrix.storage;
    final scaleX = math.sqrt(storage[0] * storage[0] + storage[1] * storage[1]);
    final scaleY = math.sqrt(storage[4] * storage[4] + storage[5] * storage[5]);
    return math.max(scaleX, scaleY);
  }
}

VideoEditViewport computeVideoEditViewport({
  required Size videoSize,
  required int rotation,
  required double maxWidth,
  double maxHeight = 300,
  double? targetAspect,
  double maxScaleMultiplier = 8,
}) {
  final normalizedRotation = ((rotation % 360) + 360) % 360;
  final isRotated = normalizedRotation == 90 || normalizedRotation == 270;
  final orientedVideoSize = Size(
    isRotated ? videoSize.height : videoSize.width,
    isRotated ? videoSize.width : videoSize.height,
  );

  final viewportSize = _computeViewportSize(
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    targetAspect: targetAspect,
  );
  final minScale = math.max(
    viewportSize.width / orientedVideoSize.width,
    viewportSize.height / orientedVideoSize.height,
  );

  return VideoEditViewport(
    size: viewportSize,
    orientedVideoSize: orientedVideoSize,
    minScale: minScale,
    maxScale: minScale * maxScaleMultiplier,
  );
}

Size _computeViewportSize({
  required double maxWidth,
  required double maxHeight,
  required double? targetAspect,
}) {
  if (targetAspect == null) {
    return Size(maxWidth, maxHeight);
  }

  if (maxWidth / maxHeight > targetAspect) {
    final height = maxHeight;
    return Size(height * targetAspect, height);
  }

  final width = maxWidth;
  return Size(width, width / targetAspect);
}

bool matrixCloseTo(Matrix4 a, Matrix4 b, {double epsilon = 0.001}) {
  for (var i = 0; i < 16; i++) {
    if ((a.storage[i] - b.storage[i]).abs() > epsilon) {
      return false;
    }
  }
  return true;
}
