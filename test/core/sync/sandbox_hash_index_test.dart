import 'dart:io';

import 'package:breakdex/core/sync/asset_hash_service.dart';
import 'package:breakdex/core/sync/sandbox_hash_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory docs;
  final hasher = AssetHashService();

  setUp(() {
    docs = Directory.systemTemp.createTempSync('sandbox_index_test');
  });

  tearDown(() {
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  File writeVideo(final String relative, [final String bytes = 'video']) {
    final file = File(p.join(docs.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(bytes);
    return file;
  }

  group('sandboxHashToken', () {
    test('reads the full hash from a canonical-store filename', () {
      final full = 'a' * 64;
      expect(sandboxHashToken('$full.mp4'), full);
    });

    test('reads hash8 from a semantic filename', () {
      expect(sandboxHashToken('Air Flare - 69e13899.mov'), '69e13899');
    });

    test('takes the LAST separator so names containing " - " still parse', () {
      expect(sandboxHashToken('Baby - Freeze - 69e13899.mp4'), '69e13899');
    });

    // The widespread `split(' - ').last` idiom returns the whole basename when
    // there is no separator. An index keyed on that maps junk onto real paths,
    // and a junk key can only ever produce a wrong rescue.
    test('returns null rather than junk when no hash is embedded', () {
      expect(sandboxHashToken('IMG_4021.mov'), isNull);
      expect(sandboxHashToken('My Move.mp4'), isNull);
      expect(sandboxHashToken('Move - notahash.mp4'), isNull);
    });

    test('is case-insensitive on the hash', () {
      expect(sandboxHashToken('Move - 69E13899.MOV'), '69e13899');
    });
  });

  group('scan', () {
    test('indexes both Moves/ and Combos/ recursively', () async {
      writeVideo('Moves/Power moves/Air Flare - 69e13899.mov');
      writeVideo('Combos/Set 1/Opener - aabbccdd.mp4');

      final index = await SandboxHashIndex.scan(docs.path);

      expect(
        await index.resolve(
          '69e13899${'0' * 56}',
          documentsPath: docs.path,
          hasher: hasher,
        ),
        p.join('Moves', 'Power moves', 'Air Flare - 69e13899.mov'),
      );
      expect(
        await index.resolve(
          'aabbccdd${'0' * 56}',
          documentsPath: docs.path,
          hasher: hasher,
        ),
        p.join('Combos', 'Set 1', 'Opener - aabbccdd.mp4'),
      );
    });

    test('skips thumbnails and non-video files', () async {
      writeVideo('Moves/.thumbs/Air Flare - 69e13899.jpg');
      writeVideo('Moves/Air Flare - 69e13899.txt');

      final index = await SandboxHashIndex.scan(docs.path);

      expect(index.isEmpty, isTrue);
    });

    test('an absent sandbox is empty, not an error', () async {
      final index = await SandboxHashIndex.scan(docs.path);
      expect(index.isEmpty, isTrue);
    });
  });

  group('resolve', () {
    test('returns null when the bytes are genuinely gone', () async {
      writeVideo('Moves/Other - 11112222.mov');

      final index = await SandboxHashIndex.scan(docs.path);

      expect(
        await index.resolve(
          '69e13899${'0' * 56}',
          documentsPath: docs.path,
          hasher: hasher,
        ),
        isNull,
      );
    });

    test('prefers a full-hash filename over a hash8 match', () async {
      final full = await hasher.computeHash(
        writeVideo('Moves/Semantic - seed.mov', 'authoritative').path,
      );
      final short = full.substring(0, 8);
      writeVideo('Moves/$full.mp4', 'authoritative');
      writeVideo('Moves/Decoy - $short.mov', 'decoy');

      final index = await SandboxHashIndex.scan(docs.path);

      expect(
        await index.resolve(full, documentsPath: docs.path, hasher: hasher),
        p.join('Moves', '$full.mp4'),
      );
    });

    // hash8 is 8 hex digits, so two files CAN share one. Trusting the first
    // would hand the uploader the wrong bytes under the right hash — the one
    // failure mode a rescue lane must never have.
    test('verifies by full hash when two files share a hash8', () async {
      const realBytes = 'the real video bytes';
      final real = writeVideo('Moves/Real - seed.mov', realBytes);
      final full = await hasher.computeHash(real.path);
      final short = full.substring(0, 8);
      real.deleteSync();

      writeVideo('Moves/Collider - $short.mov', 'wrong bytes entirely');
      writeVideo('Moves/Power moves/Real - $short.mov', realBytes);

      final index = await SandboxHashIndex.scan(docs.path);

      expect(
        await index.resolve(full, documentsPath: docs.path, hasher: hasher),
        p.join('Moves', 'Power moves', 'Real - $short.mov'),
      );
    });

    test('returns null when every hash8 candidate fails verification',
        () async {
      final full = 'deadbeef${'0' * 56}';
      writeVideo('Moves/A - deadbeef.mov', 'not it');
      writeVideo('Moves/B - deadbeef.mov', 'also not it');

      final index = await SandboxHashIndex.scan(docs.path);

      expect(
        await index.resolve(full, documentsPath: docs.path, hasher: hasher),
        isNull,
      );
    });
  });
}
