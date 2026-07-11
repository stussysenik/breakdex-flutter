import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

Widget nativeFileImage(
  final String path, {
  final BoxFit? fit,
  final FilterQuality filterQuality = FilterQuality.low,
  final bool gaplessPlayback = false,
  final ImageErrorWidgetBuilder? errorBuilder,
}) =>
    Image.file(
      File(path),
      fit: fit,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: errorBuilder,
    );

VideoPlayerController nativeFileVideoController(
  final String path, {
  final VideoPlayerOptions? videoPlayerOptions,
}) =>
    VideoPlayerController.file(File(path), videoPlayerOptions: videoPlayerOptions);
