import '../machine.dart';
import '../../../core/database/database.dart';

sealed class ComboDetailState {
  final Combo combo;
  const ComboDetailState(this.combo);
}

class Idle extends ComboDetailState {
  const Idle(super.combo);
}

class SavingNotes extends ComboDetailState {
  final String draftNotes;
  const SavingNotes(super.combo, {required this.draftNotes});
}

class Deleting extends ComboDetailState {
  const Deleting(super.combo);
}

class Gone extends ComboDetailState {
  const Gone(super.combo);
}

class ErrorState extends ComboDetailState {
  final String message;
  const ErrorState(super.combo, {required this.message});
}

sealed class ComboDetailEvent {}

class UpdateNotes extends ComboDetailEvent {
  final String notes;
  UpdateNotes(this.notes);
}

class TapDelete extends ComboDetailEvent {}

class ConfirmDelete extends ComboDetailEvent {}

class Cancel extends ComboDetailEvent {}

class SaveSucceeded extends ComboDetailEvent {
  final Combo combo;
  SaveSucceeded(this.combo);
}

class SaveFailed extends ComboDetailEvent {
  final String error;
  SaveFailed(this.error);
}

class DeleteSucceeded extends ComboDetailEvent {}

class DeleteFailed extends ComboDetailEvent {
  final String error;
  DeleteFailed(this.error);
}

class StreamUpdate extends ComboDetailEvent {
  final Combo combo;
  StreamUpdate(this.combo);
}

class ComboDetailMachine extends Machine<ComboDetailState, ComboDetailEvent> {
  ComboDetailMachine(super.initialState);

  @override
  ComboDetailState? transition(ComboDetailState s, ComboDetailEvent e) {
    return switch ((s, e)) {
      (Idle(), UpdateNotes e) => SavingNotes(s.combo, draftNotes: e.notes),
      (Idle(), TapDelete _) => Deleting(s.combo),
      (Idle(), StreamUpdate e) => Idle(e.combo),
      (SavingNotes(), SaveSucceeded e) => Idle(e.combo),
      (SavingNotes(), SaveFailed e) => ErrorState(s.combo, message: e.error),
      (Deleting(), ConfirmDelete _) => Deleting(s.combo), // Actual delete triggered by entry
      (Deleting(), Cancel _) => Idle(s.combo),
      (Deleting(), DeleteSucceeded _) => Gone(s.combo),
      (Deleting(), DeleteFailed e) => ErrorState(s.combo, message: e.error),
      (ErrorState(), Cancel _) => Idle(s.combo),
      _ => null,
    };
  }
}
