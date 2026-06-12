import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../utils/diagnostics.dart';
import 'app_storage_paths.dart';
import 'video_storage_gate.dart';

const _markerFileName = '.breakdex-master';
const _ledgerFileName = '.breakdex-ledger.json';
const _ledgerVersion = 1;

class CanonicalFolderService {
  CanonicalFolderService();

  Ledger? _cachedLedger;

  Future<Directory> get _masterDir async {
    final docs = await AppStoragePaths.documentsDirectory();
    return Directory(p.join(docs.path, _markerFileName));
  }

  Future<Directory> get videosDir async {
    final master = await _masterDir;
    return Directory(p.join(master.path, 'videos'));
  }

  Future<bool> get exists async {
    final dir = await _masterDir;
    return dir.exists();
  }

  Future<Directory> ensureInitialized() async {
    final master = await _masterDir;
    if (!await master.exists()) {
      await master.create(recursive: true);
    }
    final markerFile = File(p.join(master.path, _markerFileName));
    if (!await markerFile.exists()) {
      await markerFile.writeAsString(
        'Breakdex canonical storage v1\n'
        'Created: ${DateTime.now().toIso8601String()}\n'
        'DO NOT DELETE — this directory is managed by Breakdex\n',
      );
    }
    final videos = await videosDir;
    if (!await videos.exists()) {
      await videos.create(recursive: true);
    }
    return master;
  }

  Future<bool> verify() async {
    try {
      final master = await _masterDir;
      if (!await master.exists()) return false;
      final markerFile = File(p.join(master.path, _markerFileName));
      return await markerFile.exists();
    } catch (_) {
      return false;
    }
  }

  Future<String> canonicalPathForHash(final String hash) async {
    final videos = await videosDir;
    return p.join(videos.path, '$hash.mp4');
  }

  Future<List<File>> listVideoFiles() async {
    final videos = await videosDir;
    if (!await videos.exists()) return [];
    final files = <File>[];
    await for (final entity in videos.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.mp4')) {
        files.add(entity);
      }
    }
    return files;
  }

  Future<String> moveToCanonical(final String sourcePath, final String hash) async {
    await ensureInitialized();
    final targetPath = await canonicalPathForHash(hash);
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      try {
        await File(sourcePath).delete();
      } catch (_) {}
      return targetPath;
    }
    VideoStorageGate.guardWrite(targetPath);
    await File(sourcePath).rename(targetPath);
    return targetPath;
  }

  Future<String> copyToCanonical(final String sourcePath, final String hash) async {
    await ensureInitialized();
    final targetPath = await canonicalPathForHash(hash);
    VideoStorageGate.guardWrite(targetPath);
    final targetFile = File(targetPath);
    if (await targetFile.exists()) return targetPath;
    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  Future<File> get _ledgerFile async {
    final master = await _masterDir;
    return File(p.join(master.path, _ledgerFileName));
  }

  Future<Ledger> readLedger() async {
    if (_cachedLedger != null) return _cachedLedger!;
    final file = await _ledgerFile;
    if (!await file.exists()) {
      _cachedLedger = Ledger.empty();
      return _cachedLedger!;
    }
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _cachedLedger = Ledger.fromJson(json);
      return _cachedLedger!;
    } catch (e) {
      debugPrint('[CanonicalFolderService] Ledger read failed: $e');
      _cachedLedger = Ledger.empty();
      return _cachedLedger!;
    }
  }

  Future<void> upsertLedgerEntry(final LedgerEntry entry) async {
    final ledger = await readLedger();
    final updated = ledger.upsert(entry);
    await _writeLedger(updated);
  }

  Future<void> removeLedgerEntry(final String hash) async {
    final ledger = await readLedger();
    final updated = ledger.remove(hash);
    await _writeLedger(updated);
  }

  Future<void> _writeLedger(final Ledger ledger) async {
    final file = await _ledgerFile;
    await file.writeAsString(jsonEncode(ledger.toJson()));
    _cachedLedger = ledger;
  }

  Future<Ledger> rebuildLedger() async {
    final videos = await videosDir;
    final entries = <String, LedgerEntry>{};
    final now = DateTime.now();
    if (await videos.exists()) {
      await for (final entity in videos.list(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.mp4')) continue;
        try {
          final stat = await entity.stat();
          final entry = LedgerEntry(
            fileName: p.basename(entity.path),
            fileSizeBytes: stat.size,
            lastSeenAt: stat.modified,
            recordedAt: now,
          );
          entries[entry.fileName] = entry;
        } catch (_) {}
      }
    }
    final ledger = Ledger(entries: entries, version: _ledgerVersion);
    await _writeLedger(ledger);
    return ledger;
  }

  Future<List<FileScanResult>> scanOrphans() async {
    final results = <FileScanResult>[];
    final videos = await videosDir;
    if (!await videos.exists()) return results;
    final ledger = await readLedger();
    await for (final entity in videos.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.mp4')) continue;
      final fileName = p.basename(entity.path);
      try {
        final stat = await entity.stat();
        results.add(FileScanResult(
          path: entity.path,
          fileName: fileName,
          fileSizeBytes: stat.size,
          modifiedAt: stat.modified,
          inLedger: ledger.entries.containsKey(fileName),
        ));
      } catch (_) {}
    }
    return results;
  }

  Future<int> pruneEmptyDirectories() async {
    var removed = 0;
    try {
      final videos = await videosDir;
      if (!await videos.exists()) return 0;
      removed = await _pruneEmptyRecursive(videos);
      if (removed > 0) {
        debugPrint('[CanonicalFolderService] Pruned $removed empty dir(s) in videos/');
      }
    } catch (e) {
      debugPrint('[CanonicalFolderService] Prune empty dirs failed: $e');
    }
    return removed;
  }

  Future<int> _pruneEmptyRecursive(final Directory dir) async {
    var removed = 0;
    try {
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          removed += await _pruneEmptyRecursive(entity);
        }
      }
      final entries = await dir.list().toList();
      if (entries.isEmpty) {
        await dir.delete();
        removed++;
      }
    } catch (_) {}
    return removed;
  }

  /// Moves unreferenced master files to `Moves/Archive/` (never hard-deletes).
  /// Returns count of files quarantined. Idempotent.
  Future<int> quarantineOrphans(final Set<String> referencedHashes) async {
    final log = StageLogger.begin('quarantineOrphans',
        subsystem: 'StorageHygiene');
    try {
      log.stage('scanning');
      final orphans = await scanOrphans();
      final orphanFiles = orphans.where((final o) => o.isOrphan).toList();
      if (orphanFiles.isEmpty) {
        log.complete('0 files to quarantine');
        return 0;
      }

      final docs = await AppStoragePaths.documentsDirectory();
      final archiveDir = Directory(p.join(docs.path, 'Moves', 'Archive'));
      if (!await archiveDir.exists()) {
        await archiveDir.create(recursive: true);
      }

      var count = 0;
      for (final orphan in orphanFiles) {
        log.stage('quarantining ${orphan.fileName}');
        final targetPath = p.join(archiveDir.path, orphan.fileName);
        try {
          if (await File(targetPath).exists()) {
            await File(orphan.path).delete();
            DiagnosticsLog.info('StorageHygiene',
                'Deleted duplicate orphan: ${orphan.fileName}');
          } else {
            await File(orphan.path).rename(targetPath);
            DiagnosticsLog.info('StorageHygiene',
                'Quarantined to Archive: ${orphan.fileName}');
          }
          count++;
        } catch (e) {
          DiagnosticsLog.error('StorageHygiene',
              'Failed to quarantine ${orphan.fileName}: $e');
        }
      }

      log.complete('quarantined $count file(s)');
      return count;
    } catch (e, stack) {
      log.fail(e, stack);
      return 0;
    }
  }

  void clearCache() {
    _cachedLedger = null;
  }

}

class Ledger {
  final int version;
  final Map<String, LedgerEntry> entries;

  const Ledger({required this.entries, this.version = _ledgerVersion});

  factory Ledger.empty() => const Ledger(entries: {});

  factory Ledger.fromJson(final Map<String, dynamic> json) {
    final entriesJson = json['entries'] as Map<String, dynamic>?;
    final entries = <String, LedgerEntry>{};
    if (entriesJson != null) {
      for (final entry in entriesJson.entries) {
        entries[entry.key] = LedgerEntry.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }
    return Ledger(
      version: json['version'] as int? ?? _ledgerVersion,
      entries: entries,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'entries': entries.map((final k, final v) => MapEntry(k, v.toJson())),
      };

  Ledger upsert(final LedgerEntry entry) {
    final updated = Map<String, LedgerEntry>.from(entries);
    updated[entry.fileName] = entry;
    return Ledger(entries: updated, version: version);
  }

  Ledger remove(final String fileName) {
    final updated = Map<String, LedgerEntry>.from(entries);
    updated.remove(fileName);
    return Ledger(entries: updated, version: version);
  }

  bool contains(final String fileName) => entries.containsKey(fileName);
  LedgerEntry? operator [](final String fileName) => entries[fileName];

  @override
  bool operator ==(final Object other) =>
      other is Ledger &&
      other.version == version &&
      _mapEquals(other.entries, entries);

  @override
  int get hashCode => Object.hash(version, Object.hashAll(entries.entries));
}

bool _mapEquals<K, V>(final Map<K, V> a, final Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

class LedgerEntry {
  final String fileName;
  final int fileSizeBytes;
  final DateTime lastSeenAt;
  final DateTime recordedAt;

  const LedgerEntry({
    required this.fileName,
    required this.fileSizeBytes,
    required this.lastSeenAt,
    required this.recordedAt,
  });

  factory LedgerEntry.fromJson(final Map<String, dynamic> json) => LedgerEntry(
        fileName: json['file'] as String,
        fileSizeBytes: json['size'] as int,
        lastSeenAt: DateTime.parse(json['seen'] as String),
        recordedAt: DateTime.parse(json['recorded'] as String),
      );

  Map<String, dynamic> toJson() => {
        'file': fileName,
        'size': fileSizeBytes,
        'seen': lastSeenAt.toIso8601String(),
        'recorded': recordedAt.toIso8601String(),
      };

  @override
  bool operator ==(final Object other) =>
      other is LedgerEntry &&
      other.fileName == fileName &&
      other.fileSizeBytes == fileSizeBytes;

  @override
  int get hashCode => Object.hash(fileName, fileSizeBytes);
}

class FileScanResult {
  final String path;
  final String fileName;
  final int fileSizeBytes;
  final DateTime modifiedAt;
  final bool inLedger;

  const FileScanResult({
    required this.path,
    required this.fileName,
    required this.fileSizeBytes,
    required this.modifiedAt,
    required this.inLedger,
  });

  bool get isOrphan => !inLedger;
}
