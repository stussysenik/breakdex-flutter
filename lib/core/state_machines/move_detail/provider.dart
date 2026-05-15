import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../database/database.dart';
import '../../models/learning_state.dart';
import '../../providers.dart';
import '../../services/video_path_resolver.dart';
import 'state.dart';
import 'event.dart';
import 'machine.dart';

/// Riverpod Notifier wrapping a MoveDetailMachine for a specific move.
///
/// The machine is lazily initialized the first time [send] is called.
/// Stream updates from the database are forwarded as [StreamUpdate] events.
class MoveDetailNotifier extends Notifier<MoveDetailState> {
  MoveDetailMachine? _machine;

  MoveDetailMachine get _m {
    assert(_machine != null, 'Machine not initialized. Call send() first.');
    return _machine!;
  }

  @override
  MoveDetailState build() {
    ref.onDispose(() {
      _machine = null;
    });
    // Return a placeholder that the UI will filter out
    return ErrorState(
      _emptyMove,
      message: 'Not initialized',
    );
  }

  static final _emptyMove = Move(
    id: '',
    name: '',
    category: 'default',
    count: 0,
    learningState: 'new',
    createdAt: DateTime.now(),
  );

  /// Initialize the machine with the given move data.
  void init(Move move) {
    _machine = MoveDetailMachine(Idle(move));
    state = _machine!.state;
  }

  /// Dispatch an event to the machine. Side effects execute automatically.
  void send(MoveDetailEvent event) {
    if (_machine == null) return;

    // Stream updates are only accepted in Idle
    if (event is StreamUpdate && _m.state is! Idle) return;

    _m.send(event);
    _executeEntryActions(_m.state);
    state = _m.state;
  }

  void _executeEntryActions(MoveDetailState state) {
    switch (state) {
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
      case Deleting(:final move):
        _deleteMove(move);
      case RemovingVideo(:final move):
        _removeVideo(move);
      case SavingVideo(:final move, :final localPath, :final originalFileName):
        _saveVideo(move, localPath, originalFileName);
      case SavingLog(:final move, :final body):
        _saveLogEntry(move, body);
      case DeletingLog(:final move, :final entryId):
        _deleteLogEntry(move, entryId);
      case SavingNotes(:final move, :final draftText):
        _saveNotes(move, draftText);
      default:
        break;
    }
  }

  // ── Side effect methods ──

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
      await ref.read(moveRepositoryProvider).update(
        MovesCompanion(id: Value(move.id), name: Value(newName)),
      );
      send(SaveSucceeded(move.copyWith(name: newName)));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveState(Move move, LearningState newState) async {
    try {
      await ref.read(moveRepositoryProvider).update(
        MovesCompanion(
          id: Value(move.id),
          learningState: Value(newState.name),
        ),
      );
      send(SaveSucceeded(move.copyWith(learningState: newState.name)));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveCategory(Move move, String newCategory) async {
    try {
      await ref.read(moveRepositoryProvider).update(
        MovesCompanion(id: Value(move.id), category: Value(newCategory)),
      );
      send(SaveSucceeded(move.copyWith(category: newCategory)));
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

  Future<void> _deleteMove(Move move) async {
    try {
      unawaited(HapticFeedback.mediumImpact());
      await ref.read(mediaCleanupServiceProvider).cleanupMoveMedia(move);
      await ref.read(moveRepositoryProvider).delete(move.id);
      send(const DeleteSucceeded());
    } catch (e) {
      send(DeleteFailed('$e'));
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
      send(SaveSucceeded(
        move.copyWith(
          videoPath: const Value(null),
          originalVideoName: const Value(null),
          managedAlbumAssetId: const Value(null),
          managedAlbumFilename: const Value(null),
          managedAlbumName: const Value(null),
          contentHash: const Value(null),
        ),
      ));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _saveVideo(
    Move move, String localPath, String originalFileName,
  ) async {
    try {
      final relativePath = VideoPathResolver.toRelative(localPath);
      await ref.read(moveRepositoryProvider).update(
        MovesCompanion(
          id: Value(move.id),
          videoPath: Value(relativePath),
          originalVideoName: Value(originalFileName),
          managedAlbumAssetId: const Value(null),
          managedAlbumFilename: const Value(null),
          managedAlbumName: const Value(null),
          contentHash: const Value(null),
        ),
      );
      send(SaveSucceeded(
        move.copyWith(
          videoPath: Value(relativePath),
          originalVideoName: Value(originalFileName),
        ),
      ));
    } catch (e) {
      send(SaveFailed('$e'));
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
      send(SaveSucceeded(
        move.copyWith(notes: Value(text.isEmpty ? null : text)),
      ));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }
}

/// Provider for the MoveDetail state machine.
///
/// Initialize with `ref.read(moveDetailProvider.notifier).init(move)` before use.
final moveDetailProvider =
    NotifierProvider<MoveDetailNotifier, MoveDetailState>(
  MoveDetailNotifier.new,
);