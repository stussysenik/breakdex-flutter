import 'package:breakdex/core/platform/native_media.dart';
import 'package:breakdex/core/platform/web_support.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

/// Task 1.4 — URL-based playback seam. The web impl only compiles under the JS
/// environment (`video_player_web`), so under the VM the conditional import
/// resolves to the native impl; both route a URL source through
/// `VideoPlayerController.networkUrl`, which is web-capable via HTML <video>.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('networkVideoController builds a network-sourced controller', () {
    final controller = networkVideoController('https://x/y.mp4');
    // Constructing (not initializing) is plugin-free; the source type is set
    // eagerly — proving the seam wires a network, not a file, playback path.
    expect(controller.dataSourceType, DataSourceType.network);
    expect(controller.dataSource, 'https://x/y.mp4');
  });

  test('a URL source is a playable path on every platform incl. web', () {
    // Unlike supportsLocalVideoPlayback (false on web), URL playback is universal.
    expect(supportsUrlVideoPlayback, isTrue);
  });
}
