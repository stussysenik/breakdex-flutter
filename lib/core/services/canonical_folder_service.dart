import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'app_storage_paths.dart';
import '../utils/filesystem_utils.dart';
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

  Future<String> canonicalPathForHash(String hash) async {
    final videos = await videosDir;
    // Nest by first 2 chars, then next 2 chars to avoid flat directory scaling issues.
    // e.g. videos/ab/cd/abcdef1234...mp4
    final p1 = hash.substring(0, 2);
    final p2 = hash.substring(2, 4);
    return p.join(videos.path, p1, p2, '$hash.mp4');
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

  Future<String> moveToCanonical(String sourcePath, String hash) async {
    await ensureInitialized();
    final targetPath = await canonicalPathForHash(hash);
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      try {
        await File(sourcePath).delete();
      } catch (_) {}
      await _pruneEmptyHashDirs(hash);
      return targetPath;
    }
    await targetFile.parent.create(recursive: true);
    await File(sourcePath).rename(targetPath);
    await _pruneEmptyParentDirs(targetPath);
    return targetPath;
  }

  Future<String> copyToCanonical(String sourcePath, String hash) async {
    await ensureInitialized();
    final targetPath = await canonicalPathForHash(hash);
    VideoStorageGate.guardWrite(targetPath);
    final targetFile = File(targetPath);
    if (await targetFile.exists()) return targetPath;
    await targetFile.parent.create(recursive: true);
    await File(sourcePath).copy(targetPath);
    await _pruneEmptyParentDirs(targetPath);
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

  Future<void> upsertLedgerEntry(LedgerEntry entry) async {
    final ledger = await readLedger();
    final updated = ledger.upsert(entry);
    await _writeLedger(updated);
  }

  Future<void> removeLedgerEntry(String hash) async {
    final ledger = await readLedger();
    final updated = ledger.remove(hash);
    await _writeLedger(updated);
    await _pruneEmptyHashDirs(hash);
  }

  Future<void> _writeLedger(Ledger ledger) async {
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

  void clearCache() {
    _cachedLedger = null;
  }

  /// Prune empty parent directories after a file is written to its hash path.
  /// Walks up from the file's parent checking for empty ancestor dirs.
  Future<void> _pruneEmptyParentDirs(String filePath) async {
    try {
      final docs = await AppStoragePaths.documentsDirectory();
      await FileSystemUtils.pruneEmptyParents(
        filePath,
        stopDir: p.join(docs.path, '.breakdex-master', 'videos'),
      );
    } catch (e) {
      debugPrint('[CanonicalFolderService] Prune failed: $e');
    }
  }

  /// Prune empty hash-nested directories (ab/cd/) after a file is removed
  /// or deduplicated away.
  Future<void> _pruneEmptyHashDirs(String hash) async {
    try {
      final videos = await videosDir;
      final p2 = hash.substring(2, 4);
      final p1 = hash.substring(0, 2);
      final leafDir = Directory(p.join(videos.path, p1, p2));
      if (await leafDir.exists()) {
        final entries = await leafDir.list().toList();
        if (entries.isEmpty) {
          await leafDir.delete();
          final parentDir = Directory(p.join(videos.path, p1));
          final parentEntries = await parentDir.list().toList();
          if (parentEntries.isEmpty) {
            await parentDir.delete();
          }
        }
      }
    } catch (_) {}
  }
}

class Ledger {
  final int version;
  final Map<String, LedgerEntry> entries;

  const Ledger({required this.entries, this.version = _ledgerVersion});

  factory Ledger.empty() => Ledger(entries: {});

  factory Ledger.fromJson(Map<String, dynamic> json) {
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
        'entries': entries.map((k, v) => MapEntry(k, v.toJson())),
      };

  Ledger upsert(LedgerEntry entry) {
    final updated = Map<String, LedgerEntry>.from(entries);
    updated[entry.fileName] = entry;
    return Ledger(entries: updated, version: version);
  }

  Ledger remove(String fileName) {
    final updated = Map<String, LedgerEntry>.from(entries);
    updated.remove(fileName);
    return Ledger(entries: updated, version: version);
  }

  bool contains(String fileName) => entries.containsKey(fileName);
  LedgerEntry? operator [](String fileName) => entries[fileName];

  @override
  bool operator ==(Object other) =>
      other is Ledger &&
      other.version == version &&
      _mapEquals(other.entries, entries);

  @override
  int get hashCode => Object.hash(version, Object.hashAll(entries.entries));
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
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

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
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
  bool operator ==(Object other) =>
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
