import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';
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
  _FakeVideoAlbum([this.managed = const <RecoverableManagedAsset>[]]);

  final List<RecoverableManagedAsset> managed;

  @override
  Future<RecoverableManagedAssetDiscoveryResult>
      discoverRecoverableManagedAssets({
    final List<String> albumPatterns = const <String>[],
  }) async =>
          managed.isEmpty
              ? RecoverableManagedAssetDiscoveryResult.empty()
              : RecoverableManagedAssetDiscoveryResult(
                  accessStatus: PhotoLibraryAccessStatus.authorized,
                  assets: managed,
                );
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
  late AppDatabase db;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('breakdex_picker_test');
    VideoPathResolver.docsPathOverride = tempDir.path;
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    VideoPathResolver.docsPathOverride = '';
    tempDir.deleteSync(recursive: true);
    await db.close();
  });

  // The picker's load does real file I/O and DB reads, and shows an
  // indeterminate progress indicator meanwhile — so `pumpAndSettle` never idles
  // on this Flutter version, and plain pumps don't advance the real async.
  // Interleave `runAsync` (drains real I/O/DB futures) with pumps (flush the
  // resulting rebuilds).
  Future<void> settle(final WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      // Advance fake time so implicit animations (button slide, tab swap) finish
      // and leave no pending timers at teardown.
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> pumpSheet(
    final WidgetTester tester, {
    final List<MetadataAsset> library = const <MetadataAsset>[],
    final List<RecoverableManagedAsset> managed =
        const <RecoverableManagedAsset>[],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          videoServiceProvider.overrideWithValue(_FakeVideoService(library)),
          nativeVideoAlbumProvider.overrideWithValue(_FakeVideoAlbum(managed)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MetadataVideoPickerSheet()),
        ),
      ),
    );
    await settle(tester);
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
      await pumpSheet(tester, library: [_asset('a.mov'), _asset('b.mov')]);

      expect(find.text('a.mov'), findsOneWidget);
      expect(find.text('b.mov'), findsOneWidget);

      await tester.tap(find.text('a.mov'));
      await settle(tester);
      expect(badgeScale(tester, 'a.mov'), 1.0);
      expect(badgeScale(tester, 'b.mov'), 0.0);

      await tester.tap(find.text('b.mov'));
      await settle(tester);
      expect(badgeScale(tester, 'a.mov'), 0.0);
      expect(badgeScale(tester, 'b.mov'), 1.0);
    });

    testWidgets('action button reads IMPORT VIDEO once a tile is selected',
        (final tester) async {
      await pumpSheet(tester, library: [_asset('a.mov'), _asset('b.mov')]);

      expect(find.text('IMPORT VIDEO'), findsNothing);

      await tester.tap(find.text('a.mov'));
      await settle(tester);
      expect(find.text('IMPORT VIDEO'), findsOneWidget);

      // Moving the selection keeps the single-import label.
      await tester.tap(find.text('b.mov'));
      await settle(tester);
      expect(find.text('IMPORT VIDEO'), findsOneWidget);
    });
  });

  group('MetadataVideoPickerSheet membership', () {
    testWidgets('a managed asset already a move is marked, and importing it '
        'offers open-existing vs import-again', (final tester) async {
      await db.movesDao.insertMove(
        const MovesCompanion(
          id: Value('m1'),
          name: Value('Windmill'),
          managedAlbumAssetId: Value('managed-1'),
        ),
      );

      await pumpSheet(
        tester,
        managed: const [
          RecoverableManagedAsset(
            assetLocalIdentifier: 'managed-1',
            filename: 'clip.mov',
            albumName: 'Breakdex',
          ),
        ],
      );

      // Move to the Video Library (managed) tab.
      await tester.tap(find.text('VIDEO LIBRARY'));
      await settle(tester);

      expect(find.text('clip.mov'), findsOneWidget);
      // Slot 4 — the already-in-Breakdex mark resolved from the index.
      expect(_alreadyInBreakdexMark, findsOneWidget);

      // Selecting + importing the member never imports silently.
      await tester.tap(find.text('clip.mov'));
      await settle(tester);
      await tester.tap(find.text('IMPORT VIDEO'));
      await settle(tester);

      expect(find.text('Open existing move'), findsOneWidget);
      expect(find.text('Import again'), findsOneWidget);
    });

    testWidgets('a photo-library asset with no matching move is not marked',
        (final tester) async {
      await db.movesDao.insertMove(
        const MovesCompanion(
          id: Value('m1'),
          name: Value('Windmill'),
          managedAlbumAssetId: Value('managed-1'),
        ),
      );

      await pumpSheet(tester, library: [_asset('a.mov')]);

      expect(find.text('a.mov'), findsOneWidget);
      // id-a.mov never equals the managed id, and camera-roll has no hash —
      // an honest miss.
      expect(_alreadyInBreakdexMark, findsNothing);
    });
  });

  group('MoveMembershipIndex', () {
    final managedAsset = MetadataAsset(
      localIdentifier: 'managed-1',
      originalFileName: 'clip.mov',
      duration: 0,
      width: 0,
      height: 0,
    );
    final photoAsset = MetadataAsset(
      localIdentifier: 'ph-99',
      originalFileName: 'IMG_0001.mov',
      duration: 5,
      width: 0,
      height: 0,
    );

    const index = MoveMembershipIndex(
      moveIdByManagedAssetId: {'managed-1': 'm1'},
      moveIdByContentHash: {'deadbeef': 'm2'},
    );

    test('managed-album id matches its owning move', () {
      expect(index.memberMoveId(managedAsset), 'm1');
    });

    test('content hash matches when supplied for a local file', () {
      expect(index.memberMoveId(photoAsset, contentHash: 'deadbeef'), 'm2');
    });

    test('photo-library asset without a hash is an honest miss', () {
      expect(index.memberMoveId(photoAsset), isNull);
    });

    test('unknown hash misses', () {
      expect(index.memberMoveId(photoAsset, contentHash: 'nope'), isNull);
    });
  });

  group('tile fact formatting', () {
    test('duration badge is mm:ss and rolls minutes over', () {
      expect(formatDurationBadge(12), '0:12');
      expect(formatDurationBadge(72), '1:12');
    });

    test('unknown duration omits the badge', () {
      expect(formatDurationBadge(0), '');
    });

    test('secondary fact prefers size, dropping the decimal past 100 MB', () {
      expect(
        formatTileSecondaryFact(sizeBytes: 48 * 1024 * 1024, date: DateTime(2026, 6, 8)),
        '48.0 MB',
      );
      expect(
        formatTileSecondaryFact(sizeBytes: 150 * 1024 * 1024),
        '150 MB',
      );
    });

    test('falls back to date when size is unknown', () {
      expect(
        formatTileSecondaryFact(sizeBytes: null, date: DateTime(2026, 6, 8)),
        'Jun 8',
      );
      expect(
        formatTileSecondaryFact(sizeBytes: 0, date: DateTime(2026, 12, 31)),
        'Dec 31',
      );
    });

    test('one fact at most — never both, empty when neither is known', () {
      expect(formatTileSecondaryFact(), '');
    });
  });
}

/// The membership mark is the tile's "Already in Breakdex" badge.
///
/// Matched by its semantics label, not by icon: the badge and the selection
/// tick both render [AppIcon.check], so an icon finder cannot tell them apart.
final Finder _alreadyInBreakdexMark = find.byWidgetPredicate(
  (final widget) =>
      widget is Semantics && widget.properties.label == 'Already in Breakdex',
  description: 'the "Already in Breakdex" membership mark',
);
