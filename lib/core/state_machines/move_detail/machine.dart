import 'package:path/path.dart' as p;

import '../machine.dart';
import 'state.dart';
import 'event.dart';

/// Pure state machine for the move detail screen CRUD operations.
///
/// The transition function is pure — no side effects. Side effects
/// (DB writes, album sync, navigation) execute in the provider's
/// entry action hooks.
final class MoveDetailMachine extends Machine<MoveDetailState, MoveDetailEvent> {
  MoveDetailMachine(super.initialState);

  @override
  MoveDetailState? transition(MoveDetailState s, MoveDetailEvent e) {
    return switch ((s, e)) {
      // ── Idle → Editing ──
      (Idle(), TapRename()) =>
        Renaming(s.move, draftName: s.move.name),
      (Idle(), TapChangeState()) => ChangingState(s.move),
      (Idle(), TapChangeCategory()) => ChangingCategory(s.move),
      (Idle(), TapChangeCount()) => ChangingCount(s.move),
      (Idle(), TapAddVideo()) => PickingVideo(s.move),
      (Idle(), VideoEdited(newPath: final path)) => SavingVideo(
        s.move,
        localPath: path,
        originalFileName: p.basename(path),
      ),
      (Idle(), TapRemoveVideo()) => ConfirmingRemoveVideo(s.move),
      (Idle(), TapAddLog()) => AddingLog(s.move),
      (Idle(), TapDeleteLog(entryId: final entryId)) =>
        ConfirmingDeleteLog(s.move, entryId: entryId),

      // ── Idle → Destructive (requires confirm) ──
      (Idle(), TapDelete()) => ConfirmingDelete(s.move),

      // ── Idle → Inline edit ──
      (Idle(), UpdateNotes(text: final text)) =>
        NotesDirty(s.move, draftText: text),

      // ── Idle → Stream update (only accepted in Idle) ──
      (Idle(), StreamUpdate(move: final m)) => Idle(m),

      // ── Renaming flow ──
      (Renaming(), UpdateDraft(name: final n)) =>
        Renaming(s.move, draftName: n),
      (Renaming(), Cancel()) => Idle(s.move),
      (Renaming(), SaveName(name: final n)) =>
        ValidatingName(s.move, candidateName: n),

      (ValidatingName(candidateName: final cn), NameAvailable()) =>
        SavingName(s.move, newName: cn),
      (ValidatingName(candidateName: final cn), NameTaken()) =>
        NameConflict(s.move, conflictingName: cn),

      (NameConflict(), UpdateDraft(name: final n)) =>
        Renaming(s.move, draftName: n),
      (NameConflict(), Cancel()) => Idle(s.move),

      (SavingName(), SaveSucceeded(move: final m)) => Idle(m),
      (SavingName(), SaveFailed()) => Idle(s.move),
      (SavingName(), AlbumSyncFailedEvent(message: final msg)) =>
        AlbumSyncFailed(s.move, message: msg),

      (AlbumSyncFailed(), Cancel()) => Idle(s.move),

      // ── State change ──
      (ChangingState(), Cancel()) => Idle(s.move),
      (ChangingState(), SaveState(learningState: final st)) =>
        SavingState(s.move, newState: st),
      (SavingState(), SaveSucceeded(move: final m)) => Idle(m),
      (SavingState(), SaveFailed()) => Idle(s.move),

      // ── Category change ──
      (ChangingCategory(), Cancel()) => Idle(s.move),
      (ChangingCategory(), SaveCategory(category: final c)) =>
        SavingCategory(s.move, newCategory: c),
      (SavingCategory(), SaveSucceeded(move: final m)) => Idle(m),
      (SavingCategory(), SaveFailed()) => Idle(s.move),

      // ── Count change ──
      (ChangingCount(), Cancel()) => Idle(s.move),
      (ChangingCount(), SaveCount(count: final c)) =>
        SavingCount(s.move, newCount: c),
      (SavingCount(), SaveSucceeded(move: final m)) => Idle(m),
      (SavingCount(), SaveFailed()) => Idle(s.move),

      // ── Delete flow ──
      (ConfirmingDelete(), Cancel()) => Idle(s.move),
      (ConfirmingDelete(), Confirm()) => Deleting(s.move),
      (Deleting(), DeleteSucceeded()) => Gone(s.move),
      (Deleting(), DeleteFailed()) => Idle(s.move),

      // ── Remove video ──
      (ConfirmingRemoveVideo(), Cancel()) => Idle(s.move),
      (ConfirmingRemoveVideo(), Confirm()) => RemovingVideo(s.move),
      (RemovingVideo(), SaveSucceeded(move: final m)) => Idle(m),
      (RemovingVideo(), SaveFailed()) => Idle(s.move),

      // ── Video picker ──
      (PickingVideo(), VideoPicked(localPath: final p, originalFileName: final n)) =>
        SavingVideo(s.move, localPath: p, originalFileName: n),
      (PickingVideo(), VideoPickCancelled()) => Idle(s.move),
      (SavingVideo(), SaveSucceeded(move: final m)) => Idle(m),
      (SavingVideo(), SaveFailed()) => Idle(s.move),

      // ── Log entries ──
      (AddingLog(), Cancel()) => Idle(s.move),
      (AddingLog(), SaveLogBody(body: final b)) =>
        SavingLog(s.move, body: b),
      (SavingLog(), SaveSucceeded(move: final m)) => Idle(m),
      (SavingLog(), SaveFailed()) => Idle(s.move),

      (ConfirmingDeleteLog(entryId: final _), Cancel()) =>
        Idle(s.move),
      (ConfirmingDeleteLog(entryId: final eid), Confirm()) =>
        DeletingLog(s.move, entryId: eid),
      (DeletingLog(), SaveSucceeded(move: final m)) => Idle(m),
      (DeletingLog(), SaveFailed()) => Idle(s.move),

      // ── Notes inline ──
      (NotesDirty(), UpdateNotes(text: final t)) =>
        NotesDirty(s.move, draftText: t),
      (NotesDirty(), SaveSucceeded(move: final m)) => Idle(m),
      (NotesDirty(), SaveFailed()) => Idle(s.move),
      (SavingNotes(), SaveSucceeded(move: final m)) => Idle(m),
      (SavingNotes(), SaveFailed()) => Idle(s.move),

      // ── Photos inline ──
      (Idle(), UpdatePhotos(json: final j)) => SavingPhotos(s.move, json: j),
      (SavingPhotos(), SaveSucceeded(move: final m)) => Idle(m),
      (SavingPhotos(), SaveFailed()) => Idle(s.move),

      // ── Error recovery ──
      (ErrorState(), Cancel()) => Idle(s.move),

      // ── Everything else: invalid → ignore ──
      _ => null,
    };
  }
}
