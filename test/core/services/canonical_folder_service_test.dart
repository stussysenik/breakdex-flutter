// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:breakdex/core/services/canonical_folder_service.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';

void main() {
  group('Ledger', () {
    test('fromJson round-trips correctly', () {
      final original = Ledger(entries: {
        'a.mp4': LedgerEntry(fileName: 'a.mp4', fileSizeBytes: 100,
            lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15)),
        'b.mp4': LedgerEntry(fileName: 'b.mp4', fileSizeBytes: 200,
            lastSeenAt: DateTime(2026, 1, 16), recordedAt: DateTime(2026, 1, 16)),
      });
      final restored = Ledger.fromJson(original.toJson());
      expect(restored.entries.length, 2);
      expect(restored['a.mp4']!.fileSizeBytes, 100);
      expect(restored['b.mp4']!.fileSizeBytes, 200);
    });

    test('upsert overwrites existing entry', () {
      final ledger = Ledger(entries: {
        'test.mp4': LedgerEntry(fileName: 'test.mp4', fileSizeBytes: 100,
            lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15)),
      });
      final updated = ledger.upsert(LedgerEntry(
          fileName: 'test.mp4', fileSizeBytes: 999,
          lastSeenAt: DateTime(2026, 1, 20), recordedAt: DateTime(2026, 1, 20)));
      expect(updated['test.mp4']!.fileSizeBytes, 999);
      expect(ledger['test.mp4']!.fileSizeBytes, 100);
    });

    test('remove returns new ledger without entry', () {
      final ledger = Ledger(entries: {
        'keep.mp4': LedgerEntry(fileName: 'keep.mp4', fileSizeBytes: 100,
            lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15)),
        'remove.mp4': LedgerEntry(fileName: 'remove.mp4', fileSizeBytes: 200,
            lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15)),
      });
      final result = ledger.remove('remove.mp4');
      expect(result.entries.length, 1);
      expect(result.contains('keep.mp4'), true);
      expect(result.contains('remove.mp4'), false);
    });

    test('empty ledger has no entries', () {
      final ledger = Ledger.empty();
      expect(ledger.entries, isEmpty);
      expect(ledger.version, 1);
    });

    test('contains returns correct membership', () {
      final ledger = Ledger(entries: {
        'found.mp4': LedgerEntry(fileName: 'found.mp4', fileSizeBytes: 100,
            lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15)),
      });
      expect(ledger.contains('found.mp4'), true);
      expect(ledger.contains('missing.mp4'), false);
    });

    test('operator [] returns entry by key', () {
      final ledger = Ledger(entries: {
        'file.mp4': LedgerEntry(fileName: 'file.mp4', fileSizeBytes: 300,
            lastSeenAt: DateTime(2026, 1, 20), recordedAt: DateTime(2026, 1, 20)),
      });
      expect(ledger['file.mp4']!.fileSizeBytes, 300);
      expect(ledger['missing.mp4'], isNull);
    });
  });

  group('FileScanResult', () {
    final testDate = DateTime(2026, 1, 15);
    test('isOrphan true when not in ledger', () {
      final r = FileScanResult(path: '/v.mp4', fileName: 'v.mp4',
          fileSizeBytes: 100, modifiedAt: testDate, inLedger: false);
      expect(r.isOrphan, true);
    });
    test('isOrphan false when in ledger', () {
      final r = FileScanResult(path: '/v.mp4', fileName: 'v.mp4',
          fileSizeBytes: 100, modifiedAt: testDate, inLedger: true);
      expect(r.isOrphan, false);
    });
  });

  group('quarantineOrphans', () {
    late Directory docsDir;
    late CanonicalFolderService service;

    Future<File> seedMaster(final String fileName, final String content) async {
      final videos = await service.videosDir;
      final file = File(p.join(videos.path, fileName));
      await file.writeAsString(content);
      return file;
    }

    setUp(() async {
      docsDir = await Directory.systemTemp.createTemp('canonical_docs_');
      service = CanonicalFolderService(docsDirOverride: docsDir);
      await service.ensureInitialized();
      VideoPathHealer.resetCounters();
    });

    tearDown(() async {
      if (await docsDir.exists()) await docsDir.delete(recursive: true);
    });

    test('moves unreferenced masters to Moves/Archive, keeps ledger- and '
        'hash-referenced files; second run is a no-op', () async {
      final inLedger = await seedMaster('aaa.mp4', 'ledger');
      final byHash = await seedMaster('bbb.mp4', 'manifest');
      final orphan = await seedMaster('ccc.mp4', 'orphan');

      await service.upsertLedgerEntry(LedgerEntry(
        fileName: 'aaa.mp4',
        fileSizeBytes: 6,
        lastSeenAt: DateTime(2026, 1, 15),
        recordedAt: DateTime(2026, 1, 15),
      ));

      final first = await service.quarantineOrphans({'bbb'});
      expect(first, 1);
      expect(await inLedger.exists(), isTrue);
      expect(await byHash.exists(), isTrue);
      expect(await orphan.exists(), isFalse);

      final archived =
          File(p.join(docsDir.path, 'Moves', 'Archive', 'ccc.mp4'));
      expect(await archived.exists(), isTrue);
      expect(await archived.readAsString(), 'orphan');
      expect(VideoPathHealer.orphansQuarantined, 1);

      final second = await service.quarantineOrphans({'bbb'});
      expect(second, 0, reason: 'second run must be a no-op');
      expect(VideoPathHealer.orphansQuarantined, 1);
      expect(await inLedger.exists(), isTrue);
      expect(await byHash.exists(), isTrue);
    });

    test('archive name collision suffixes instead of deleting', () async {
      await seedMaster('dup.mp4', 'NEW');
      final archiveDir =
          Directory(p.join(docsDir.path, 'Moves', 'Archive'));
      await archiveDir.create(recursive: true);
      final preExisting = File(p.join(archiveDir.path, 'dup.mp4'));
      await preExisting.writeAsString('OLD');

      final count = await service.quarantineOrphans({});
      expect(count, 1);

      // Both copies survive: the pre-existing archive file untouched, the
      // orphan moved under a suffixed name — nothing deleted.
      expect(await preExisting.readAsString(), 'OLD');
      final archiveFiles = await archiveDir
          .list()
          .where((final e) => e is File)
          .toList();
      expect(archiveFiles.length, 2);
      final suffixed = archiveFiles
          .map((final e) => e.path)
          .firstWhere((final path) => p.basename(path) != 'dup.mp4');
      expect(await File(suffixed).readAsString(), 'NEW');
    });

    test('clean master is a no-op with zero counters', () async {
      await seedMaster('eee.mp4', 'kept');
      await service.upsertLedgerEntry(LedgerEntry(
        fileName: 'eee.mp4',
        fileSizeBytes: 4,
        lastSeenAt: DateTime(2026, 1, 15),
        recordedAt: DateTime(2026, 1, 15),
      ));

      final count = await service.quarantineOrphans({});
      expect(count, 0);
      expect(VideoPathHealer.orphansQuarantined, 0);
    });
  });

  group('LedgerEntry', () {
    test('fromJson correctly parses all fields', () {
      final entry = LedgerEntry.fromJson({
        'file': 'test.mp4', 'size': 500,
        'seen': '2026-01-15T10:00:00.000', 'recorded': '2026-01-15T11:00:00.000',
      });
      expect(entry.fileName, 'test.mp4');
      expect(entry.fileSizeBytes, 500);
      expect(entry.lastSeenAt, DateTime(2026, 1, 15, 10, 0, 0));
      expect(entry.recordedAt, DateTime(2026, 1, 15, 11, 0, 0));
    });

    test('equality compares fileName and fileSizeBytes only', () {
      final a = LedgerEntry(fileName: 'same.mp4', fileSizeBytes: 100,
          lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15));
      final b = LedgerEntry(fileName: 'same.mp4', fileSizeBytes: 100,
          lastSeenAt: DateTime(2026, 1, 16), recordedAt: DateTime(2026, 1, 16));
      expect(a, equals(b));
    });
  });
}
