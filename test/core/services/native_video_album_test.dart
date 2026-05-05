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

  group('NativeVideoAlbum.breakdexAlbumPattern', () {
    final regex = NativeVideoAlbum.breakdexAlbumPattern;

    test('matches canonical Breakdex album names', () {
      expect(regex.hasMatch('Breakdex'), isTrue);
      expect(regex.hasMatch('breakdex'), isTrue);
      expect(regex.hasMatch('BREAKDEX'), isTrue);
      expect(regex.hasMatch('BreakDex'), isTrue);
      expect(regex.hasMatch('break dex'), isTrue);
      expect(regex.hasMatch('Break Dex'), isTrue);
    });

    test('matches dated album variants', () {
      expect(regex.hasMatch('Breakdex 05-05-2026'), isTrue);
      expect(regex.hasMatch('breakdex_03_07_2026'), isTrue);
      expect(regex.hasMatch('Break Dex 12-25-2025'), isTrue);
      expect(regex.hasMatch('breakdex-videos'), isTrue);
    });

    test('matches legacy naming patterns', () {
      expect(regex.hasMatch('breakin'), isTrue);
      expect(regex.hasMatch('BREAKING'), isTrue);
      expect(regex.hasMatch('BBoy'), isTrue);
      expect(regex.hasMatch('b boy'), isTrue);
      expect(regex.hasMatch('BGirl'), isTrue);
      expect(regex.hasMatch('b girl'), isTrue);
      expect(regex.hasMatch('breakdance'), isTrue);
      expect(regex.hasMatch('Break Dance'), isTrue);
    });

    test('does not match unrelated album names', () {
      expect(regex.hasMatch('Vacation 2024'), isFalse);
      expect(regex.hasMatch('Homework'), isFalse);
      expect(regex.hasMatch('Favorites'), isFalse);
      expect(regex.hasMatch('My Album'), isFalse);
    });

    test('matches substrings within longer album names', () {
      expect(regex.hasMatch('My Breakdex Clips'), isTrue);
      expect(regex.hasMatch('Best bboy moves'), isTrue);
      expect(regex.hasMatch('bgirl practice session'), isTrue);
    });
  });
}
