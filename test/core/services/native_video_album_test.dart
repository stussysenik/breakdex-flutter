import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/services/native_video_album.dart';

void main() {
  group('NativeVideoAlbum.semanticFilename', () {
    test('matches the app-managed album naming scheme', () {
      expect(
        NativeVideoAlbum.semanticFilename(
          assetTitle: ' Airflare / Step ',
          category: 'Top_Rock',
          fileExtension: '.mov',
        ),
        'Airflare - Step - Top_Rock.mov',
      );
    });

    test('falls back to a default base name and extension', () {
      expect(
        NativeVideoAlbum.semanticFilename(
          assetTitle: '   ',
          category: null,
          fileExtension: null,
        ),
        'Breakdex Clip.mp4',
      );
    });
  });
}
