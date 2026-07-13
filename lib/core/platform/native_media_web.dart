import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Web has no local-file media surface. Render a neutral placeholder in place
/// of a file thumbnail/photo (the permanent "no local file on web" state)...
Widget nativeFileImage(
  final String path, {
  final BoxFit? fit,
  final FilterQuality filterQuality = FilterQuality.low,
  final bool gaplessPlayback = false,
  final ImageErrorWidgetBuilder? errorBuilder,
}) =>
    const Center(child: Icon(Icons.image_not_supported_outlined, size: 20));

/// ...and fail loudly when something tries to play a local file, so the caller's
/// error handling shows the gap rather than silently doing nothing.
VideoPlayerController nativeFileVideoController(
  final String path, {
  final VideoPlayerOptions? videoPlayerOptions,
}) =>
    throw UnsupportedError(
      'Local-file video playback is unavailable on web (native-only feature).',
    );

/// A *URL* source is playable on web: `video_player_web` renders it into an HTML
/// `<video>` element. This is the one playback path that works on web, so it does
/// not throw. The URL itself (authenticated Drive media) is produced by the
/// `contentHash → Drive-media-URL` resolver, which rides Phase M (owner session).
VideoPlayerController nativeNetworkVideoController(
  final String url, {
  final VideoPlayerOptions? videoPlayerOptions,
}) =>
    VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: videoPlayerOptions,
    );
