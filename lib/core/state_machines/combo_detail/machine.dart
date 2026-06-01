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

class ConfirmingDelete extends ComboDetailState {
  const ConfirmingDelete(super.combo);
}

class Deleting extends ComboDetailState {
  const Deleting(super.combo);
}

class Gone extends ComboDetailState {
  const Gone(super.combo);
}

class AddingLog extends ComboDetailState {
  const AddingLog(super.combo);
}

class SavingLog extends ComboDetailState {
  final String body;
  const SavingLog(super.combo, {required this.body});
}

class ConfirmingDeleteLog extends ComboDetailState {
  final String entryId;
  const ConfirmingDeleteLog(super.combo, {required this.entryId});
}

class DeletingLog extends ComboDetailState {
  final String entryId;
  const DeletingLog(super.combo, {required this.entryId});
}

class NotesDirty extends ComboDetailState {
  final String draftText;
  const NotesDirty(super.combo, {required this.draftText});
}

class ErrorState extends ComboDetailState {
  final String message;
  const ErrorState(super.combo, {required this.message});
}

sealed class ComboDetailEvent {}

class UpdateNotes extends ComboDetailEvent {
  final String text;
  UpdateNotes(this.text);
}

class TapDelete extends ComboDetailEvent {}

class ConfirmDelete extends ComboDetailEvent {}

class Cancel extends ComboDetailEvent {}

class TapAddLog extends ComboDetailEvent {}

class SaveLogBody extends ComboDetailEvent {
  final String body;
  SaveLogBody(this.body);
}

class TapDeleteLog extends ComboDetailEvent {
  final String entryId;
  TapDeleteLog(this.entryId);
}

class Confirm extends ComboDetailEvent {}

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
  String get diagnosticsLabel => 'ComboDetail';

  @override
  ComboDetailState? transition(final ComboDetailState s, final ComboDetailEvent e) {
    return switch ((s, e)) {
      // ── Notes ──
      (Idle(), final UpdateNotes e) => SavingNotes(s.combo, draftNotes: e.text),
      (SavingNotes(), final UpdateNotes e) => SavingNotes(s.combo, draftNotes: e.text),
      (SavingNotes(), final SaveSucceeded e) => Idle(e.combo),
      (SavingNotes(), final SaveFailed e) => ErrorState(s.combo, message: e.error),
      (NotesDirty(), UpdateNotes(text: final t)) => NotesDirty(s.combo, draftText: t),
      (NotesDirty(), SaveSucceeded(combo: final _)) => Idle(s.combo),
      (NotesDirty(), SaveFailed(error: final e)) => ErrorState(s.combo, message: e),

      // ── Delete flow ──
      (Idle(), TapDelete _) => Deleting(s.combo),
      (Idle(), ConfirmDelete _) => Deleting(s.combo),
      (Idle(), final StreamUpdate e) => Idle(e.combo),
      (Deleting(), ConfirmDelete _) => Deleting(s.combo),
      (Deleting(), Cancel _) => Idle(s.combo),
      (Deleting(), DeleteSucceeded _) => Gone(s.combo),
      (Deleting(), final DeleteFailed e) => ErrorState(s.combo, message: e.error),

      // ── Log entries ──
      (Idle(), TapAddLog _) => AddingLog(s.combo),
      (AddingLog(), SaveLogBody(body: final b)) => SavingLog(s.combo, body: b),
      (AddingLog(), Cancel _) => Idle(s.combo),
      (SavingLog(), SaveSucceeded(combo: final _)) => Idle(s.combo),
      (SavingLog(), SaveFailed(error: final e)) => ErrorState(s.combo, message: e),

      (Idle(), TapDeleteLog(entryId: final eid)) => ConfirmingDeleteLog(s.combo, entryId: eid),
      (ConfirmingDeleteLog(entryId: final _), Confirm _) => Idle(s.combo),
      (ConfirmingDeleteLog(entryId: final eid), Cancel _) => DeletingLog(s.combo, entryId: eid),
      (DeletingLog(), SaveSucceeded(combo: final _)) => Idle(s.combo),
      (DeletingLog(), SaveFailed(error: final e)) => ErrorState(s.combo, message: e),

      // ── Error recovery ──
      (ErrorState(), Cancel _) => Idle(s.combo),

      _ => null,
    };
  }
}
