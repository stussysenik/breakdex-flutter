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

  Matrix4 clampTransform(final Matrix4 transform) {
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

  Rect normalizedCropRect(final Matrix4 transform) {
    final clamped = clampTransform(transform);
    final scale = _matrixScale(clamped);
    final translation = clamped.getTranslation();

    final leftPx = (-translation.x / scale)
        .clamp(0.0, orientedVideoSize.width)
        .toDouble();
    final topPx = (-translation.y / scale)
        .clamp(0.0, orientedVideoSize.height)
        .toDouble();
    final rightPx = ((size.width - translation.x) / scale)
        .clamp(leftPx, orientedVideoSize.width)
        .toDouble();
    final bottomPx = ((size.height - translation.y) / scale)
        .clamp(topPx, orientedVideoSize.height)
        .toDouble();

    final left = leftPx / orientedVideoSize.width;
    final top = topPx / orientedVideoSize.height;
    final right = rightPx / orientedVideoSize.width;
    final bottom = bottomPx / orientedVideoSize.height;

    debugPrint(
      '[VideoEditViewport] normalizedCropRect: '
      'viewport=${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)} '
      'orientedVideo=${orientedVideoSize.width.toStringAsFixed(0)}x${orientedVideoSize.height.toStringAsFixed(0)} '
      'scale=${scale.toStringAsFixed(4)} tx=${translation.x.toStringAsFixed(1)} ty=${translation.y.toStringAsFixed(1)} '
      'leftPx=$leftPx topPx=$topPx rightPx=$rightPx bottomPx=$bottomPx '
      '→ norm ltrb: ${left.toStringAsFixed(4)} ${top.toStringAsFixed(4)} ${right.toStringAsFixed(4)} ${bottom.toStringAsFixed(4)}',
    );

    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Matrix4 _matrix({
    required final double scale,
    required final double tx,
    required final double ty,
  }) {
    final matrix = Matrix4.diagonal3Values(scale, scale, 1);
    matrix.setTranslationRaw(tx, ty, 0);
    return matrix;
  }

  static double _clampAxisTranslation(
    final double translation, {
    required final double viewportExtent,
    required final double contentExtent,
  }) {
    if (contentExtent <= viewportExtent) {
      return (viewportExtent - contentExtent) / 2;
    }
    return translation.clamp(viewportExtent - contentExtent, 0.0).toDouble();
  }

  static double _matrixScale(final Matrix4 matrix) {
    final storage = matrix.storage;
    final scaleX = math.sqrt(storage[0] * storage[0] + storage[1] * storage[1]);
    final scaleY = math.sqrt(storage[4] * storage[4] + storage[5] * storage[5]);
    return math.max(scaleX, scaleY);
  }
}

VideoEditViewport computeVideoEditViewport({
  required final Size videoSize,
  required final int rotation,
  required final double maxWidth,
  final double maxHeight = 300,
  final double? targetAspect,
  final double maxScaleMultiplier = 8,
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
    videoAspect: orientedVideoSize.width / orientedVideoSize.height,
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
  required final double maxWidth,
  required final double maxHeight,
  required final double? targetAspect,
  required final double videoAspect,
  }) {
  final aspect = targetAspect ?? videoAspect;

  if (maxWidth / maxHeight > aspect) {
    final height = maxHeight;
    return Size(height * aspect, height);
  }

  final width = maxWidth;
  return Size(width, width / aspect);
  }

bool matrixCloseTo(final Matrix4 a, final Matrix4 b, {final double epsilon = 0.001}) {
  for (var i = 0; i < 16; i++) {
    if ((a.storage[i] - b.storage[i]).abs() > epsilon) {
      return false;
    }
  }
  return true;
}
