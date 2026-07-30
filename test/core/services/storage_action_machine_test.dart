// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';

import 'package:breakdex/core/models/canonical_path.dart';
import 'package:breakdex/core/services/storage_action_machine.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/sync/asset_hash_service.dart';

class _HashFailure implements Exception {
  const _HashFailure();
}

/// Fails the moment the machine asks for a hash, so `execute`'s catch runs.
class _ThrowingHashService extends AssetHashService {
  @override
  Stream<dynamic> computeHashWithProgress(final String filePath) =>
      Stream<dynamic>.error(const _HashFailure());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `StageLogger.fail` calls `debugPrintStack`, which asserts on the
  // stack_trace-formatted traces that propagate inside a plain `test()` body.
  // Without this hook the assertion REPLACES the error under test, so every
  // error path here would report `_AssertionError` instead of its cause.
  FlutterError.demangleStackTrace = (final StackTrace stack) => switch (stack) {
        final Trace t => t.vmTrace,
        final Chain c => c.toTrace().vmTrace,
        _ => stack,
      };

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

  // Teardown races: the machine's progress stream is a side channel, but a
  // closed controller used to make it load-bearing. `dispose()` closes it while
  // an action can still be suspended on an await, so the next `_emit` threw
  // `Bad state: Cannot add new events after calling close` — and the `catch` in
  // `execute` emitted onto that same closed controller, so the StateError
  // replaced the real error instead of rethrowing it. Progress is advisory;
  // losing it must never fail the transaction or hide a cause.
  group('StorageActionMachine after dispose', () {
    late Directory tempDir;
    late StorageActionMachine machine;
    late String sourceAbs;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('breakdex-storage-dispose');
      VideoPathResolver.docsPathOverride = tempDir.path;
      machine = StorageActionMachine(hashService: AssetHashService());

      sourceAbs = p.join(tempDir.path, 'Edits', 'source.mp4');
      await File(sourceAbs).parent.create(recursive: true);
      await File(sourceAbs).writeAsString('dummy-video-content');
    });

    tearDown(() async {
      VideoPathResolver.docsPathOverride = '';
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('materializing onto a closed progress stream still completes', () async {
      machine.dispose();

      final target = await machine.execute(MaterializeAction(
        sourcePath: sourceAbs,
        category: 'Power',
        moveName: 'Windmill',
      ));

      expect(target.value, matches(r'^Moves/Power/Windmill - [a-f0-9]+\.mp4$'));
      expect(await File(VideoPathResolver.toAbsolute(target.value)).exists(), isTrue,
          reason: 'the file move is the transaction; progress is advisory');
    });

    test('a real failure is rethrown, not masked by the closed stream', () async {
      // Faked rather than provoked with a bad path: a missing source makes the
      // hash isolate die without closing its port, so `_handleMaterialize`
      // hangs instead of throwing (recorded as a separate finding). This drives
      // the error path directly, which is the unit under test.
      final failing = StorageActionMachine(hashService: _ThrowingHashService())
        ..dispose();

      await expectLater(
        failing.execute(MaterializeAction(
          sourcePath: sourceAbs,
          category: 'Power',
          moveName: 'Windmill',
        )),
        throwsA(
          isA<_HashFailure>(),
          // Pre-fix this was a StateError from `execute`'s own progress emit,
          // so the cause never reached the caller.
        ),
      );
    });
  });
}
