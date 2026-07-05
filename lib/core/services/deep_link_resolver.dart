// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:path/path.dart' as p;

import '../database/database.dart';
import '../utils/diagnostics.dart';
import 'video_path_resolver.dart';

/// Resolution result: a navigation target in Breakdex.
class DeepLinkTarget {
  final String type; // 'move' or 'combo'
  final String entityId;
  final String? comboStepName;

  DeepLinkTarget.move(final String id)
      : type = 'move',
        entityId = id,
        comboStepName = null;
  DeepLinkTarget.combo(final String id, final String? stepName)
      : type = 'combo',
        entityId = id,
        comboStepName = stepName;

  String get route => switch (type) {
        'move' => '/breakdex/move/$entityId',
        'combo' => '/breakdex/combo/$entityId',
        _ => '/breakdex/move/$entityId',
      };
}

/// Resolves an incoming video URL (from Files app Open-in) to a Breakdex
/// navigation target. Resolution is fully logged via StageLogger.
abstract final class DeepLinkResolver {
  /// Resolves [fileUrl] to a target, or null if no match.
  static Future<DeepLinkTarget?> resolve(
    final String fileUrl,
    final AppDatabase db,
  ) async {
    final log = StageLogger.begin('DeepLinkResolver',
        subsystem: 'FilesDeepLink',
        context: {'url': fileUrl});

    try {
      final file = File(fileUrl);
      if (!await file.exists()) {
        log.stage('fileNotFound');
        log.fail('File not found at $fileUrl', null);
        return null;
      }

      final filename = p.basename(fileUrl);
      final fileSize = await file.length();
      log.stage('fileFound', {'filename': filename, 'size': fileSize});

      // 1. Match by filename against moves
      final allMoves = await db.movesDao.getAllIncludingArchived();
      for (final move in allMoves) {
        if (move.originalVideoName == filename ||
            (move.videoPath != null &&
                p.basename(move.videoPath!) == filename)) {
          log.stage('moveMatchedByFilename', {'moveId': move.id});
          log.complete();
          return DeepLinkTarget.move(move.id);
        }
      }

      // 2. Match by contentHash — check if any move has this file's content hash
      // (Fast: iterate only moves that have a content hash)
      for (final move in allMoves) {
        if (move.contentHash != null && move.videoPath != null) {
          final storedPath = VideoPathResolver.toAbsolute(move.videoPath!);
          if (await File(storedPath).exists()) {
            final storedSize = await File(storedPath).length();
            if (storedSize == fileSize) {
              log.stage('moveMatchedBySize', {'moveId': move.id});
              log.complete();
              return DeepLinkTarget.move(move.id);
            }
          }
        }
      }

      // 3. Check combo note entries for videoPath matches
      // (This requires iterating — kept lightweight by limiting to recent entries)
      final recents = await db.comboNoteEntriesDao
          .watchRecentTakeRefs(limit: 100)
          .first;
      for (final entry in recents) {
        if (entry.videoPath != null &&
            p.basename(entry.videoPath!) == filename) {
          log.stage('comboMatchByFilename',
              {'comboId': entry.comboId});
          log.complete();
          return DeepLinkTarget.combo(entry.comboId, null);
        }
      }

      // 4. No match — file is not from Breakdex
      log.stage('noMatch');
      log.complete();
      return null;
    } on Object catch (e, stack) {
      log.fail(e, stack);
      return null;
    }
  }
}
