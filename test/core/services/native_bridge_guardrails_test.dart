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

      await service.saveToAlbum(
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
    });
  });
}
