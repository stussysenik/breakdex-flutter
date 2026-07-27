// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/models/canonical_path.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/storage_action_machine.dart';
import 'package:breakdex/core/utils/diagnostics.dart';
import 'package:breakdex/core/state_machines/move_detail/state.dart';
import 'package:breakdex/core/state_machines/move_detail/event.dart';
import 'package:breakdex/core/state_machines/move_detail/machine.dart';

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

  void init(final Move move) {
    state = Idle(move);
    _machine.send(StreamUpdate(move));
  }

  void send(final MoveDetailEvent event) {
    final next = _machine.transition(state, event);
    if (next != null) {
      state = next;
      _executeEntryActions(next);
    }
  }

  void _executeEntryActions(final MoveDetailState s) {
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

  Future<void> _duplicateMove(final Move move) async {
    final log = StageLogger.begin('_duplicateMove', subsystem: 'MoveDetail', context: {'moveId': move.id});
    try {
      final engine = ref.read(storageActionMachineProvider);
      final repo = ref.read(moveRepositoryProvider);
      final newName = '${move.name} (Copy)';

      // 1. Materialize duplicate via Engine
      final sourceRelative = CanonicalPath(move.videoPath ?? '');
      final targetRelative = await engine.execute(DuplicateAction(
        sourceRelative: sourceRelative,
        newName: newName,
        category: move.category,
      ));

      // 2. Derive identity. The content hash is SHARED with the source (same
      //    bytes → same Drive asset, no re-upload), but the move gets its OWN
      //    id so any number of independent copies can coexist. Using the hash
      //    as the move id caused a primary-key collision on the 2nd duplicate,
      //    which is why "infinite copies" failed.
      final filename = p.basenameWithoutExtension(targetRelative.value);
      final contentHash = filename.split(' - ').last;
      final newId = const Uuid().v4();

      final companion = MovesCompanion.insert(
        id: newId,
        name: newName,
        category: Value(move.category),
        count: Value(move.count),
        learningState: Value(move.learningState),
        notes: Value(move.notes),
        videoPath: Value(targetRelative.value),
        originalVideoName: Value(move.originalVideoName),
        videoFileSize: Value(move.videoFileSize),
        videoCreationDate: Value(DateTime.now()),
        imagePaths: Value(move.imagePaths),
        contentHash: Value(contentHash),
      );

      await repo.insert(companion);
      await ref.read(fsrsCardsDaoProvider).ensureCard(newId, entityType: 'move');

      final newMove = await repo.getById(newId);
      send(DuplicateSucceeded(newMove));
      log.complete('newId=$newId hash=$contentHash');
    } on Object catch (e, st) {
      log.fail(e, st);
      send(DuplicateFailed('Duplication failed: $e'));
    }
  }

  Future<void> _savePhotos(final Move move, final String? json) async {
    try {
      await ref.read(moveRepositoryProvider).update(
        MovesCompanion(id: Value(move.id), imagePaths: Value(json)),
      );
      send(SaveSucceeded(move.copyWith(imagePaths: Value(json))));
    } on Object catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _validateName(final Move move, final String candidateName) async {
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

  Future<void> _saveName(final Move move, final String newName) async {
    try {
      final orchestrator = ref.read(storageOrchestratorProvider);
      final updatedMove = await orchestrator.updateMoveName(move, newName);
      send(SaveSucceeded(updatedMove));
    } on Object catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveState(final Move move, final LearningState newState) async {
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
    } on Object catch (e, stack) {
      log.fail(e, stack);
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveCategory(final Move move, final String newCategory) async {
    try {
      final orchestrator = ref.read(storageOrchestratorProvider);
      final updatedMove = await orchestrator.updateMoveCategory(move, newCategory);
      send(SaveSucceeded(updatedMove));
    } on Object catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveCount(final Move move, final int newCount) async {
    try {
      await ref.read(moveRepositoryProvider).update(
        MovesCompanion(id: Value(move.id), count: Value(newCount)),
      );
      send(SaveSucceeded(move.copyWith(count: newCount)));
    } on Object catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveVideo(final Move move, final String localPath, final String originalFileName) async {
    final log = StageLogger.begin('_saveVideo', subsystem: 'MoveDetail', context: {
      'moveId': move.id,
      'localPath': localPath,
    });
    try {
      final engine = ref.read(storageActionMachineProvider);
      
      // 1. Materialize via Engine (Hot)
      final semanticRelative = await engine.execute(MaterializeAction(
        sourcePath: localPath,
        category: move.category,
        moveName: move.name,
      ));
      
      final contentHash = p.basenameWithoutExtension(semanticRelative.value).split(' - ').last;
      final resolvedAbs = VideoPathResolver.toAbsolute(semanticRelative.value);
      unawaited(ref.read(videoServiceProvider).generateThumbnail(resolvedAbs));

      await ref.read(moveRepositoryProvider).update(
            MovesCompanion(
              id: Value(move.id),
              videoPath: Value(semanticRelative.value),
              originalVideoName: Value(originalFileName),
              contentHash: Value(contentHash),
            ),
          );
      final updatedMove = move.copyWith(
        videoPath: Value(semanticRelative.value),
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
    } on Object catch (e, stack) {
      log.fail(e, stack);
      send(SaveFailed('$e'));
    }
  }

  Future<void> _removeVideo(final Move move) async {
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
    } on Object catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _deleteMove(final Move move) async {
    try {
      unawaited(HapticFeedback.mediumImpact());
      final orchestrator = ref.read(storageOrchestratorProvider);
      await orchestrator.deleteMove(
        move,
        cleanupMedia: (final m) => ref.read(mediaCleanupServiceProvider).cleanupMoveMedia(m),
      );
      send(const DeleteSucceeded());
    } on Object catch (e) {
      send(DeleteFailed('Delete failed: $e'));
    }
  }

  Future<void> _saveLogEntry(final Move move, final String body) async {
    try {
      final dao = ref.read(moveNoteEntriesDaoProvider);
      await dao.addEntry(id: const Uuid().v4(), moveId: move.id, body: body);
      send(SaveSucceeded(move));
    } on Object catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _deleteLogEntry(final Move move, final String entryId) async {
    try {
      final dao = ref.read(moveNoteEntriesDaoProvider);
      await dao.deleteEntry(entryId);
      send(SaveSucceeded(move));
    } on Object catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveNotes(final Move move, final String text) async {
    try {
      await ref.read(moveRepositoryProvider).update(
            MovesCompanion(
              id: Value(move.id),
              notes: Value(text.isEmpty ? null : text),
            ),
          );
      send(SaveSucceeded(move.copyWith(notes: Value(text.isEmpty ? null : text))));
    } on Object catch (e) {
      send(SaveFailed('$e'));
    }
  }
}

final moveDetailProvider = NotifierProvider<MoveDetailNotifier, MoveDetailState>(
  MoveDetailNotifier.new,
);
