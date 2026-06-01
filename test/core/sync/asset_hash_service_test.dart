import 'dart:io';

import 'package:breakdex/core/sync/asset_hash_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AssetHashService hashService;

  setUp(() {
    hashService = AssetHashService();
  });

  group('AssetHashService', () {
    group('computeHash', () {
      test('returns 64-char lowercase hex string', () async {
        final dir = Directory.systemTemp.createTempSync('hash_test_');
        final file = File('${dir.path}/test_video.mp4');
        file.writeAsBytesSync(List.generate(1024, (final i) => i % 256));

        final hash = await hashService.computeHash(file.path);

        expect(hash.length, 64);
        expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));

        // Cleanup
        dir.deleteSync(recursive: true);
      });

      test('returns same hash for identical content', () async {
        final dir = Directory.systemTemp.createTempSync('hash_test_');
        final content = List.generate(2048, (final i) => i % 256);
        final file1 = File('${dir.path}/file1.mp4')
          ..writeAsBytesSync(content);
        final file2 = File('${dir.path}/file2.mp4')
          ..writeAsBytesSync(content);

        final hash1 = await hashService.computeHash(file1.path);
        final hash2 = await hashService.computeHash(file2.path);

        expect(hash1, equals(hash2));

        dir.deleteSync(recursive: true);
      });

      test('returns different hash for different content', () async {
        final dir = Directory.systemTemp.createTempSync('hash_test_');
        final file1 = File('${dir.path}/file1.mp4')
          ..writeAsBytesSync([1, 2, 3]);
        final file2 = File('${dir.path}/file2.mp4')
          ..writeAsBytesSync([4, 5, 6]);

        final hash1 = await hashService.computeHash(file1.path);
        final hash2 = await hashService.computeHash(file2.path);

        expect(hash1, isNot(equals(hash2)));

        dir.deleteSync(recursive: true);
      });

      test('handles empty file', () async {
        final dir = Directory.systemTemp.createTempSync('hash_test_');
        final file = File('${dir.path}/empty.mp4')..writeAsBytesSync([]);

        final hash = await hashService.computeHash(file.path);

        expect(hash.length, 64);
        expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));

        dir.deleteSync(recursive: true);
      });
    });

    group('verifyHash', () {
      test('returns true for matching hash', () async {
        final dir = Directory.systemTemp.createTempSync('hash_test_');
        final file = File('${dir.path}/test.mp4')
          ..writeAsBytesSync([10, 20, 30, 40]);

        final hash = await hashService.computeHash(file.path);
        final result = await hashService.verifyHash(file.path, hash);

        expect(result, isTrue);

        dir.deleteSync(recursive: true);
      });

      test('returns false for mismatched hash', () async {
        final dir = Directory.systemTemp.createTempSync('hash_test_');
        final file = File('${dir.path}/test.mp4')
          ..writeAsBytesSync([10, 20, 30, 40]);

        final result = await hashService.verifyHash(
          file.path,
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        );

        expect(result, isFalse);

        dir.deleteSync(recursive: true);
      });

      test('returns false for non-existent file', () async {
        final result = await hashService.verifyHash(
          '/tmp/does_not_exist_${DateTime.now().millisecondsSinceEpoch}.mp4',
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        );

        expect(result, isFalse);
      });
    });

    group('hashAll', () {
      test('emits progress for each file', () async {
        final dir = Directory.systemTemp.createTempSync('hash_test_');
        final files = List.generate(3, (final i) {
          final f = File('${dir.path}/file_$i.mp4');
          f.writeAsBytesSync(List.generate(100, (final j) => (i * 100 + j) % 256));
          return f.path;
        });

        final events = await hashService.hashAll(files).toList();

        expect(events.length, 3);
        expect(events[0].$1, 1); // completed
        expect(events[0].$2, 3); // total
        expect(events[0].$3, isNotNull); // hash
        expect(events[2].$1, 3);
        expect(events[2].$2, 3);

        dir.deleteSync(recursive: true);
      });

      test('yields null hash for missing files', () async {
        final events = await hashService.hashAll([
          '/tmp/nonexistent_${DateTime.now().millisecondsSinceEpoch}.mp4',
        ]).toList();

        expect(events.length, 1);
        expect(events[0].$1, 1);
        expect(events[0].$3, isNull);
      });
    });
  });
}
