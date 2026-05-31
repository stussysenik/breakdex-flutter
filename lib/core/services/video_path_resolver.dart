import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../utils/filesystem_utils.dart';
import '../utils/diagnostics.dart';
import 'app_storage_paths.dart';

String _sanitizeFilename(String name) {
  return name
      .replaceAll('/', '-')
      .replaceAll(':', '-')
      .trim();
}

/// Resolves video paths between relative (DB) and absolute (file system) forms.
///
/// iOS changes the container UUID on every reinstall/update, which breaks
/// absolute paths stored in the database. This utility stores paths as relative
/// (`Moves/uuid.mp4`) and resolves them to the current container at runtime.
///
/// **Three core operations:**
/// - [toRelative] — strips the documents prefix for DB storage
/// - [toAbsolute] — prepends the current documents dir for file access
/// - [resolve] — last-resort disk scan when the expected file is missing
///
/// Call [initialize] once at app startup before any path operations.
abstract final class VideoPathResolver {
  static String _docsPath = '';

  /// Cache the current documents directory path. Must be called once at
  /// startup before [toRelative], [toAbsolute], or [resolve] are used.
  static Future<void> initialize() async {
    final dir = await AppStoragePaths.documentsDirectory();
    _docsPath = dir.path;
    // Ensure trailing separator is stripped for consistent prefix matching
    if (_docsPath.endsWith('/')) {
      _docsPath = _docsPath.substring(0, _docsPath.length - 1);
    }
  }

  /// Test-only setter to bypass [AppStoragePaths] in unit tests.
  @visibleForTesting
  static set docsPathOverride(String path) => _docsPath = path;

  /// Whether a path is already relative (doesn't start with `/`).
  static bool isRelative(String path) => !path.startsWith('/');

  /// Convert an absolute path to a relative path suitable for DB storage.
  ///
  /// Algorithm:
  /// 1. Already relative → return as-is
  /// 2. Starts with current docs prefix → strip prefix
  /// 3. Absolute but different container UUID → find `/Documents/` marker
  /// 4. Fallback → `Moves/{basename}`
  static String toRelative(String path) {
    assert(
      _docsPath.isNotEmpty,
      'VideoPathResolver.initialize() must be called first',
    );
    // Already relative — nothing to do
    if (!path.startsWith('/')) return path;

    // Starts with current documents directory
    if (path.startsWith(_docsPath)) {
      final relative = path.substring(_docsPath.length);
      // Strip leading slash: "/Moves/uuid.mp4" → "Moves/uuid.mp4"
      if (relative.startsWith('/')) return relative.substring(1);
      return relative;
    }

    // Different container UUID — extract from /Documents/ marker
    const marker = '/Documents/';
    final markerIndex = path.indexOf(marker);
    if (markerIndex >= 0) {
      return path.substring(markerIndex + marker.length);
    }

    // New fallback: If it's already an absolute path under a 'Moves' folder
    // but we can't find /Documents/, try to find the 'Moves/' marker itself.
    final movesMarker = p.separator + 'Moves' + p.separator;
    final movesIndex = path.indexOf(movesMarker);
    if (movesIndex >= 0) {
      return path.substring(movesIndex + 1); // "Moves/..."
    }

    // Fallback: use Moves/{basename} as a safe relative path
    return 'Moves/${p.basename(path)}';
  }

  /// Convert a (possibly relative) path to an absolute path for file access.
  ///
  /// Algorithm:
  /// 1. Relative → prepend current docs directory
  /// 2. Starts with current docs prefix → return as-is
  /// 3. Absolute with wrong prefix → extract relative via /Documents/ marker
  static String toAbsolute(String path) {
    assert(
      _docsPath.isNotEmpty,
      'VideoPathResolver.initialize() must be called first',
    );
    // Relative path — prepend docs directory
    if (!path.startsWith('/')) {
      return '$_docsPath/$path';
    }

    // Already points to current container
    if (path.startsWith(_docsPath)) return path;

    // Absolute with stale container UUID — extract relative portion
    const marker = '/Documents/';
    final markerIndex = path.indexOf(marker);
    if (markerIndex >= 0) {
      final relative = path.substring(markerIndex + marker.length);
      return '$_docsPath/$relative';
    }

    // Unknown absolute path — return as-is, caller will handle missing file
    return path;
  }

  /// Last-resort file resolution: scans known directories for a matching
  /// filename when the expected path doesn't exist on disk.
  ///
  /// Returns the found absolute path, or null if the file can't be located.
  /// This is the self-healing core — called only when a file is missing.
  static Future<String?> resolve(String storedPath) async {
    DiagnosticsLog.info('VideoPathResolver', 'resolve storedPath=$storedPath');
    // First try the normal toAbsolute resolution
    final candidate = toAbsolute(storedPath);
    try {
      final exists = await File(
        candidate,
      ).exists().timeout(const Duration(seconds: 3), onTimeout: () => false);
      if (exists) {
        final stat = await File(candidate).stat().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw Exception('stat timed out'),
        );
        if (stat.size > 0) {
          DiagnosticsLog.info('VideoPathResolver', 'resolve: direct hit $candidate');
          return candidate;
        }
      }
    } catch (_) {
      // Continue to fallback scan
    }

    DiagnosticsLog.warn('VideoPathResolver', 'resolve: direct miss for $storedPath, scanning...');
    // Extract filename for directory scan
    final filename = p.basename(storedPath);
    if (filename.isEmpty) return null;

    // Scan Documents/Moves/ and Documents/videos/ for matching filename
    for (final subdir in ['Moves', 'videos']) {
      final dir = Directory('$_docsPath/$subdir');
      try {
        if (!await dir.exists()) continue;
        await for (final entity in dir.list()) {
          if (entity is File && p.basename(entity.path) == filename) {
            final stat = await entity.stat();
            if (stat.size > 0) {
              DiagnosticsLog.info('VideoPathResolver', 'resolve: found in $subdir → ${entity.path}');
              return entity.path;
            }
          }
        }
      } catch (e) {
        debugPrint('[VideoPathResolver] Scan error in $subdir: $e');
      }
    }

    DiagnosticsLog.error('VideoPathResolver', 'resolve: file not found for $storedPath');
    return null;
  }

  /// Return a semantic relative path for video storage:
  /// `Moves/{category}/{moveName}/{contentHash}.{ext}`.
  ///
  /// Uses content hash as the filename so different edits always produce
  /// different paths, forcing Flutter widget keys to evict cached video
  /// players and preventing stale video display.
  ///
  /// Category and move name are sanitized for safe filesystem usage.
  /// If the category is not recognized as a primary category, it defaults to 'Default'.
  static String semanticVideoPath(
    String category,
    String moveName,
    String extension, {
    required String contentHash,
  }) {
    final safeCategory = getSafeCategory(category);

    final sanitizedName = _sanitizeFilename(moveName.trim());
    final safeName = sanitizedName.length > 1
        ? sanitizedName[0].toUpperCase() + sanitizedName.substring(1).toLowerCase()
        : sanitizedName.toUpperCase();

    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    final shortHash = contentHash.substring(0, contentHash.length > 8 ? 8 : contentHash.length);
    return p.join('Moves', safeCategory, '$safeName - $shortHash.${ext.toLowerCase()}');
  }

  /// Return a semantic relative path for video storage:
  /// `Moves/{category}/{moveName}/video.{ext}` (backward-compatible stub
  /// for callers that don't have a content hash yet).
  @Deprecated('Use the contentHash variant instead')
  static String semanticVideoPathLegacy(
    String category,
    String moveName,
    String extension,
  ) {
    final safeCategory = getSafeCategory(category);
    final sanitizedName = _sanitizeFilename(moveName.trim());
    final safeName = sanitizedName.length > 1
        ? sanitizedName[0].toUpperCase() + sanitizedName.substring(1).toLowerCase()
        : sanitizedName.toUpperCase();
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    return p.join('Moves', safeCategory, '$safeName.${ext.toLowerCase()}');
  }

  static String getSafeCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return 'Default';

    final lower = trimmed.toLowerCase();
    
    // Catch all variations of "default" and force canonical 'Default'
    if (lower == 'default' ||
        lower == 'none' ||
        lower == 'uncategorized' ||
        lower == 'general') {
      return 'Default';
    }

    // Force Title Case for all categories to prevent "Footwork" vs "footwork" folders
    final sanitized = _sanitizeFilename(trimmed);
    if (sanitized.length <= 1) return sanitized.toUpperCase();
    return sanitized[0].toUpperCase() + sanitized.substring(1).toLowerCase();
  }

  /// Move the file at [currentRelativePath] to a semantic path based on
  /// [category], [moveName], and [contentHash]. Returns the new relative path.
  ///
  /// If the source file cannot be found, returns [currentRelativePath] as-is.
  /// Creates intermediate directories as needed.
  ///
  /// When [contentHash] is provided, the target filename is `{hash}.mp4`.
  /// When null (backward compat), falls back to `video.mp4`.
  static Future<String> moveToSemanticPath({
    required String currentRelativePath,
    required String category,
    required String moveName,
    String? contentHash,
  }) async {
    final sourceAbs = toAbsolute(currentRelativePath);
    final sourceFile = File(sourceAbs);

    if (!await sourceFile.exists()) {
      DiagnosticsLog.warn('VideoPathResolver', 'moveToSemanticPath: source not found $sourceAbs');
      return currentRelativePath;
    }

    final ext = p.extension(currentRelativePath).isNotEmpty
        ? p.extension(currentRelativePath)
        : '.mp4';
    final newRelative = contentHash != null
        ? semanticVideoPath(category, moveName, ext, contentHash: contentHash)
        : semanticVideoPathLegacy(category, moveName, ext);
    final newAbs = toAbsolute(newRelative);

    if (sourceAbs == newAbs) {
      DiagnosticsLog.info('VideoPathResolver', 'moveToSemanticPath: already at target $newAbs');
      return currentRelativePath;
    }

    final newDir = Directory(p.dirname(newAbs));
    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }

    // Clean up any old legacy `video.mp4` in the same directory to avoid
    // having both the old and new files.
    if (contentHash != null) {
      final legacyFile = File(p.join(p.dirname(newAbs), 'video.mp4'));
      try {
        if (await legacyFile.exists()) {
          await legacyFile.delete();
          DiagnosticsLog.info('VideoPathResolver', 'cleaned legacy video.mp4');
        }
      } catch (_) {}
    }

    try {
      await FileSystemUtils.safeMove(sourceAbs, newAbs);
      DiagnosticsLog.info('VideoPathResolver', 'moveToSemanticPath: $sourceAbs → $newAbs');
      // Prune empty parent dirs of the old path
      final docsPath = _docsPath;
      await FileSystemUtils.pruneEmptyParents(sourceAbs, stopDir: p.join(docsPath, 'Moves'));
      return toRelative(newAbs);
    } catch (e) {
      DiagnosticsLog.error('VideoPathResolver', 'Failed to move file to semantic path: $e');
      // THE FIX: Do not return currentRelativePath which swallows the error,
      // instead rethrow so the upstream caller fails gracefully without corrupting DB state.
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
  static Future<void> healAll(AppDatabase db, SharedPreferences prefs) async {
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
  static Future<void> _autoCleanFileSystem(AppDatabase db) async {
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

  static Future<void> _mergeDirectories(Directory source, Directory target) async {
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

  static Future<int> _pruneEmptyRecursive(Directory dir) async {
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

  static Future<void> _cleanupMovesOrphans(AppDatabase db) async {
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

  static Future<void> _healDatabasePaths(AppDatabase db) async {
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
        contentHash: move.contentHash,
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
        await (db.update(db.combos)..where((t) => t.id.equals(combo.id)))
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
