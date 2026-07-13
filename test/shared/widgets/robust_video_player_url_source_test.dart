import 'package:breakdex/shared/widgets/video_player_widget.dart';
import 'package:flutter_test/flutter_test.dart';

/// Task 1.4 — both players accept an optional URL source that plays without a
/// local file (and thus without the dart:io file probe). These are pure
/// constructor/contract tests: a full mount would need the video plugin channel
/// and the settings providers, which the seam unit test already covers.
void main() {
  group('RobustVideoPlayer URL source', () {
    test('constructs from videoUrl alone, no videoPath required', () {
      expect(
        () => const RobustVideoPlayer(videoUrl: 'https://x/y.mp4'),
        returnsNormally,
      );
    });

    test('still constructs from a local videoPath alone (unchanged path)', () {
      expect(
        () => const RobustVideoPlayer(videoPath: 'clips/a.mp4'),
        returnsNormally,
      );
    });

    test('asserts when neither a videoPath nor a videoUrl is given', () {
      expect(() => RobustVideoPlayer(), throwsAssertionError);
    });
  });

  group('VideoPlayerWidget URL source', () {
    test('constructs from videoUrl alone', () {
      expect(
        () => const VideoPlayerWidget(videoUrl: 'https://x/y.mp4'),
        returnsNormally,
      );
    });

    test('asserts when neither a videoPath nor a videoUrl is given', () {
      expect(() => VideoPlayerWidget(), throwsAssertionError);
    });
  });
}
