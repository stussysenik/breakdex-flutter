import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
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
        if (stat.size > 0) return candidate;
      }
    } catch (_) {
      // Continue to fallback scan
    }

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
            if (stat.size > 0) return entity.path;
          }
        }
      } catch (e) {
        debugPrint('[VideoPathResolver] Scan error in $subdir: $e');
      }
    }

    return null;
  }

  /// Return a semantic relative path for video storage:
  /// `Moves/{category}/{moveName}/video.{ext}`.
  ///
  /// Category and move name are sanitized for safe filesystem usage.
  /// If the category is not recognized as a primary category, it defaults to 'Default'.
  static String semanticVideoPath(
    String category,
    String moveName,
    String extension,
  ) {
    // Standardize category naming for storage
    final safeCategory = _getSafeCategory(category);
    
    // Standardize move naming to prevent "Windmill" vs "windmill" folder duplicates
    final sanitizedName = _sanitizeFilename(moveName.trim());
    final safeName = sanitizedName.length > 1 
      ? sanitizedName[0].toUpperCase() + sanitizedName.substring(1).toLowerCase()
      : sanitizedName.toUpperCase();

    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    return p.join('Moves', safeCategory, safeName, 'video.$ext');
  }

  static String _getSafeCategory(String category) {
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
  /// [category] and [moveName]. Returns the new relative path.
  ///
  /// If the source file cannot be found, returns [currentRelativePath] as-is.
  /// Creates intermediate directories as needed.
  static Future<String> moveToSemanticPath({
    required String currentRelativePath,
    required String category,
    required String moveName,
  }) async {
    final sourceAbs = toAbsolute(currentRelativePath);
    final sourceFile = File(sourceAbs);

    if (!await sourceFile.exists()) return currentRelativePath;

    final ext = p.extension(currentRelativePath).isNotEmpty
        ? p.extension(currentRelativePath)
        : '.mp4';
    final newRelative = semanticVideoPath(category, moveName, ext);
    final newAbs = toAbsolute(newRelative);

    // Already at the correct path
    if (sourceAbs == newAbs) return currentRelativePath;

    final newDir = Directory(p.dirname(newAbs));
    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }

    try {
      await sourceFile.rename(newAbs);
      return toRelative(newAbs);
    } catch (e) {
      debugPrint('[VideoPathResolver] Failed to move file to semantic path: $e');
      return currentRelativePath;
    }
  }
}

/// One-time batch migration that converts stored absolute video paths to
/// relative form and ensures all files follow the semantic naming structure.
///
/// Gated by SharedPreferences so it only runs once.
abstract final class VideoPathHealer {
  static const _prefsKey = 'video_paths_healed_v3';

  /// Proactive healing of both the database records and physical filesystem.
  ///
  /// This is the "Truth Guard" of the application. It runs after the first frame
  /// to ensure the Files app and SQLite always remain in sync.
  static Future<void> healAll(AppDatabase db, SharedPreferences prefs) async {
    // 1. Filesystem Purity (Run every boot - lightweight)
    // Ensures root backups and orphaned UUID videos are always organized.
    await _autoCleanFileSystem(db);

    // 2. Database Record Healing (Version gated - heavy)
    // Ensures all stored paths follow the latest semantic structure.
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
        if (await File(destPath).exists()) {
          await entity.delete();
        } else {
          await entity.rename(destPath);
        }
      } else if (entity is Directory) {
        await _mergeDirectories(entity, Directory(destPath));
      }
    }
    try {
      await source.delete();
    } catch (_) {}
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
            await entity.delete();
          } else {
            await entity.rename(targetPath);
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
      final validPaths = allMoves
          .map((m) => m.videoPath)
          .whereType<String>()
          .map((p) => VideoPathResolver.toAbsolute(p))
          .toSet();

      await for (final entity in movesDir.list()) {
        if (entity is! File) continue;
        final absPath = entity.path;
        final name = p.basename(absPath);

        // If it's a flat file in Moves/ that we don't recognize -> Archive
        if (validPaths.contains(absPath)) continue;
        if (name.startsWith('.') || name.endsWith('.jpg') || name.endsWith('.png')) continue;

        final targetPath = p.join(archiveDir.path, name);
        if (await File(targetPath).exists()) {
          await entity.delete();
        } else {
          await entity.rename(targetPath);
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
