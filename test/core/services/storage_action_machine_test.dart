// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:breakdex/core/models/canonical_path.dart';
import 'package:breakdex/core/services/storage_action_machine.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/sync/asset_hash_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageActionMachine.DuplicateAction', () {
    late Directory tempDir;
    late StorageActionMachine machine;
    late CanonicalPath sourceRelative;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('breakdex-storage-test');
      VideoPathResolver.docsPathOverride = tempDir.path;
      machine = StorageActionMachine(hashService: AssetHashService());

      // Seed a source video file under the Moves tree.
      sourceRelative = const CanonicalPath('Moves/Power/Windmill - source.mp4');
      final sourceAbs = VideoPathResolver.toAbsolute(sourceRelative.value);
      await File(sourceAbs).parent.create(recursive: true);
      await File(sourceAbs).writeAsString('hello');
    });

    tearDown(() async {
      machine.dispose();
      VideoPathResolver.docsPathOverride = '';
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('duplicating the same source repeatedly yields independent files', () async {
      // Three duplicates of identical bytes — the old code collided on the 2nd
      // (same hash → same path → clobber) and on the move PK. Each must now be
      // its own file.
      final copies = <CanonicalPath>[];
      for (var i = 0; i < 3; i++) {
        copies.add(await machine.execute(DuplicateAction(
          sourceRelative: sourceRelative,
          newName: 'Windmill (Copy)',
          category: 'Power',
        )));
      }

      // All paths distinct, all files present on disk.
      final paths = copies.map((final c) => c.value).toSet();
      expect(paths.length, 3, reason: 'each copy must be an independent file');
      for (final c in copies) {
        expect(await File(VideoPathResolver.toAbsolute(c.value)).exists(), isTrue);
      }

      // The shared content hash stays the LAST ` - ` segment so callers can
      // still recover it from the filename.
      String hashOf(final CanonicalPath c) =>
          p.basenameWithoutExtension(c.value).split(' - ').last;
      final hashes = copies.map(hashOf).toSet();
      expect(hashes.length, 1, reason: 'identical bytes → one shared hash');
    });
  });
}
