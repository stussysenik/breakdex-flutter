import 'package:breakdex/core/services/native_video_album.dart';
import 'package:breakdex/core/services/native_video_preview.dart';
import 'package:breakdex/core/services/scene_3d.dart';
import 'package:breakdex/core/services/vision_ml.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const previewChannel = MethodChannel('com.breakdex/video_preview');
  const sceneChannel = MethodChannel('com.breakdex/scene_3d');
  const visionChannel = MethodChannel('com.breakdex/vision_ml');
  const albumChannel = MethodChannel('com.breakdex/video_album');

  final previewCalls = <MethodCall>[];
  final sceneCalls = <MethodCall>[];
  final visionCalls = <MethodCall>[];
  final albumCalls = <MethodCall>[];

  setUp(() {
    previewCalls.clear();
    sceneCalls.clear();
    visionCalls.clear();
    albumCalls.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(previewChannel, (call) async {
          previewCalls.add(call);
          return const <dynamic>[];
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sceneChannel, (call) async {
          sceneCalls.add(call);
          return true;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(visionChannel, (call) async {
          visionCalls.add(call);
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(albumChannel, (call) async {
          albumCalls.add(call);
          if (call.method == 'saveToAlbum') {
            return <String, dynamic>{
              'assetLocalIdentifier': 'asset-123',
              'filename': 'Airflare - Toprock.mov',
              'albumName': 'Breakdex 04-03-2026',
            };
          }
          if (call.method == 'requestReadAccess') {
            return 'authorized';
          }
          if (call.method == 'findMissingManagedAssets') {
            return <String, dynamic>{
              'accessStatus': 'authorized',
              'missingAssetLocalIdentifiers': ['asset-missing'],
            };
          }
          if (call.method == 'reconcileManagedAssets') {
            return <String, dynamic>{
              'accessStatus': 'authorized',
              'events': [
                <String, dynamic>{
                  'type': 'assetDeletedFromLibrary',
                  'assetLocalIdentifier': 'asset-123',
                  'moveId': 'move-1',
                  'albumName': 'Breakdex 04-03-2026',
                },
              ],
            };
          }
          if (call.method == 'discoverRecoverableManagedAssets') {
            return <String, dynamic>{
              'accessStatus': 'authorized',
              'assets': [
                <String, dynamic>{
                  'assetLocalIdentifier': 'asset-legacy',
                  'filename': 'Halo - Power.mov',
                  'albumName': 'Bboying Practice',
                },
              ],
            };
          }
          if (call.method == 'restoreManagedAsset') {
            return <String, dynamic>{
              'localPath': '/tmp/recovered.mov',
              'originalFileName': 'Recovered.mov',
            };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(previewChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sceneChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(visionChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(albumChannel, null);
  });

  group('Native bridge guardrails', () {
    test('video preview short-circuits empty path and empty times', () async {
      final service = NativeVideoPreview();

      final noPath = await service.generateThumbnails(
        videoPath: '   ',
        timesMs: const [0, 120],
        maxWidth: 0,
        quality: 200,
      );
      final noTimes = await service.generateThumbnails(
        videoPath: '/tmp/video.mp4',
        timesMs: const [],
        maxWidth: 80,
        quality: 50,
      );

      expect(noPath, [null, null]);
      expect(noTimes, isEmpty);
      expect(previewCalls, isEmpty);
    });

    test('video preview clamps args before channel call', () async {
      final service = NativeVideoPreview();

      await service.generateThumbnails(
        videoPath: ' /tmp/video.mp4 ',
        timesMs: const [0],
        maxWidth: 1,
        quality: 300,
        toleranceMs: -1,
      );

      final args = Map<String, dynamic>.from(
        previewCalls.single.arguments as Map,
      );
      expect(args['videoPath'], '/tmp/video.mp4');
      expect(args['maxWidth'], 2);
      expect(args['quality'], 100);
      expect(args['toleranceMs'], 0);
    });

    test('vision ml ignores empty image payloads', () async {
      final service = VisionML();

      final pose = await service.detectPose(Uint8List(0));
      final mask = await service.segmentPerson(Uint8List(0));

      expect(pose, isEmpty);
      expect(mask, isNull);
      expect(visionCalls, isEmpty);
    });

    test('scene 3d ignores empty model path and empty joints', () async {
      final service = Scene3D();

      final loaded = await service.loadModel('   ');
      await service.updateSkeleton(const []);

      expect(loaded, isFalse);
      expect(sceneCalls, isEmpty);
    });

    test('scene 3d omits null camera and lighting keys', () async {
      final service = Scene3D();

      await service.setCamera(x: 1, y: 2, z: 3);
      await service.setLighting(intensity: 500);

      final cameraArgs = Map<String, dynamic>.from(
        sceneCalls.first.arguments as Map,
      );
      final lightingArgs = Map<String, dynamic>.from(
        sceneCalls.last.arguments as Map,
      );
      expect(cameraArgs.containsKey('pitch'), isFalse);
      expect(cameraArgs.containsKey('yaw'), isFalse);
      expect(lightingArgs.containsKey('color'), isFalse);
    });

    test('video album ignores empty path and album name', () async {
      final service = NativeVideoAlbum();

      await service.saveToAlbum(videoPath: ' ', albumName: 'Breakdex');
      await service.saveToAlbum(videoPath: '/tmp/video.mp4', albumName: '   ');

      expect(albumCalls, isEmpty);
    });

    test('video album trims and filters optional fields', () async {
      final service = NativeVideoAlbum();

      final copy = await service.saveToAlbum(
        videoPath: ' /tmp/video.mp4 ',
        albumName: ' Breakdex Album ',
        assetTitle: ' Fixture Swipe ',
        category: ' ',
      );

      final args = Map<String, dynamic>.from(
        albumCalls.single.arguments as Map,
      );
      expect(args['videoPath'], '/tmp/video.mp4');
      expect(args['albumName'], 'Breakdex Album');
      expect(args['assetTitle'], 'Fixture Swipe');
      expect(args.containsKey('category'), isFalse);
      expect(copy?.assetLocalIdentifier, 'asset-123');
      expect(copy?.filename, 'Airflare - Toprock.mov');
      expect(copy?.albumName, 'Breakdex 04-03-2026');
    });

    test('video album normalizes delete cleanup arguments', () async {
      final service = NativeVideoAlbum();

      await service.deleteManagedCopies(
        assetTitle: ' Airflare ',
        category: ' Power ',
        fileExtension: ' .mov ',
        assetLocalIdentifier: ' asset-123 ',
      );

      final args = Map<String, dynamic>.from(
        albumCalls.single.arguments as Map,
      );
      expect(args['assetTitle'], 'Airflare');
      expect(args['category'], 'Power');
      expect(args['fileExtension'], 'mov');
      expect(args['assetLocalIdentifier'], 'asset-123');
    });

    test('video album derives deterministic semantic filenames', () {
      expect(
        NativeVideoAlbum.semanticFilename(
          assetTitle: 'Airflare/Freeze',
          category: 'Power*Set',
          fileExtension: '.mov',
        ),
        'Airflare-Freeze - Power-Set.mov',
      );
      expect(NativeVideoAlbum.semanticFilename(), 'Breakdex Clip.mp4');
    });

    test('video album parses read access and missing asset lookup', () async {
      final service = NativeVideoAlbum();

      final access = await service.requestReadAccess();
      final lookup = await service.findMissingManagedAssets([
        ' asset-missing ',
        '',
        'asset-missing',
      ]);

      expect(access, PhotoLibraryAccessStatus.authorized);
      final args = Map<String, dynamic>.from(albumCalls.last.arguments as Map);
      expect(args['assetLocalIdentifiers'], ['asset-missing']);
      expect(lookup.accessStatus, PhotoLibraryAccessStatus.authorized);
      expect(lookup.missingAssetLocalIdentifiers, ['asset-missing']);
    });

    test('video album parses reconcile payloads', () async {
      final service = NativeVideoAlbum();

      final result = await service.reconcileManagedAssets(const [
        ManagedAssetReference(
          moveId: ' move-1 ',
          assetLocalIdentifier: ' asset-123 ',
          albumName: ' Breakdex 04-03-2026 ',
        ),
      ], source: ' resume ');

      final args = Map<String, dynamic>.from(
        albumCalls.single.arguments as Map,
      );
      final trackedAssets = (args['trackedAssets'] as List)
          .map((value) => Map<String, dynamic>.from(value as Map))
          .toList();

      expect(args['source'], 'resume');
      expect(trackedAssets.single['moveId'], 'move-1');
      expect(trackedAssets.single['assetLocalIdentifier'], 'asset-123');
      expect(trackedAssets.single['albumName'], 'Breakdex 04-03-2026');
      expect(result.accessStatus, PhotoLibraryAccessStatus.authorized);
      expect(result.events, hasLength(1));
      expect(
        result.events.single.type,
        ManagedAssetReconcileEventType.assetDeletedFromLibrary,
      );
    });

    test('video album parses managed asset restore payloads', () async {
      final service = NativeVideoAlbum();

      final restored = await service.restoreManagedAsset(' asset-123 ');

      final args = Map<String, dynamic>.from(
        albumCalls.single.arguments as Map,
      );
      expect(args['assetLocalIdentifier'], 'asset-123');
      expect(restored?.localPath, '/tmp/recovered.mov');
      expect(restored?.originalFileName, 'Recovered.mov');
    });

    test(
      'video album passes regex filters for historical recovery scans',
      () async {
        final service = NativeVideoAlbum();

        final result = await service.discoverRecoverableManagedAssets(
          albumPatterns: [
            ' ${NativeVideoAlbum.historicalAlbumPatterns.first} ',
            '',
            r'\bb[\s\-_]*boy(?:ing)?\b ',
          ],
        );

        final args = Map<String, dynamic>.from(
          albumCalls.single.arguments as Map,
        );
        expect(args['albumPatterns'], [
          NativeVideoAlbum.historicalAlbumPatterns.first,
          r'\bb[\s\-_]*boy(?:ing)?\b',
        ]);
        expect(result.accessStatus, PhotoLibraryAccessStatus.authorized);
        expect(result.assets, hasLength(1));
        expect(result.assets.single.assetLocalIdentifier, 'asset-legacy');
        expect(result.assets.single.albumName, 'Bboying Practice');
      },
    );
  });
}
