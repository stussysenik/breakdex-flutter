import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/daos/moves_dao.dart';
import '../utils/filesystem_utils.dart';
import '../utils/diagnostics.dart';
import 'video_path_resolver.dart';
import 'provenance_service.dart';

import 'blackbox_service.dart';

import 'blackbox_service.dart';

/// Orchestrates atomic-like operations across SQLite and the Filesystem.
class StorageOrchestrator {
  final MovesDao _movesDao;
  final ProvenanceService? _provenance;
  final BlackboxService? _blackbox;

  StorageOrchestrator({
    required AppDatabase db,
    required MovesDao movesDao,
    ProvenanceService? provenance,
    BlackboxService? blackbox,
  }) : _movesDao = movesDao,
       _provenance = provenance,
       _blackbox = blackbox;

  /// Rename a category and move all associated video files.
  Future<void> renameCategory(String oldName, String newName) async {
    if (oldName == newName) return;

    final moves = await _movesDao.getAll();
    final movesInCategory = moves.where((m) => m.category == oldName).toList();

    // Blackbox safety log
    await _blackbox?.log('rename_category', 'category', oldName, {'to': newName});

    if (movesInCategory.isEmpty) {
      // Still update the category just in case there are archived moves
      // or other entities we missed in the lightweight list.
      await _movesDao.updateCategory(oldName, newName);
      return;
    }

    // Record intent in provenance for safety (The "Blackbox")
    await _provenance?.logEdited(
      'category',
      oldName,
      {'action': 'rename_started', 'to': newName, 'impact': movesInCategory.length},
    );

    for (final move in movesInCategory) {
      final oldRelative = move.videoPath;
      if (oldRelative == null) {
        // Just update category for this move
        await _movesDao.updateMove(MovesCompanion(
          id: Value(move.id),
          category: Value(newName),
        ));
        continue;
      }

      final newRelative = await VideoPathResolver.moveToSemanticPath(
        currentRelativePath: oldRelative,
        category: newName,
        moveName: move.name,
        contentHash: move.contentHash,
      );

      await _movesDao.updateMove(MovesCompanion(
        id: Value(move.id),
        category: Value(newName),
        videoPath: Value(newRelative),
      ));
    }

    await _provenance?.logEdited(
      'category',
      newName,
      {'action': 'rename_complete', 'from': oldName},
    );

    // Final cleanup: remove the old category directory if it is empty
    await _cleanupOldCategoryDir(oldName);
    
    // Proactive Duplicate Guard: merge any other "default" or "Default" folders
    await _enforceCanonicalCasing(newName);
  }

  /// Proactively find and merge folders that differ only by casing.
  /// (e.g., if 'default' exists alongside 'Default', merge into 'Default')
  Future<void> _enforceCanonicalCasing(String category) async {
    try {
      final canonicalName = VideoPathResolver.getSafeCategory(category);
      final rootMoves = p.join(VideoPathResolver.toAbsolute(''), 'Moves');
      final directory = Directory(rootMoves);
      if (!await directory.exists()) return;

      await for (final entity in directory.list()) {
        if (entity is! Directory) continue;
        final actualName = p.basename(entity.path);
        
        // If it's a match ignoring case but NOT the canonical one, merge it
        if (actualName.toLowerCase() == canonicalName.toLowerCase() && 
            actualName != canonicalName) {
          DiagnosticsLog.debug('StorageOrchestrator', 'Merging duplicate folder: $actualName -> $canonicalName');
          await _mergeDirectories(entity, Directory(p.join(rootMoves, canonicalName)));
        }
      }
    } catch (e) {
      DiagnosticsLog.warn('StorageOrchestrator', 'Duplicate guard failed: $e');
    }
  }

  Future<void> _mergeDirectories(Directory source, Directory target) async {
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
          finalDest = p.join(target.path, '${base}_merged_$timestamp$ext');
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

  /// Update a move's category and physically move its video file.
  Future<Move> updateMoveCategory(Move move, String newCategory) async {
    if (move.category == newCategory) return move;

    await _blackbox?.log('update_move_category', 'move', move.id, {
      'from': move.category,
      'to': newCategory,
    });

    String? newRelative = move.videoPath;
    if (move.videoPath != null) {
      newRelative = await VideoPathResolver.moveToSemanticPath(
        currentRelativePath: move.videoPath!,
        category: newCategory,
        moveName: move.name,
        contentHash: move.contentHash,
      );
    }

    await _movesDao.updateMove(MovesCompanion(
      id: Value(move.id),
      category: Value(newCategory),
      videoPath: Value(newRelative),
    ));

    // Cleanup old dir if empty
    await _cleanupOldCategoryDir(move.category);

    // Proactive Duplicate Guard
    await _enforceCanonicalCasing(newCategory);

    return move.copyWith(
      category: newCategory,
      videoPath: Value(newRelative),
    );
  }

  /// Update a move's name and physically rename its video folder/file.
  Future<Move> updateMoveName(Move move, String newName) async {
    if (move.name == newName) return move;

    await _blackbox?.log('update_move_name', 'move', move.id, {
      'from': move.name,
      'to': newName,
    });

    String? newRelative = move.videoPath;
    if (move.videoPath != null) {
      newRelative = await VideoPathResolver.moveToSemanticPath(
        currentRelativePath: move.videoPath!,
        category: move.category,
        moveName: newName,
        contentHash: move.contentHash,
      );
    }

    await _movesDao.updateMove(MovesCompanion(
      id: Value(move.id),
      name: Value(newName),
      videoPath: Value(newRelative),
    ));

    return move.copyWith(
      name: newName,
      videoPath: Value(newRelative),
    );
  }

  /// Delete a move and its associated physical media.
  Future<void> deleteMove(Move move, {required Future<void> Function(Move) cleanupMedia}) async {
    await _blackbox?.log('delete_move', 'move', move.id, {'name': move.name});
    final log = StageLogger.begin('deleteMove', subsystem: 'StorageOrchestrator', context: {
      'moveId': move.id,
      'name': move.name,
    });

    try {
      await cleanupMedia(move);
      log.stage('mediaCleaned');
    } catch (e, stack) {
      log.stage('mediaCleanupFailed', {'error': '$e'});
    }

    try {
      await _movesDao.deleteMove(move.id);
      log.stage('dbRowDeleted');
    } catch (e, stack) {
      log.fail(e, stack);
      rethrow;
    }

    await _blackbox?.log('delete_move_complete', 'move', move.id, {});
    log.complete();

    await _cleanupOldCategoryDir(move.category);
  }

  Future<void> _cleanupOldCategoryDir(String categoryName) async {
    try {
      final safeCategory = categoryName.replaceAll('/', '-').replaceAll(':', '-').trim();
      final dirPath = p.join(VideoPathResolver.toAbsolute(''), 'Moves', safeCategory);
      final directory = Directory(dirPath);
      if (await directory.exists()) {
        final contents = await directory.list().toList();
        if (contents.isEmpty) {
          await directory.delete();
          debugPrint('[StorageOrchestrator] Cleaned up empty category dir: $safeCategory');
        }
      }
    } catch (e) {
      debugPrint('[StorageOrchestrator] Cleanup failed (non-fatal): $e');
    }
  }
}
