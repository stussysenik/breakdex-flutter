import 'package:breakdex/core/services/media_playback_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaPlaybackCoordinator', () {
    test('claiming a new primary pauses the previous owner', () {
      final coordinator = MediaPlaybackCoordinator();
      final paused = <String>[];

      coordinator.attach(
        playbackId: 'review-card',
        onPause: () => paused.add('review-card'),
      );
      coordinator.attach(
        playbackId: 'move-detail',
        onPause: () => paused.add('move-detail'),
      );

      coordinator.claimPrimary('review-card');
      coordinator.claimPrimary('move-detail');

      expect(paused, ['review-card']);
      expect(coordinator.isPrimary('move-detail'), isTrue);
    });

    test('releasing the primary clears ownership without pausing others', () {
      final coordinator = MediaPlaybackCoordinator();
      var pauseCount = 0;

      coordinator.attach(
        playbackId: 'editor',
        onPause: () => pauseCount += 1,
      );
      coordinator.claimPrimary('editor');

      coordinator.release('editor');

      expect(coordinator.isPrimary('editor'), isFalse);
      expect(pauseCount, 0);
    });

    test('pauseAll pauses every attached playback surface and clears primary', () {
      final coordinator = MediaPlaybackCoordinator();
      final paused = <String>[];

      coordinator.attach(playbackId: 'a', onPause: () => paused.add('a'));
      coordinator.attach(playbackId: 'b', onPause: () => paused.add('b'));
      coordinator.claimPrimary('a');

      coordinator.pauseAll();

      expect(paused, ['a', 'b']);
      expect(coordinator.isPrimary('a'), isFalse);
      expect(coordinator.isPrimary('b'), isFalse);
    });
  });
}
