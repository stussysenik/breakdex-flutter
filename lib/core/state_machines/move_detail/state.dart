// ignore_for_file: unused_field

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/learning_state.dart';

/// All possible states of the move detail screen's CRUD surface.
sealed class MoveDetailState {
  final Move move;
  const MoveDetailState(this.move);
}

/// Viewing the move. All user actions are accepted.
final class Idle extends MoveDetailState {
  const Idle(super.move);
}

// ── Rename flow ──

final class Renaming extends MoveDetailState {
  final String draftName;
  const Renaming(super.move, {required this.draftName});
}

final class ValidatingName extends MoveDetailState {
  final String candidateName;
  const ValidatingName(super.move, {required this.candidateName});
}

final class NameConflict extends MoveDetailState {
  final String conflictingName;
  const NameConflict(super.move, {required this.conflictingName});
}

final class SavingName extends MoveDetailState {
  final String newName;
  const SavingName(super.move, {required this.newName});
}

final class AlbumSyncFailed extends MoveDetailState {
  final String message;
  const AlbumSyncFailed(super.move, {required this.message});
}

// ── State change ──

final class ChangingState extends MoveDetailState {
  const ChangingState(super.move);
}

final class SavingState extends MoveDetailState {
  final LearningState newState;
  const SavingState(super.move, {required this.newState});
}

// ── Category change ──

final class ChangingCategory extends MoveDetailState {
  const ChangingCategory(super.move);
}

final class SavingCategory extends MoveDetailState {
  final String newCategory;
  const SavingCategory(super.move, {required this.newCategory});
}

// ── Count change ──

final class ChangingCount extends MoveDetailState {
  const ChangingCount(super.move);
}

final class SavingCount extends MoveDetailState {
  final int newCount;
  const SavingCount(super.move, {required this.newCount});
}

// ── Delete flow ──

final class ConfirmingDelete extends MoveDetailState {
  final List<Combo> combos;
  const ConfirmingDelete(super.move, {required this.combos});
}

final class Deleting extends MoveDetailState {
  const Deleting(super.move);
}

/// Move has been deleted — trigger navigation back.
final class Gone extends MoveDetailState {
  const Gone(super.move);
}

// ── Video management ──

final class ConfirmingRemoveVideo extends MoveDetailState {
  const ConfirmingRemoveVideo(super.move);
}

final class RemovingVideo extends MoveDetailState {
  const RemovingVideo(super.move);
}

final class PickingVideo extends MoveDetailState {
  const PickingVideo(super.move);
}

final class SavingVideo extends MoveDetailState {
  final String localPath;
  final String originalFileName;
  const SavingVideo(
    super.move, {
    required this.localPath,
    required this.originalFileName,
  });
}

// ── Log entries ──

final class AddingLog extends MoveDetailState {
  const AddingLog(super.move);
}

final class SavingLog extends MoveDetailState {
  final String body;
  const SavingLog(super.move, {required this.body});
}

final class ConfirmingDeleteLog extends MoveDetailState {
  final String entryId;
  const ConfirmingDeleteLog(super.move, {required this.entryId});
}

final class DeletingLog extends MoveDetailState {
  final String entryId;
  const DeletingLog(super.move, {required this.entryId});
}

// ── Inline editing ──

final class NotesDirty extends MoveDetailState {
  final String draftText;
  const NotesDirty(super.move, {required this.draftText});
}

final class SavingNotes extends MoveDetailState {
  final String draftText;
  const SavingNotes(super.move, {required this.draftText});
}

final class SavingPhotos extends MoveDetailState {
  final String? json;
  const SavingPhotos(super.move, {required this.json});
}

final class Duplicating extends MoveDetailState {
  const Duplicating(super.move);
}

// ── Error ──

final class ErrorState extends MoveDetailState {
  final String message;
  const ErrorState(super.move, {required this.message});
}
