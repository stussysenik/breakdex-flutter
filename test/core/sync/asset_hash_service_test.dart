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

    group('computeHashWithProgress', () {
      test(
        'a missing source ends the stream with an error, never hanging',
        () async {
          final absent =
              '${Directory.systemTemp.path}/breakdex-absent-source.mp4';
          expect(File(absent).existsSync(), isFalse);

          await expectLater(
            hashService.computeHashWithProgress(absent),
            emitsError(
              isA<HashIsolateFailure>()
                  .having((final e) => e.path, 'path', absent),
            ),
          );
        },
        // The pre-fix failure mode is an indefinite wait, so the deadline is
        // the assertion: without it this test hangs the runner instead of
        // reporting.
        timeout: const Timeout(Duration(seconds: 10)),
      );

      // Guards the rewritten loop rather than a defect: the error plumbing
      // added `onExit`/`onError` messages to the same port the data uses, so
      // the success path has to keep ending on the hash and nothing else.
      test('ends on the hash after streaming fractional progress', () async {
        final dir = Directory.systemTemp.createTempSync('hash_progress_');
        addTearDown(() => dir.deleteSync(recursive: true));
        final file = File('${dir.path}/video.mp4')
          ..writeAsBytesSync(List.generate(4096, (final i) => i % 256));

        final events =
            await hashService.computeHashWithProgress(file.path).toList();

        expect(events.last, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(events.last, await hashService.computeHash(file.path));
        expect(
          events.sublist(0, events.length - 1),
          everyElement(isA<double>()),
        );
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
  });
}
