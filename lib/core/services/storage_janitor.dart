import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers.dart';
import '../utils/diagnostics.dart';
import '../utils/filesystem_utils.dart';
import 'video_path_resolver.dart';

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
    } catch (e) {
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
    } catch (_) {}
    return removed;
  }
}

final storageJanitorProvider = Provider<StorageJanitor>((final ref) {
  return StorageJanitor(db: ref.watch(databaseProvider));
});
