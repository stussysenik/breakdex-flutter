import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../models/canonical_path.dart';
import '../utils/filesystem_utils.dart';
import '../utils/diagnostics.dart';
import 'app_storage_paths.dart';

String _sanitizeFilename(final String name) {
  return name
      .replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-')
      .trim();
}

/// Resolves video paths between relative (DB) and absolute (file system) forms.
///
/// iOS changes the container UUID on every reinstall/update, which breaks
/// absolute paths stored in the database. This utility stores paths as relative
/// (`Moves/Category/Name - Hash.mp4`) and resolves them to the current container at runtime.
abstract final class VideoPathResolver {
  static String _docsPath = '';

  /// Cache the current documents directory path. Must be called once at
  /// startup before any path operations are used.
  static Future<void> initialize() async {
    final dir = await AppStoragePaths.documentsDirectory();
    _docsPath = dir.path;
    if (_docsPath.endsWith('/')) {
      _docsPath = _docsPath.substring(0, _docsPath.length - 1);
    }
  }

  @visibleForTesting
  static set docsPathOverride(final String path) => _docsPath = path;

  static String get documentsPath => _docsPath;

  static bool isRelative(final String path) => !path.startsWith('/');

  /// Convert an absolute path to a relative [CanonicalPath].
  static CanonicalPath toRelative(final String path) {
    assert(_docsPath.isNotEmpty, 'VideoPathResolver.initialize() not called');
    if (!path.startsWith('/')) return CanonicalPath(path);

    if (path.startsWith(_docsPath)) {
      final relative = path.substring(_docsPath.length);
      return CanonicalPath(relative.startsWith('/') ? relative.substring(1) : relative);
    }

    const marker = '/Documents/';
    final markerIndex = path.indexOf(marker);
    if (markerIndex >= 0) {
      return CanonicalPath(path.substring(markerIndex + marker.length));
    }

    final movesMarker = '${p.separator}Moves${p.separator}';
    final movesIndex = path.indexOf(movesMarker);
    if (movesIndex >= 0) {
      return CanonicalPath(path.substring(movesIndex + 1));
    }

    return CanonicalPath('Moves/${p.basename(path)}');
  }

  /// Convert a [CanonicalPath] or raw relative path to an absolute string.
  static String toAbsolute(final String path) {
    assert(_docsPath.isNotEmpty, 'VideoPathResolver.initialize() not called');
    if (!path.startsWith('/')) return '$_docsPath/$path';
    if (path.startsWith(_docsPath)) return path;

    const marker = '/Documents/';
    final markerIndex = path.indexOf(marker);
    if (markerIndex >= 0) {
      return '$_docsPath/${path.substring(markerIndex + marker.length)}';
    }

    return path;
  }

  /// Last-resort fallback: If the stored relative path is missing, scan the
  /// filesystem for the filename in common locations.
  static Future<String?> resolve(final String relativePath) async {
    // 1. Check if it's already absolute and exists
    if (!isRelative(relativePath) && await File(relativePath).exists()) {
      return relativePath;
    }

    // 2. Try the "correct" absolute path
    final correctAbs = toAbsolute(relativePath);
    if (await File(correctAbs).exists()) return correctAbs;

    // 3. Fallback: Scan by filename
    final filename = p.basename(relativePath);

    // a. Check in 'videos/' (cloud download folder)
    final videosDir = p.join(_docsPath, 'videos');
    final inVideos = p.join(videosDir, filename);
    if (await File(inVideos).exists()) return inVideos;

    // b. Recursive search in Moves/ (can be slow, but this is last resort)
    final movesRoot = p.join(_docsPath, 'Moves');
    final movesDir = Directory(movesRoot);
    if (await movesDir.exists()) {
      await for (final entity in movesDir.list(recursive: true)) {
        if (entity is File && p.basename(entity.path) == filename) {
          return entity.path;
        }
      }
    }

    return null;
  }

  /// Deterministic path generation: `Moves/{Category}/{Name} - {Hash}.{ext}`.
  static CanonicalPath semanticVideoPath(
    final String category,
    final String moveName,
    final String extension, {
    required final ContentHash contentHash,
  }) {
    final safeCategory = getSafeCategory(category);
    final safeName = _sanitizeFilename(moveName);
    final shortHash = contentHash.short;

    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    // Standardize on Flat files within Category folders for human readability
    return CanonicalPath(p.join('Moves', safeCategory, '$safeName - $shortHash.${ext.toLowerCase()}'));
  }

  static String getSafeCategory(final String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return 'Default';

    final lower = trimmed.toLowerCase();
    if (['default', 'none', 'uncategorized', 'general'].contains(lower)) {
      return 'Default';
    }

    final sanitized = _sanitizeFilename(trimmed);
    if (sanitized.length <= 1) return sanitized.toUpperCase();
    return sanitized[0].toUpperCase() + sanitized.substring(1).toLowerCase();
  }

  /// Central materialization logic: Moves a file to its canonical location.
  static Future<CanonicalPath> moveToSemanticPath({
    required final String currentRelativePath,
    required final String category,
    required final String moveName,
    required final ContentHash contentHash,
  }) async {
    final sourceAbs = toAbsolute(currentRelativePath);
    final sourceFile = File(sourceAbs);

    if (!await sourceFile.exists()) {
      DiagnosticsLog.warn('VideoPathResolver', 'Source not found: $sourceAbs');
      return toRelative(currentRelativePath);
    }

    final ext = p.extension(currentRelativePath).isNotEmpty
        ? p.extension(currentRelativePath)
        : '.mp4';
    
    final newRelative = semanticVideoPath(category, moveName, ext, contentHash: contentHash);
    final newAbs = toAbsolute(newRelative.value);

    if (sourceAbs == newAbs) return newRelative;

    final newDir = Directory(p.dirname(newAbs));
    if (!await newDir.exists()) await newDir.create(recursive: true);

    try {
      await FileSystemUtils.safeMove(sourceAbs, newAbs);
      DiagnosticsLog.info('VideoPathResolver', '[MATERIALIZE] $sourceAbs → $newAbs');
      
      await FileSystemUtils.pruneEmptyParents(sourceAbs, stopDir: p.join(_docsPath, 'Moves'));
      return newRelative;
    } catch (e) {
      DiagnosticsLog.error('VideoPathResolver', 'Materialization failed: $e');
      rethrow;
    }
  }
}

/// One-time batch migration that converts stored absolute video paths to
/// relative form and ensures all files follow the semantic naming structure.
///
/// Gated by SharedPreferences so it only runs once.
abstract final class VideoPathHealer {
  static const _prefsKey = 'video_paths_healed_v3';
  static const _cleanupRunAtKey = 'video_paths_cleanup_run_at';

  /// Proactive healing of both the database records and physical filesystem.
  ///
  /// Filesystem cleanup is deferred to run at most once every 24 hours to avoid
  /// blocking app startup with expensive directory scans on every boot.
  static Future<void> healAll(final AppDatabase db, final SharedPreferences prefs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastCleanup = prefs.getInt(_cleanupRunAtKey) ?? 0;
    final hoursSinceCleanup =
        (now - lastCleanup) / (1000 * 60 * 60);

    if (hoursSinceCleanup >= 24 || lastCleanup == 0) {
      try {
        await _autoCleanFileSystem(db);
        await prefs.setInt(_cleanupRunAtKey, now);
      } catch (e) {
        debugPrint('[VideoPathHealer] Cleanup failed: $e');
      }
    }

    if (prefs.getBool(_prefsKey) != true) {
      try {
        await _healDatabasePaths(db);
        await prefs.setBool(_prefsKey, true);
      } catch (e) {
        debugPrint('[VideoPathHealer] DB healing failed: $e');
      }
    }
  }

  /// Automatically cleans up the root directory and Move folder orphans.
  /// This is the primary mechanism for enforcing a clean Files app view.
  static Future<void> _autoCleanFileSystem(final AppDatabase db) async {
    await _cleanupRootBackups();
    await _cleanupMovesOrphans(db);
    await _mergeDuplicateFolders();
    await _pruneEmptyMovesDirectories();
  }

  /// Proactively find and merge folders that differ only by casing.
  /// (e.g., merge 'default' -> 'Default')
  static Future<void> _mergeDuplicateFolders() async {
    try {
      final rootMoves = p.join(VideoPathResolver.toAbsolute(''), 'Moves');
      final directory = Directory(rootMoves);
      if (!await directory.exists()) return;

      final Map<String, String> seenLower = {};
      
      await for (final entity in directory.list()) {
        if (entity is! Directory) continue;
        final name = p.basename(entity.path);
        final lower = name.toLowerCase();
        
        // Determine the canonical name for this category
        String canonical;
        if (lower == 'default' || lower == 'none' || lower == 'uncategorized' || lower == 'general') {
          canonical = 'Default';
        } else {
          canonical = name.length > 1 
            ? name[0].toUpperCase() + name.substring(1).toLowerCase()
            : name.toUpperCase();
        }

        if (seenLower.containsKey(lower)) {
          // If we've seen this name (case-insensitive) before, merge into the first one or canonical
          final target = seenLower[lower]!;
          if (name != target) {
            debugPrint('[VideoPathHealer] Boot merge: $name -> $target');
            await _mergeDirectories(entity, Directory(p.join(rootMoves, target)));
          }
        } else {
          // If the folder name itself isn't canonical, rename it
          if (name != canonical) {
            debugPrint('[VideoPathHealer] Boot normalize: $name -> $canonical');
            await _mergeDirectories(entity, Directory(p.join(rootMoves, canonical)));
            seenLower[lower] = canonical;
          } else {
            seenLower[lower] = name;
          }
        }
      }
    } catch (e) {
      debugPrint('[VideoPathHealer] Boot merge failed: $e');
    }
  }

  static Future<void> _mergeDirectories(final Directory source, final Directory target) async {
    if (!await target.exists()) await target.create(recursive: true);
    await for (final entity in source.list()) {
      final name = p.basename(entity.path);
      final destPath = p.join(target.path, name);
      if (entity is File) {
        // Collision strategy: If target exists, keep source but suffix it to avoid data loss
        String finalDest = destPath;
        if (await File(destPath).exists()) {
          final ext = p.extension(destPath);
          final base = p.basenameWithoutExtension(destPath);
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          finalDest = p.join(target.path, '${base}_healed_$timestamp$ext');
        }
        await FileSystemUtils.safeMove(entity.path, finalDest);
      } else if (entity is Directory) {
        await _mergeDirectories(entity, Directory(destPath));
      }
    }
    try {
      await source.delete();
    } catch (_) {}
  }

  /// Recursively walk the Moves/ directory tree and delete any empty
  /// subdirectories. Runs after orphan cleanup and folder merging to ensure
  /// no ghost directories accumulate.
  static Future<void> _pruneEmptyMovesDirectories() async {
    try {
      final movesPath = p.join(VideoPathResolver.toAbsolute(''), 'Moves');
      final movesDir = Directory(movesPath);
      if (!await movesDir.exists()) return;

      final removed = await _pruneEmptyRecursive(movesDir);
      if (removed > 0) {
        debugPrint('[VideoPathHealer] Pruned $removed empty dir(s) in Moves/');
      }
    } catch (e) {
      debugPrint('[VideoPathHealer] Prune empty dirs failed: $e');
    }
  }

  static Future<int> _pruneEmptyRecursive(final Directory dir) async {
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

  static Future<void> _cleanupRootBackups() async {
    try {
      final rootPath = VideoPathResolver.toAbsolute('');
      final rootDir = Directory(rootPath);
      final backupsDir = Directory(p.join(rootPath, '.backups'));
      if (!await backupsDir.exists()) {
        await backupsDir.create(recursive: true);
      }

      await for (final entity in rootDir.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        
        // Root backups belong in .backups/
        if ((name.startsWith('breakdex_backup_') && name.endsWith('.db')) ||
            name == 'breakdex_provenance') {
          final targetPath = p.join(backupsDir.path, name);
          if (await File(targetPath).exists()) {
            // Suffix the old backup if it collides (highly unlikely but safe)
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final targetPathWithTs = p.join(backupsDir.path, '${p.basenameWithoutExtension(name)}_$timestamp${p.extension(name)}');
            await FileSystemUtils.safeMove(entity.path, targetPathWithTs);
          } else {
            await FileSystemUtils.safeMove(entity.path, targetPath);
          }
        }
      }
    } catch (e) {
      debugPrint('[VideoPathHealer] Root cleanup failed: $e');
    }
  }

  static Future<void> _cleanupMovesOrphans(final AppDatabase db) async {
    try {
      final movesPath = p.join(VideoPathResolver.toAbsolute(''), 'Moves');
      final movesDir = Directory(movesPath);
      if (!await movesDir.exists()) return;

      final archiveDir = Directory(p.join(movesPath, 'Archive'));
      if (!await archiveDir.exists()) {
        await archiveDir.create(recursive: true);
      }

      // Proactive cross-reference: everything on disk must have a home in DB
      final allMoves = await db.movesDao.getAllIncludingArchived();
      final allCombos = await db.combosDao.getAll();
      
      final validPaths = <String>{};
      
      for (final m in allMoves) {
        if (m.videoPath != null) {
          validPaths.add(VideoPathResolver.toAbsolute(m.videoPath!));
        }
      }
      
      for (final c in allCombos) {
        if (c.activeVideoPath != null) {
          validPaths.add(VideoPathResolver.toAbsolute(c.activeVideoPath!));
        }
      }

      await for (final entity in movesDir.list(recursive: true)) {
        if (entity is! File) continue;
        final absPath = entity.path;
        
        // Don't orphan files that are already safely archived
        if (p.isWithin(archiveDir.path, absPath)) continue;

        final name = p.basename(absPath);

        // If it's a flat file in Moves/ that we don't recognize -> Archive
        if (validPaths.contains(absPath)) continue;
        if (name.startsWith('.') || name.endsWith('.jpg') || name.endsWith('.png')) continue;

        final targetPath = p.join(archiveDir.path, name);
        if (await File(targetPath).exists()) {
          // Suffix orphan if it collides in Archive
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final targetPathWithTs = p.join(archiveDir.path, '${p.basenameWithoutExtension(name)}_orphan_$timestamp${p.extension(name)}');
          await FileSystemUtils.safeMove(entity.path, targetPathWithTs);
        } else {
          await FileSystemUtils.safeMove(entity.path, targetPath);
        }
      }
    } catch (e) {
      debugPrint('[VideoPathHealer] Orphan cleanup failed: $e');
    }
  }

  static Future<void> _healDatabasePaths(final AppDatabase db) async {
    var healed = 0;
    var migrated = 0;

    // Heal moves.videoPath
    final moves = await db.movesDao.getAllIncludingArchived();
    for (final move in moves) {
      String? currentPath = move.videoPath;
      if (currentPath == null) continue;

      if (!VideoPathResolver.isRelative(currentPath)) {
        currentPath = VideoPathResolver.toRelative(currentPath);
        await db.movesDao.updateMove(
          MovesCompanion(id: Value(move.id), videoPath: Value(currentPath)),
        );
        healed++;
      }

      final semanticRelative = await VideoPathResolver.moveToSemanticPath(
        currentRelativePath: currentPath,
        category: move.category,
        moveName: move.name,
        contentHash: ContentHash(move.contentHash!),
      );

      if (semanticRelative != currentPath) {
        await db.movesDao.updateMove(
          MovesCompanion(id: Value(move.id), videoPath: Value(semanticRelative)),
        );
        migrated++;
      }
    }

    // Heal combos and asset manifest
    final combos = await db.combosDao.getAll();
    for (final combo in combos) {
      if (combo.activeVideoPath != null &&
          !VideoPathResolver.isRelative(combo.activeVideoPath!)) {
        final relative = VideoPathResolver.toRelative(combo.activeVideoPath!);
        await (db.update(db.combos)..where((final t) => t.id.equals(combo.id)))
            .write(CombosCompanion(activeVideoPath: Value(relative)));
        healed++;
      }
    }

    final manifests = await db.assetManifestDao.getAll();
    for (final manifest in manifests) {
      if (manifest.localPath != null &&
          !VideoPathResolver.isRelative(manifest.localPath!)) {
        final relative = VideoPathResolver.toRelative(manifest.localPath!);
        await db.assetManifestDao.updateLocalState(
          manifest.contentHash,
          localPath: Value(relative),
        );
        healed++;
      }
    }

    if (healed > 0 || migrated > 0) {
      debugPrint('[VideoPathHealer] Completed record healing.');
    }
  }
}
