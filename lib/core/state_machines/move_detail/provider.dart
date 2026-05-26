import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../database/database.dart';
import '../../models/learning_state.dart';
import '../../models/reviewable_item.dart';
import '../../providers.dart';
import '../../services/video_path_resolver.dart';
import '../../services/native_video_album.dart';
import 'state.dart';
import 'event.dart';
import 'machine.dart';

/// Riverpod Notifier wrapping a MoveDetailMachine for a specific move.
///
/// It translates machine states with side-effect potential (e.g. `SavingName`)
/// into actual asynchronous calls and feeds the results back as events.
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
    // Reset machine state too
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
      default:
        break;
    }
  }

  // ── Side effect methods ──

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

      // "Magic" Photos Sync: Add to album with new name
      if (updatedMove.videoPath != null) {
        try {
          final album = ref.read(nativeVideoAlbumProvider);
          final copy = await album.saveToAlbum(
            videoPath: updatedMove.resolvedVideoPath!,
            albumName: NativeVideoAlbum.defaultAlbumName(),
            assetTitle: newName,
            category: updatedMove.category,
          );
          if (copy != null) {
            final companion = MovesCompanion(
              id: Value(move.id),
              managedAlbumAssetId: Value(copy.assetLocalIdentifier),
              managedAlbumFilename: Value(copy.filename),
              managedAlbumName: Value(copy.albumName),
            );
            await ref.read(moveRepositoryProvider).update(companion);
            updatedMove = updatedMove.copyWith(
              managedAlbumAssetId: Value(copy.assetLocalIdentifier),
              managedAlbumFilename: Value(copy.filename),
              managedAlbumName: Value(copy.albumName),
            );
          }
        } catch (e) {
          debugPrint('[MoveDetailNotifier] Photos sync failed (non-fatal): $e');
        }
      }

      send(SaveSucceeded(updatedMove));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveState(Move move, LearningState newState) async {
    try {
      await ref.read(manualReviewStateServiceProvider).setMoveState(
        move,
        newState,
      );
      send(SaveSucceeded(move.copyWith(learningState: newState.name)));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveCategory(Move move, String newCategory) async {
    try {
      final orchestrator = ref.read(storageOrchestratorProvider);
      var updatedMove = await orchestrator.updateMoveCategory(move, newCategory);

      // "Magic" Photos Sync: Add to album with new category
      if (updatedMove.videoPath != null) {
        try {
          final album = ref.read(nativeVideoAlbumProvider);
          final copy = await album.saveToAlbum(
            videoPath: updatedMove.resolvedVideoPath!,
            albumName: NativeVideoAlbum.defaultAlbumName(),
            assetTitle: move.name,
            category: newCategory,
          );
          if (copy != null) {
            final companion = MovesCompanion(
              id: Value(move.id),
              managedAlbumAssetId: Value(copy.assetLocalIdentifier),
              managedAlbumFilename: Value(copy.filename),
              managedAlbumName: Value(copy.albumName),
            );
            await ref.read(moveRepositoryProvider).update(companion);
            updatedMove = updatedMove.copyWith(
              managedAlbumAssetId: Value(copy.assetLocalIdentifier),
              managedAlbumFilename: Value(copy.filename),
              managedAlbumName: Value(copy.albumName),
            );
          }
        } catch (e) {
          debugPrint('[MoveDetailNotifier] Photos sync failed (non-fatal): $e');
        }
      }

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

  Future<void> _saveVideo(
    Move move,
    String localPath,
    String originalFileName,
  ) async {
    try {
      // 1. Cleanup old assets (detach but keep if others use it)
      await ref.read(mediaCleanupServiceProvider).cleanupDetachedAsset(
            title: move.name,
            category: move.category,
            storedVideoPath: move.videoPath,
            resolvedVideoPath: move.resolvedVideoPath,
            contentHash: move.contentHash,
            managedAlbumAssetId: move.managedAlbumAssetId,
            excludingMoveId: move.id,
            skipPhotosCleanup: true,
          );

      // 2. "Magic" Disk Move: move to semantic path
      final semanticRelative = await VideoPathResolver.moveToSemanticPath(
        currentRelativePath: VideoPathResolver.toRelative(localPath),
        category: move.category,
        moveName: move.name,
      );

      // 3. Compute SHA-256 hash (the content truth)
      final resolvedAbs = VideoPathResolver.toAbsolute(semanticRelative);
      final contentHash = await ref.read(assetHashServiceProvider).computeHash(resolvedAbs);

      // 4. Update DB with final path and content hash
      await ref.read(moveRepositoryProvider).update(
            MovesCompanion(
              id: Value(move.id),
              videoPath: Value(semanticRelative),
              originalVideoName: Value(originalFileName),
              managedAlbumAssetId: const Value(null),
              managedAlbumFilename: const Value(null),
              managedAlbumName: const Value(null),
              contentHash: Value(contentHash),
            ),
          );

      var updatedMove = move.copyWith(
        videoPath: Value(semanticRelative),
        originalVideoName: Value(originalFileName),
        managedAlbumAssetId: const Value(null),
        managedAlbumFilename: const Value(null),
        managedAlbumName: const Value(null),
        contentHash: Value(contentHash),
      );

      // 4. "Magic" Photos Sync: Add to album (don't delete old to avoid prompt)
      try {
        final album = ref.read(nativeVideoAlbumProvider);
        final copy = await album.saveToAlbum(
          videoPath: updatedMove.resolvedVideoPath!,
          albumName: NativeVideoAlbum.defaultAlbumName(),
          assetTitle: move.name,
          category: move.category,
        );
        if (copy != null) {
          await ref.read(moveRepositoryProvider).update(
                MovesCompanion(
                  id: Value(move.id),
                  managedAlbumAssetId: Value(copy.assetLocalIdentifier),
                  managedAlbumFilename: Value(copy.filename),
                  managedAlbumName: Value(copy.albumName),
                ),
              );
          updatedMove = updatedMove.copyWith(
            managedAlbumAssetId: Value(copy.assetLocalIdentifier),
            managedAlbumFilename: Value(copy.filename),
            managedAlbumName: Value(copy.albumName),
          );
        }
      } catch (e) {
        debugPrint('[MoveDetailNotifier] Photos sync failed (non-fatal): $e');
      }

      // 5. Fire sync hook (manifest, copies, upload) with precomputed hash
      unawaited(ref.read(videoImportSyncHookProvider).onVideoImported(
        localPath: resolvedAbs,
        moveId: move.id,
        precomputedHash: contentHash,
      ));

      send(SaveSucceeded(updatedMove));
    } catch (e) {
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
              managedAlbumAssetId: const Value(null),
              managedAlbumFilename: const Value(null),
              managedAlbumName: const Value(null),
              contentHash: const Value(null),
            ),
          );
      send(
        SaveSucceeded(
          move.copyWith(
            videoPath: const Value(null),
            originalVideoName: const Value(null),
            managedAlbumAssetId: const Value(null),
            managedAlbumFilename: const Value(null),
            managedAlbumName: const Value(null),
            contentHash: const Value(null),
          ),
        ),
      );
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _deleteMove(Move move) async {
    try {
      unawaited(HapticFeedback.mediumImpact());
      final orchestrator = ref.read(storageOrchestratorProvider);
      await orchestrator.deleteMove(
        move,
        cleanupMedia: (m) => ref.read(mediaCleanupServiceProvider).cleanupMoveMedia(m),
      );
      send(const DeleteSucceeded());
    } catch (e) {
      send(DeleteFailed('$e'));
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
