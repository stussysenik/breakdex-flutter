import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/native_video_album.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/shared/widgets/metadata_video_picker_sheet.dart';

class _FakeVideoService extends VideoService {
  _FakeVideoService(this.assets);

  final List<MetadataAsset> assets;

  @override
  Stream<double> get importProgress => const Stream<double>.empty();

  @override
  Future<List<MetadataAsset>> fetchPhotoLibraryVideos({
    final int offset = 0,
    final int limit = 50,
  }) async =>
      offset == 0 ? assets : <MetadataAsset>[];

  @override
  Future<Uint8List?> getAssetThumbnail(
    final String identifier, {
    final int width = 200,
    final int height = 200,
  }) async =>
      null;

  @override
  Future<String?> generateThumbnail(
    final String videoPath, {
    final int maxWidth = VideoService.thumbnailWidthFull,
  }) async =>
      null;
}

class _FakeVideoAlbum extends NativeVideoAlbum {
  @override
  Future<RecoverableManagedAssetDiscoveryResult>
      discoverRecoverableManagedAssets({
    final List<String> albumPatterns = const <String>[],
  }) async =>
      RecoverableManagedAssetDiscoveryResult.empty();
}

MetadataAsset _asset(final String name) => MetadataAsset(
      localIdentifier: 'id-$name',
      originalFileName: name,
      duration: 5,
      width: 1080,
      height: 1920,
      creationDate: DateTime(2026, 6, 8),
    );

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('breakdex_picker_test');
    VideoPathResolver.docsPathOverride = tempDir.path;
  });

  tearDown(() {
    VideoPathResolver.docsPathOverride = '';
    tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpSheet(final WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoServiceProvider.overrideWithValue(
            _FakeVideoService([_asset('a.mov'), _asset('b.mov')]),
          ),
          nativeVideoAlbumProvider.overrideWithValue(_FakeVideoAlbum()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MetadataVideoPickerSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Scale of the selection check badge inside the tile showing [name]:
  /// 1.0 when selected, 0.0 when not.
  double badgeScale(final WidgetTester tester, final String name) {
    return tester
        .widget<AnimatedScale>(
          find.descendant(
            of: find
                .ancestor(
                  of: find.text(name),
                  matching: find.byType(GestureDetector),
                )
                .first,
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;
  }

  group('MetadataVideoPickerSheet selection', () {
    testWidgets('tapping a second tile moves the selection (single-select)',
        (final tester) async {
      await pumpSheet(tester);

      expect(find.text('a.mov'), findsOneWidget);
      expect(find.text('b.mov'), findsOneWidget);

      await tester.tap(find.text('a.mov'));
      await tester.pumpAndSettle();
      expect(badgeScale(tester, 'a.mov'), 1.0);
      expect(badgeScale(tester, 'b.mov'), 0.0);

      await tester.tap(find.text('b.mov'));
      await tester.pumpAndSettle();
      expect(badgeScale(tester, 'a.mov'), 0.0);
      expect(badgeScale(tester, 'b.mov'), 1.0);
    });

    testWidgets('action button reads IMPORT VIDEO once a tile is selected',
        (final tester) async {
      await pumpSheet(tester);

      expect(find.text('IMPORT VIDEO'), findsNothing);

      await tester.tap(find.text('a.mov'));
      await tester.pumpAndSettle();
      expect(find.text('IMPORT VIDEO'), findsOneWidget);

      // Moving the selection keeps the single-import label.
      await tester.tap(find.text('b.mov'));
      await tester.pumpAndSettle();
      expect(find.text('IMPORT VIDEO'), findsOneWidget);
    });
  });

  group('formatVideoFactsLine', () {
    test('duration, size, and date join in logical order', () {
      expect(
        formatVideoFactsLine(
          durationSeconds: 12,
          sizeBytes: 48 * 1024 * 1024,
          date: DateTime(2026, 6, 8),
        ),
        '0:12 · 48.0 MB · Jun 8',
      );
    });

    test('minutes roll over and large sizes drop the decimal', () {
      expect(
        formatVideoFactsLine(
          durationSeconds: 72,
          sizeBytes: 150 * 1024 * 1024,
          date: DateTime(2026, 12, 31),
        ),
        '1:12 · 150 MB · Dec 31',
      );
    });

    test('unknown size is omitted', () {
      expect(
        formatVideoFactsLine(
          durationSeconds: 12,
          sizeBytes: null,
          date: DateTime(2026, 6, 8),
        ),
        '0:12 · Jun 8',
      );
    });

    test('zero size is omitted, not rendered as 0', () {
      expect(
        formatVideoFactsLine(durationSeconds: 12, sizeBytes: 0, date: null),
        '0:12',
      );
    });

    test('unknown duration and date leave only the size', () {
      expect(
        formatVideoFactsLine(
          durationSeconds: 0,
          sizeBytes: 2 * 1024 * 1024,
          date: null,
        ),
        '2.0 MB',
      );
    });

    test('everything unknown renders an empty line', () {
      expect(
        formatVideoFactsLine(durationSeconds: 0, sizeBytes: null, date: null),
        '',
      );
    });
  });
}
