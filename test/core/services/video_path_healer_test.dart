// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/utils/app_clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../helpers/test_database.dart';

/// Controllable clock for testing the 24h staleness cutoff.
class _FixedClock implements AppClock {
  _FixedClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now.toUtc();

  @override
  Duration get monotonic => Duration.zero;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoPathHealer.pruneStaleExportDirs', () {
    late Directory tmpDir;
    late _FixedClock clock;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('healer_tmp_');
      clock = _FixedClock(DateTime.now());
      VideoPathHealer.clock = clock;
      VideoPathHealer.resetCounters();
    });

    tearDown(() async {
      VideoPathHealer.clock = SystemClock();
      if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
    });

    test('removes export dirs older than 24h; second run is a no-op', () async {
      final exportDir = Directory(p.join(tmpDir.path, 'export_stale'));
      await exportDir.create();
      await File(p.join(exportDir.path, 'clip.mp4')).writeAsString('data');

      // Advance the injected clock 25h past the directory's mtime.
      clock.now = DateTime.now().add(const Duration(hours: 25));

      final first = await VideoPathHealer.pruneStaleExportDirs(tempDir: tmpDir);
      expect(first, 1);
      expect(await exportDir.exists(), isFalse);
      expect(VideoPathHealer.staleFoldersRemoved, 1);

      final second = await VideoPathHealer.pruneStaleExportDirs(tempDir: tmpDir);
      expect(second, 0, reason: 'second run must be a no-op');
      expect(VideoPathHealer.staleFoldersRemoved, 1);
    });

    test('keeps export dirs younger than 24h', () async {
      final exportDir = Directory(p.join(tmpDir.path, 'export_fresh'));
      await exportDir.create();

      final removed = await VideoPathHealer.pruneStaleExportDirs(tempDir: tmpDir);
      expect(removed, 0);
      expect(await exportDir.exists(), isTrue);
    });

    test('ignores non-export directories regardless of age', () async {
      final otherDir = Directory(p.join(tmpDir.path, 'cache_dir'));
      await otherDir.create();
      clock.now = DateTime.now().add(const Duration(hours: 48));

      final removed = await VideoPathHealer.pruneStaleExportDirs(tempDir: tmpDir);
      expect(removed, 0);
      expect(await otherDir.exists(), isTrue);
    });
  });

  group('VideoPathHealer.pruneLegacyVideosDirectory', () {
    late Directory docsDir;
    late AppDatabase db;

    setUp(() async {
      docsDir = await Directory.systemTemp.createTemp('healer_docs_');
      VideoPathResolver.docsPathOverride = docsDir.path;
      db = createTestDatabase();
      VideoPathHealer.resetCounters();
    });

    tearDown(() async {
      await db.close();
      VideoPathResolver.docsPathOverride = '';
      if (await docsDir.exists()) await docsDir.delete(recursive: true);
    });

    test('migrates referenced legacy file to canonical path, prunes dir; '
        'second run is a no-op', () async {
      await db.movesDao.insertMove(
        MovesCompanion.insert(
          id: 'move-1',
          name: 'Airflare',
          category: const Value('Power'),
          videoPath: const Value('Moves/Power/Airflare - abc123.mp4'),
          originalVideoName: const Value('clip.mp4'),
        ),
      );

      final legacyDir = Directory(p.join(docsDir.path, 'videos'));
      await legacyDir.create(recursive: true);
      final legacyFile = File(p.join(legacyDir.path, 'clip.mp4'));
      await legacyFile.writeAsString('video-bytes');

      final first = await VideoPathHealer.pruneLegacyVideosDirectory(db);
      expect(first, 2, reason: '1 file migrated + 1 directory pruned');

      final canonical =
          File(p.join(docsDir.path, 'Moves', 'Power', 'Airflare - abc123.mp4'));
      expect(await canonical.exists(), isTrue);
      expect(await canonical.readAsString(), 'video-bytes');
      expect(await legacyDir.exists(), isFalse);
      expect(VideoPathHealer.staleFoldersRemoved, 1);

      final second = await VideoPathHealer.pruneLegacyVideosDirectory(db);
      expect(second, 0, reason: 'second run must be a no-op');
      expect(VideoPathHealer.staleFoldersRemoved, 1);
      expect(await canonical.exists(), isTrue);
    });

    test('leaves unreferenced legacy files in place (never deletes)', () async {
      final legacyDir = Directory(p.join(docsDir.path, 'videos'));
      await legacyDir.create(recursive: true);
      final unknown = File(p.join(legacyDir.path, 'unknown.mp4'));
      await unknown.writeAsString('mystery');

      final mutations = await VideoPathHealer.pruneLegacyVideosDirectory(db);
      expect(mutations, 0);
      expect(await unknown.exists(), isTrue);
      expect(await legacyDir.exists(), isTrue);
      expect(VideoPathHealer.staleFoldersRemoved, 0);
    });

    test('no legacy directory is a no-op', () async {
      final mutations = await VideoPathHealer.pruneLegacyVideosDirectory(db);
      expect(mutations, 0);
      expect(VideoPathHealer.staleFoldersRemoved, 0);
    });
  });
}
