// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'package:breakdex/core/platform/io.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/sync/sandbox_hash_index.dart' show sandboxHashToken;
import 'package:breakdex/core/utils/diagnostics.dart';
import 'package:breakdex/core/utils/filesystem_utils.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';

/// Performs a symmetric difference between the SQL database and the Filesystem.
/// 
/// The "Janitor" is the ultimate guard for Truth. It ensures that no zombie 
/// files survive app restarts and all records have their corresponding media.
class StorageJanitor {
  StorageJanitor({
    required final AppDatabase db,
  }) : _db = db;

  final AppDatabase _db;

  /// Runs the full reconciliation cycle.
  Future<void> reconcile() async {
    final stopwatch = Stopwatch()..start();
    DiagnosticsLog.info('Janitor', '[START] Boot-up reconciliation');

    try {
      // 1. Fetch all valid paths from DB
      final allMoves = await _db.movesDao.getAllIncludingArchived();
      final allCombos = await _db.combosDao.getAll();
      
      final dbPaths = <String>{};
      for (final m in allMoves) {
        if (m.videoPath != null) dbPaths.add(VideoPathResolver.toAbsolute(m.videoPath!));
      }
      for (final c in allCombos) {
        if (c.activeVideoPath != null) dbPaths.add(VideoPathResolver.toAbsolute(c.activeVideoPath!));
      }

      // Hash tokens of every live manifest row (full hash + hash8). A file
      // whose canonical filename carries one of these is manifest-known — a
      // registered asset at a stale path, NOT "identity unknown". Quarantining
      // it severs the asset from its bytes while the manifest keeps billing
      // for it (design D11: the exact mechanism that stranded 22 assets in
      // `.lost+found`). Entities are not the only ownership truth; the
      // manifest registry is consulted before any file is moved.
      final manifestTokens = <String>{};
      for (final m in await _db.assetManifestDao.getAll()) {
        if (m.deletedAt != null) continue;
        final hash = m.contentHash.toLowerCase();
        manifestTokens.add(hash);
        if (hash.length > 8) manifestTokens.add(hash.substring(0, 8));
      }

      // 2. Scan Filesystem
      final movesDir = Directory(p.join(VideoPathResolver.documentsPath, 'Moves'));
      if (!await movesDir.exists()) return;

      final lostAndFound = Directory(p.join(movesDir.path, '.lost+found'));
      var purged = 0;
      var archived = 0;

      await for (final entity in movesDir.list(recursive: true)) {
        if (entity is! File) continue;
        final absPath = entity.path;
        
        // Skip system/internal files
        if (p.basename(absPath).startsWith('.') || 
            absPath.contains('/.thumbs/') ||
            p.isWithin(lostAndFound.path, absPath)) {
          continue;
        }

        // If file NOT in DB -> Orphan
        if (!dbPaths.contains(absPath)) {
          final filename = p.basename(absPath);

          // Manifest-known: leave in place. The engine's hash-indexed heal
          // lane (D10) re-points `localPath` here on the next sweep; moving
          // the file would only force another heal or, pre-D10, strand it.
          final token = sandboxHashToken(filename);
          if (token != null && manifestTokens.contains(token)) {
            DiagnosticsLog.info(
                'Janitor', '[KNOWN] Manifest asset, left for heal: $filename');
            continue;
          }
          final target = p.join(lostAndFound.path, filename);
          
          if (!await lostAndFound.exists()) await lostAndFound.create(recursive: true);
          
          await FileSystemUtils.safeMove(absPath, target);
          DiagnosticsLog.warn('Janitor', '[ORPHAN] Identity unknown -> .lost+found: $filename');
          archived++;
        }
      }

      // 3. Prune Empty Folders
      purged = await _pruneEmptyRecursive(movesDir);

      DiagnosticsLog.info('Janitor', '[COMPLETE] ${stopwatch.elapsedMilliseconds}ms | Archived: $archived | Pruned Dirs: $purged');
    } on Object catch (e) {
      DiagnosticsLog.error('Janitor', 'Reconciliation failed: $e');
    }
  }

  Future<int> _pruneEmptyRecursive(final Directory dir) async {
    var removed = 0;
    try {
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          removed += await _pruneEmptyRecursive(entity);
        }
      }
      
      // Don't delete the root Moves folder
      if (p.basename(dir.path) == 'Moves') return removed;
      
      final entries = await dir.list().toList();
      if (entries.isEmpty) {
        await dir.delete();
        removed++;
      }
    } on Object catch (_) {}
    return removed;
  }
}

final storageJanitorProvider = Provider<StorageJanitor>((final ref) {
  return StorageJanitor(db: ref.watch(databaseProvider));
});
