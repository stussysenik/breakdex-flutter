import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../database/database.dart';
import '../../models/learning_state.dart';
import '../../models/reviewable_item.dart';
import '../../providers.dart';
import '../../services/video_path_resolver.dart';
import '../../services/native_video_album.dart';
import '../../utils/diagnostics.dart';
import '../../utils/filesystem_utils.dart';
import 'state.dart';
import 'event.dart';
import 'machine.dart';

/// Riverpod Notifier wrapping a MoveDetailMachine for a specific move.
class MoveDetailNotifier extends Notifier<MoveDetailState> {
  late final MoveDetailMachine _machine;

  @override
  MoveDetailState build() {
    final initialMove = Move(
      id: 'loading',
      name: 'Loading...',
      category: '...',
      count: 0,
      learningState: 'new',
      createdAt: DateTime.now(),
    );
    final initialState = Idle(initialMove);
    _machine = MoveDetailMachine(initialState);
    return initialState;
  }

  void init(Move move) {
    state = Idle(move);
    _machine.send(StreamUpdate(move));
  }

  void send(MoveDetailEvent event) {
    final next = _machine.transition(state, event);
    if (next != null) {
      state = next;
      _executeEntryActions(next);
    }
  }

  void _executeEntryActions(MoveDetailState s) {
    switch (s) {
      case ValidatingName(:final move, :final candidateName):
        _validateName(move, candidateName);
      case SavingName(:final move, :final newName):
        _saveName(move, newName);
      case SavingState(:final move, :final newState):
        _saveState(move, newState);
      case SavingCategory(:final move, :final newCategory):
        _saveCategory(move, newCategory);
      case SavingCount(:final move, :final newCount):
        _saveCount(move, newCount);
      case SavingVideo(:final move, :final localPath, :final originalFileName):
        _saveVideo(move, localPath, originalFileName);
      case RemovingVideo(:final move):
        _removeVideo(move);
      case Deleting(:final move):
        _deleteMove(move);
      case SavingLog(:final move, :final body):
        _saveLogEntry(move, body);
      case DeletingLog(:final move, :final entryId):
        _deleteLogEntry(move, entryId);
      case SavingNotes(:final move, :final draftText):
        _saveNotes(move, draftText);
      case SavingPhotos(:final move, :final json):
        _savePhotos(move, json);
      case Duplicating(:final move):
        _duplicateMove(move);
      default:
        break;
    }
  }

  // ── Side effect methods ──

  Future<void> _duplicateMove(Move move) async {
    final log = StageLogger.begin('_duplicateMove', subsystem: 'MoveDetail', context: {
      'moveId': move.id,
      'name': move.name,
    });
    try {
      unawaited(HapticFeedback.heavyImpact());
      final newName = '${move.name} (Copy)';
      
      final newId = const Uuid().v4();
      String? newVideoPath;
      
      if (move.videoPath != null) {
        log.stage('copying_video_isolate');
        final sourceAbs = VideoPathResolver.toAbsolute(move.videoPath!);
        final ext = p.extension(sourceAbs);
        final targetRelative = VideoPathResolver.semanticVideoPath(
          move.category,
          newName,
          ext,
          contentHash: newId,
        );
        final targetAbs = VideoPathResolver.toAbsolute(targetRelative);
        
        // offload to background isolate to keep UI thread at 60/120fps
        await FileSystemUtils.copyFileBackground(sourceAbs, targetAbs);
        
        newVideoPath = targetRelative;
        
        // Also copy thumbnail in background
        final sourceThumb = p.join(p.dirname(sourceAbs), '.thumbs', '${p.basenameWithoutExtension(sourceAbs)}.jpg');
        final targetThumb = p.join(p.dirname(targetAbs), '.thumbs', '${p.basenameWithoutExtension(targetAbs)}.jpg');
        if (await File(sourceThumb).exists()) {
          await FileSystemUtils.copyFileBackground(sourceThumb, targetThumb);
        }
      }
      
      final companion = MovesCompanion.insert(
        id: newId,
        name: newName,
        category: Value(move.category),
        count: Value(move.count),
        learningState: Value(move.learningState),
        notes: Value(move.notes),
        videoPath: Value(newVideoPath),
        originalVideoName: Value(move.originalVideoName),
        videoFileSize: Value(move.videoFileSize),
        videoCreationDate: Value(DateTime.now()),
        imagePaths: Value(move.imagePaths),
        contentHash: Value(move.contentHash),
      );
      
      await ref.read(moveRepositoryProvider).insert(companion);
      log.stage('db_inserted');
      
      final newMove = await ref.read(moveRepositoryProvider).getById(newId);
      await ref.read(fsrsCardsDaoProvider).ensureCard(newId, entityType: 'move');
      
      send(DuplicateSucceeded(newMove));
      log.complete('newId=$newId');
    } catch (e, st) {
      log.fail(e, st);
      send(DuplicateFailed('Duplication failed: $e'));
    }
  }

  Future<void> _savePhotos(Move move, String? json) async {
    try {
      await ref.read(moveRepositoryProvider).update(
        MovesCompanion(id: Value(move.id), imagePaths: Value(json)),
      );
      send(SaveSucceeded(move.copyWith(imagePaths: Value(json))));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _validateName(Move move, String candidateName) async {
    final naming = ref.read(reviewableNamingServiceProvider);
    final normalized = naming.normalize(candidateName);
    final exists = await naming.isNameTaken(
      normalized,
      excludingMoveId: move.id,
    );
    if (exists) {
      send(const NameTaken());
    } else {
      send(const NameAvailable());
    }
  }

  Future<void> _saveName(Move move, String newName) async {
    try {
      final orchestrator = ref.read(storageOrchestratorProvider);
      var updatedMove = await orchestrator.updateMoveName(move, newName);
      send(SaveSucceeded(updatedMove));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveState(Move move, LearningState newState) async {
    final log = StageLogger.begin('_saveState', subsystem: 'MoveDetail', context: {
      'moveId': move.id,
      'currentState': move.learningState,
      'newState': newState.dbValue,
    });
    try {
      await ref.read(manualReviewStateServiceProvider).setMoveState(move, newState);
      log.stage('serviceCompleted');
      final updatedMove = move.copyWith(learningState: newState.dbValue);
      send(SaveSucceeded(updatedMove));
      log.complete();
    } catch (e, stack) {
      log.fail(e, stack);
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveCategory(Move move, String newCategory) async {
    try {
      final orchestrator = ref.read(storageOrchestratorProvider);
      var updatedMove = await orchestrator.updateMoveCategory(move, newCategory);
      send(SaveSucceeded(updatedMove));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveCount(Move move, int newCount) async {
    try {
      await ref.read(moveRepositoryProvider).update(
        MovesCompanion(id: Value(move.id), count: Value(newCount)),
      );
      send(SaveSucceeded(move.copyWith(count: newCount)));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveVideo(Move move, String localPath, String originalFileName) async {
    final log = StageLogger.begin('_saveVideo', subsystem: 'MoveDetail', context: {
      'moveId': move.id,
      'localPath': localPath,
      'originalFileName': originalFileName,
    });
    try {
      final absPath = VideoPathResolver.toAbsolute(localPath);
      final contentHash = await ref.read(assetHashServiceProvider).computeHash(absPath);
      final semanticRelative = await VideoPathResolver.moveToSemanticPath(
        currentRelativePath: absPath,
        category: move.category,
        moveName: move.name,
        contentHash: contentHash,
      );
      final resolvedAbs = VideoPathResolver.toAbsolute(semanticRelative);
      final videoService = ref.read(videoServiceProvider);
      unawaited(videoService.generateThumbnail(resolvedAbs));

      await ref.read(moveRepositoryProvider).update(
            MovesCompanion(
              id: Value(move.id),
              videoPath: Value(semanticRelative),
              originalVideoName: Value(originalFileName),
              contentHash: Value(contentHash),
            ),
          );
      var updatedMove = move.copyWith(
        videoPath: Value(semanticRelative),
        originalVideoName: Value(originalFileName),
        contentHash: Value(contentHash),
      );
      unawaited(ref.read(videoImportSyncHookProvider).onVideoImported(
        localPath: resolvedAbs,
        moveId: move.id,
        precomputedHash: contentHash,
      ));
      send(SaveSucceeded(updatedMove));
      log.complete();
    } catch (e, stack) {
      log.fail(e, stack);
      send(SaveFailed('$e'));
    }
  }

  Future<void> _removeVideo(Move move) async {
    try {
      unawaited(HapticFeedback.mediumImpact());
      await ref.read(mediaCleanupServiceProvider).cleanupMoveMedia(move);
      await ref.read(moveRepositoryProvider).update(
            MovesCompanion(
              id: Value(move.id),
              videoPath: const Value(null),
              originalVideoName: const Value(null),
              contentHash: const Value(null),
            ),
          );
      send(SaveSucceeded(move.copyWith(
        videoPath: const Value(null),
        originalVideoName: const Value(null),
        contentHash: const Value(null),
      )));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _deleteMove(Move move) async {
    try {
      unawaited(HapticFeedback.mediumImpact());
      final orchestrator = ref.read(storageOrchestratorProvider);
      unawaited(orchestrator.deleteMove(
        move,
        cleanupMedia: (m) => ref.read(mediaCleanupServiceProvider).cleanupMoveMedia(m),
      ));
      send(const DeleteSucceeded());
    } catch (e) {
      send(DeleteFailed('Delete failed: $e'));
    }
  }

  Future<void> _saveLogEntry(Move move, String body) async {
    try {
      final dao = ref.read(moveNoteEntriesDaoProvider);
      await dao.addEntry(id: const Uuid().v4(), moveId: move.id, body: body);
      send(SaveSucceeded(move));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _deleteLogEntry(Move move, String entryId) async {
    try {
      final dao = ref.read(moveNoteEntriesDaoProvider);
      await dao.deleteEntry(entryId);
      send(SaveSucceeded(move));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveNotes(Move move, String text) async {
    try {
      await ref.read(moveRepositoryProvider).update(
            MovesCompanion(
              id: Value(move.id),
              notes: Value(text.isEmpty ? null : text),
            ),
          );
      send(SaveSucceeded(move.copyWith(notes: Value(text.isEmpty ? null : text))));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }
}

final moveDetailProvider = NotifierProvider<MoveDetailNotifier, MoveDetailState>(
  MoveDetailNotifier.new,
);
