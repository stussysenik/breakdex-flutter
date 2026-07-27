import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'package:breakdex/core/platform/native_media_native.dart'
    if (dart.library.js_interop) 'native_media_web.dart';

/// Local-file-backed media that only exists on native (`dart:io.File` +
/// `video_player`'s file constructor, AVFoundation-backed). On web these
/// degrade **visibly** per the web-release contract: [fileImage] renders a
/// neutral placeholder in place of a local thumbnail/photo, and
/// [fileVideoController] throws so the caller's error UI surfaces the gap —
/// never a silent no-op. Full web degradation of the video editor / media
/// affordances lives in tasks 1.3/1.4; this seam only keeps 1.0 web-compilable.
Widget fileImage(
  final String path, {
  final BoxFit? fit,
  final FilterQuality filterQuality = FilterQuality.low,
  final bool gaplessPlayback = false,
  final ImageErrorWidgetBuilder? errorBuilder,
}) =>
    nativeFileImage(
      path,
      fit: fit,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: errorBuilder,
    );

VideoPlayerController fileVideoController(
  final String path, {
  final VideoPlayerOptions? videoPlayerOptions,
}) =>
    nativeFileVideoController(path, videoPlayerOptions: videoPlayerOptions);

/// URL-backed playback that works on **every** platform, web included: a network
/// source routes through `video_player`'s HTML `<video>` backend on web and the
/// AVFoundation/ExoPlayer network path on native. This is the seam a Drive media
/// URL (authenticated) flows through so a released web build can actually play.
/// Resolving `contentHash → Drive-media-URL` and the live wiring ride Phase M
/// (owner Drive session); this seam only makes the playback path web-capable.
VideoPlayerController networkVideoController(
  final String url, {
  final VideoPlayerOptions? videoPlayerOptions,
}) =>
    nativeNetworkVideoController(url, videoPlayerOptions: videoPlayerOptions);
