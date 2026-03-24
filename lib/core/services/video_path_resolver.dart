import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import 'app_storage_paths.dart';

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
    assert(_docsPath.isNotEmpty, 'VideoPathResolver.initialize() must be called first');
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
    assert(_docsPath.isNotEmpty, 'VideoPathResolver.initialize() must be called first');
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
      final exists = await File(candidate).exists().timeout(
            const Duration(seconds: 3),
            onTimeout: () => false,
          );
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
}

/// One-time batch migration that converts stored absolute video paths to
/// relative form. Gated by SharedPreferences so it only runs once.
///
/// No Drift schema migration needed — column types stay the same, only the
/// stored string values change from `/var/mobile/.../Documents/Moves/uuid.mp4`
/// to `Moves/uuid.mp4`.
abstract final class VideoPathHealer {
  static const _prefsKey = 'video_paths_healed_v1';

  /// Convert all absolute video paths in the database to relative form.
  /// Idempotent — skips if already healed (SharedPreferences gate).
  static Future<void> healAll(AppDatabase db, SharedPreferences prefs) async {
    if (prefs.getBool(_prefsKey) == true) return;

    var healed = 0;

    try {
      // Heal moves.videoPath
      final moves = await db.movesDao.getAll();
      for (final move in moves) {
        if (move.videoPath != null &&
            !VideoPathResolver.isRelative(move.videoPath!)) {
          final relative = VideoPathResolver.toRelative(move.videoPath!);
          await db.movesDao.updateMove(
            MovesCompanion(
              id: Value(move.id),
              videoPath: Value(relative),
            ),
          );
          healed++;
        }
      }

      // Heal combos.activeVideoPath
      final combos = await db.combosDao.getAll();
      for (final combo in combos) {
        if (combo.activeVideoPath != null &&
            !VideoPathResolver.isRelative(combo.activeVideoPath!)) {
          final relative =
              VideoPathResolver.toRelative(combo.activeVideoPath!);
          await (db.update(db.combos)
                ..where((t) => t.id.equals(combo.id)))
              .write(CombosCompanion(activeVideoPath: Value(relative)));
          healed++;
        }
      }

      // Heal asset_manifest.localPath
      final manifests = await db.assetManifestDao.getAll();
      for (final manifest in manifests) {
        if (manifest.localPath != null &&
            !VideoPathResolver.isRelative(manifest.localPath!)) {
          final relative =
              VideoPathResolver.toRelative(manifest.localPath!);
          await db.assetManifestDao.upsert(
            AssetManifestCompanion(
              contentHash: Value(manifest.contentHash),
              localPath: Value(relative),
            ),
          );
          healed++;
        }
      }

      await prefs.setBool(_prefsKey, true);
      if (healed > 0) {
        debugPrint('[VideoPathHealer] Healed $healed absolute paths → relative');
      }
    } catch (e) {
      debugPrint('[VideoPathHealer] Healing failed: $e');
      // Non-fatal — paths still work via toAbsolute() at read time
    }
  }
}
