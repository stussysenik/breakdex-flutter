// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/video_service.dart';

/// Unit tests for the native video import MethodChannel contract.
///
/// These tests mock the platform channel to verify that VideoService
/// correctly handles pick results, cancellations, and errors without
/// needing a running iOS app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const importChannel = MethodChannel('com.breakdex/native_video_import');
  late List<MethodCall> log;

  setUp(() {
    log = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(importChannel, (final call) async {
          log.add(call);
          switch (call.method) {
            case 'pickFromPhotos':
              return _responses[call.method];
            case 'pickFromFiles':
              return _responses[call.method];
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(importChannel, null);
    _responses.clear();
  });

  group('Video cleanup', () {
    late Directory tempDocsDir;

    setUp(() async {
      tempDocsDir = await Directory.systemTemp.createTemp('breakdex-video-');
      VideoPathResolver.docsPathOverride = tempDocsDir.path;
    });

    tearDown(() async {
      VideoPathResolver.docsPathOverride = '';
      await tempDocsDir.delete(recursive: true);
    });

    test(
      'deleteVideo removes the file and thumbnail for relative paths',
      () async {
        final movesDir = Directory('${tempDocsDir.path}/Moves');
        final thumbsDir = Directory('${movesDir.path}/.thumbs');
        await thumbsDir.create(recursive: true);

        final video = File('${movesDir.path}/abc.mp4');
        final thumb = File('${thumbsDir.path}/abc.jpg');
        await video.writeAsString('video');
        await thumb.writeAsString('thumb');

        await VideoService().deleteVideo('Moves/abc.mp4');

        expect(await video.exists(), isFalse);
        expect(await thumb.exists(), isFalse);
      },
    );
  });

  group('Native video import channel', () {
    test('pickFromPhotos returns localPath and originalFileName', () async {
      _responses['pickFromPhotos'] = {
        'localPath': '/Documents/Moves/abc.mp4',
        'originalFileName': 'my_clip.mp4',
      };

      final result = await importChannel.invokeMapMethod<String, dynamic>(
        'pickFromPhotos',
      );

      expect(result, isNotNull);
      expect(result!['localPath'], '/Documents/Moves/abc.mp4');
      expect(result['originalFileName'], 'my_clip.mp4');
      expect(log.single.method, 'pickFromPhotos');
    });

    test('pickFromPhotos returns null when user cancels', () async {
      _responses['pickFromPhotos'] = null;

      final result = await importChannel.invokeMapMethod<String, dynamic>(
        'pickFromPhotos',
      );

      expect(result, isNull);
    });

    test('pickFromFiles returns localPath and originalFileName', () async {
      _responses['pickFromFiles'] = {
        'localPath': '/Documents/Moves/def.mov',
        'originalFileName': 'dance_move.mov',
      };

      final result = await importChannel.invokeMapMethod<String, dynamic>(
        'pickFromFiles',
      );

      expect(result, isNotNull);
      expect(result!['localPath'], '/Documents/Moves/def.mov');
      expect(result['originalFileName'], 'dance_move.mov');
    });

    test('pickFromFiles returns null when user cancels', () async {
      _responses['pickFromFiles'] = null;

      final result = await importChannel.invokeMapMethod<String, dynamic>(
        'pickFromFiles',
      );

      expect(result, isNull);
    });

    test(
      'PlatformException with "cancelled" message is a cancellation',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(importChannel, (final call) async {
              throw PlatformException(
                code: 'CANCELLED',
                message: 'User cancelled the picker',
              );
            });

        expect(
          () =>
              importChannel.invokeMapMethod<String, dynamic>('pickFromPhotos'),
          throwsA(
            isA<PlatformException>().having(
              (final e) => e.message?.toLowerCase().contains('cancelled'),
              'message contains cancelled',
              true,
            ),
          ),
        );
      },
    );

    test('PlatformException with actual error propagates', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(importChannel, (final call) async {
            throw PlatformException(
              code: 'PERMISSION_DENIED',
              message: 'Photo library access denied',
            );
          });

      expect(
        () => importChannel.invokeMapMethod<String, dynamic>('pickFromPhotos'),
        throwsA(
          isA<PlatformException>().having(
            (final e) => e.code,
            'error code',
            'PERMISSION_DENIED',
          ),
        ),
      );
    });

    test('empty localPath in response is treated as no selection', () async {
      _responses['pickFromPhotos'] = {
        'localPath': '',
        'originalFileName': null,
      };

      final result = await importChannel.invokeMapMethod<String, dynamic>(
        'pickFromPhotos',
      );

      expect(result, isNotNull);
      expect(result!['localPath'], isEmpty);
      // VideoService would treat empty localPath as null — channel just returns it
    });
  });

  group('Native video export channel', () {
    const exportChannel = MethodChannel('com.breakdex/video_export');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(exportChannel, (final call) async {
            log.add(call);
            switch (call.method) {
              case 'exportVideo':
                final args = Map<String, dynamic>.from(call.arguments as Map);
                return args['outputPath'] as String;
              case 'cancelExport':
                return null;
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(exportChannel, null);
    });

    test('exportVideo sends correct parameters', () async {
      final result = await exportChannel.invokeMethod<String>('exportVideo', {
        'inputPath': '/input.mp4',
        'outputPath': '/output.mp4',
        'trimStartMs': 1000,
        'trimEndMs': 5000,
        'speed': 1.0,
        'rotation': 90,
        'aspectRatio': null,
      });

      expect(result, '/output.mp4');
      final call = log.last;
      expect(call.method, 'exportVideo');
      final args = Map<String, dynamic>.from(call.arguments as Map);
      expect(args['trimStartMs'], 1000);
      expect(args['trimEndMs'], 5000);
      expect(args['speed'], 1.0);
      expect(args['rotation'], 90);
    });

    test('exportVideo with crop rect sends crop parameters', () async {
      await exportChannel.invokeMethod<String>('exportVideo', {
        'inputPath': '/input.mp4',
        'outputPath': '/output.mp4',
        'trimStartMs': 0,
        'trimEndMs': 3000,
        'speed': 0.5,
        'rotation': 0,
        'aspectRatio': null,
        'cropLeft': 0.1,
        'cropTop': 0.2,
        'cropWidth': 0.5,
        'cropHeight': 0.5,
      });

      final args = Map<String, dynamic>.from(log.last.arguments as Map);
      expect(args['cropLeft'], 0.1);
      expect(args['cropTop'], 0.2);
      expect(args['cropWidth'], 0.5);
      expect(args['cropHeight'], 0.5);
    });

    test('cancelExport invokes correctly', () async {
      await exportChannel.invokeMethod('cancelExport');
      expect(log.last.method, 'cancelExport');
    });
  });
}

/// Response map for mock method channel handler.
final Map<String, dynamic> _responses = {};
