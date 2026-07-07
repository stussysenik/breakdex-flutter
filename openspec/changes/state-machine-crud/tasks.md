## Residual (verified 2026-07-06 audit)

Evidence-based audit of all 51 tasks against `lib/core/state_machines/` and the consuming
screens (`move_detail_screen.dart`, `add_screen.dart`, `move_detail/widgets/`). Result:
~22 SHIPPED, ~6 PARTIAL, ~23 OPEN. The `Machine<S,E>` framework and the **move-detail
vertical** are shipped and wired into production; the app-wide hierarchical vision
(TrashMachine, MoveListMachine, AppMachine) is not started. Below are only the items that
are genuinely PARTIAL or OPEN — do not re-tick shipped rows.

- **1.5 PARTIAL** — no generic `machineProvider` factory; per-machine `NotifierProvider`s
  serve the role instead (`move_detail/provider.dart`, `move_creation/provider.dart`).
- **2.1–2.6 OPEN** — `TrashMachine` not started; `lib/core/services/delete_state_machine.dart`
  still present, only self-referenced.
- **4.3 PARTIAL** — delete-confirm overlay shows only combo count, not the full cascade
  (reviews, achievements, log entries, aura links).
- **4.8 OPEN** — video pick still a modal bottom sheet (`VideoPickerSheet.show()`); the
  `PickingVideo` machine state is not consumed by the UI.
- **4.9 / 4.10 OPEN** — log add + log-delete-confirm overlays never wired to UI; the
  `AddingLog`/`SavingLog`/`ConfirmingDeleteLog` states exist but are unused by the screen
  (log-delete confirmation — the "currently missing" item — is still missing at the UI layer).
- **4.11 OPEN** — notes debounce + `NotesDirty`→`SavingNotes` path missing; notes do not
  persist through the machine.
- **4.12 PARTIAL** — photos auto-save is wired but immediate (no 500ms debounce).
- **4.13 OPEN** — no `AnimatedOpacity`/`AnimatedScale` on dialog overlays.
- **5.1–5.4 OPEN** — `MoveListMachine` not started.
- **6.1 / 6.2 PARTIAL** — `MoveCreationMachine` exists but lacks the spec states
  `ChoosingType`/`ValidatingMoveName`/`MoveNameConflict` and their name-validation entry actions.
- **7.1 / 7.2 / 7.4 OPEN** — restored-moves notification distinction + verification not
  evidenced (no such notification exists in code). 7.3 shipped (manifest-only recover).
- **8.1–8.4 OPEN** — `AppMachine` / hierarchical root integration not started.
- **9.1–9.6 OPEN** — validation + manual smokes not run (9.4 would fail today, given 4.10).

> Ledger ruling (align-cross-client-foundations D8): this change is **kept open** as the
> tracker for the residual work above rather than archived, because a material slice
> (TrashMachine, MoveListMachine, AppMachine, notes/logs overlays) is genuinely unshipped.

---

## 1. Core State Machine Infrastructure

- [x] 1.1 Create `lib/core/state_machines/` directory structure
- [x] 1.2 Implement `Machine<S, E>` base class with sealed `S` and `E` generics, pure `transition` function, `send` method, `onEntry`/`onExit` hooks
- [x] 1.3 Implement hierarchical child machine composition in base `Machine` class
- [x] 1.4 Write unit tests for `Machine`: valid transitions, invalid transitions ignored, entry/exit hook invocation, child delegation
- [ ] 1.5 Create Riverpod `machineProvider` factory for scoping machines to widget lifecycle

## 2. Replace DeleteStateMachine

- [ ] 2.1 Define sealed states for `TrashMachine`: `Viewing`, `ConfirmingTrash`, `Trashing`, `Trashed`, `ConfirmingRestore`, `Restoring`, `ConfirmingPurge`, `Purging`, `Failed`
- [ ] 2.2 Define sealed events: `TapTrash(hash, reason)`, `TapRestore(hash)`, `TapPurge`, `Confirm`, `Cancel`, `TrashSucceeded`, `TrashFailed`, `RestoreSucceeded`, `RestoreFailed`, `PurgeSucceeded`, `PurgeFailed`
- [ ] 2.3 Implement `TrashMachine` transition function and entry actions (DB writes, file deletion, ledger updates)
- [ ] 2.4 Replace all references to `DeleteStateMachine` with `TrashMachine` in providers and consumers
- [ ] 2.5 Delete `lib/core/services/delete_state_machine.dart`
- [ ] 2.6 Run existing trash/restore tests and verify they pass

## 3. Move Detail State Machine

- [x] 3.1 Define sealed `MoveDetailState` hierarchy: `Idle`, `Renaming`, `ValidatingName`, `NameConflict`, `SavingName`, `AlbumSyncFailed`, `ChangingState`, `SavingState`, `ChangingCategory`, `SavingCategory`, `ChangingCount`, `SavingCount`, `ConfirmingDelete`, `Deleting`, `Gone`, `ConfirmingRemoveVideo`, `RemovingVideo`, `PickingVideo`, `SavingVideo`, `AddingLog`, `SavingLog`, `ConfirmingDeleteLog`, `DeletingLog`, `NotesDirty`, `SavingNotes`, `PhotosDirty`, `SavingPhotos`
- [x] 3.2 Define sealed `MoveDetailEvent` hierarchy: all user intents, async results, and stream update events
- [x] 3.3 Implement `MoveDetailMachine` transition function with all valid transitions; invalid transitions return null
- [x] 3.4 Implement entry actions: DB writes via `moveRepositoryProvider`, album sync, media cleanup, video import hook
- [x] 3.5 Implement `NameValidating` entry action: call `ReviewableNamingService.isNameTaken` and send `NameAvailable`/`NameTaken`
- [x] 3.6 Implement stream gating: only update move context in `Idle` state; ignore during all other states

## 4. Move Detail Inline Overlays

- [x] 4.1 Rewrite `MoveDetailScreen.build()` to render a `Stack` with main content + state-gated overlays
- [x] 4.2 Extract `_RenameOverlay` from current `_rename` dialog code, wire to machine `SaveName`/`Cancel` events
- [ ] 4.3 Extract `_DeleteConfirmOverlay` showing full cascade scope, wire to machine `Confirm`/`Cancel` events
- [x] 4.4 Extract `_CountEditorOverlay` from `_CountEditor`, wire to machine events
- [x] 4.5 Extract `_StatePickerOverlay` from `StatePickerSheet`, wire to machine events
- [x] 4.6 Extract `_CategoryPickerOverlay` from category bottom sheet, wire to machine events
- [x] 4.7 Extract `_RemoveVideoOverlay` from `_removeVideo` dialog, wire to machine events
- [ ] 4.8 Extract `_VideoPickerOverlay` from `VideoPickerSheet`, wire to machine events
- [ ] 4.9 Extract `_LogEntryOverlay` from `_addLogEntry` dialog, wire to machine events
- [ ] 4.10 Extract `_DeleteLogConfirmOverlay` (NEW — currently missing), wire to machine events
- [ ] 4.11 Wire notes `onChanged` to `NotesDirty` state with 500ms debounce → `SavingNotes`
- [ ] 4.12 Wire photos `onChanged` to `PhotosDirty` state with 500ms debounce → `SavingPhotos`
- [ ] 4.13 Apply `AnimatedOpacity` + `AnimatedScale` to overlays for native dialog feel

## 5. Move List State Machine

- [ ] 5.1 Define sealed `MoveListState` and `MoveListEvent` types
- [ ] 5.2 Implement `MoveListMachine` with delete confirmation workflow
- [ ] 5.3 Wire move list screen to consume machine state for delete operations
- [ ] 5.4 Ensure list refreshes after delete completes (invalidate repository provider on `Gone`)

## 6. Add Screen State Machine

- [ ] 6.1 Define sealed `AddState` and `AddEvent` types: `ChoosingType`, `CreatingMove`, `ValidatingMoveName`, `MoveNameConflict`, `SavingMove`, `Error`
- [ ] 6.2 Implement `AddMachine` transition function and entry actions
- [x] 6.3 Wire add screen to consume machine state for type selection, creation, validation

## 7. Fix Restored Moves Bug

- [ ] 7.1 Trace the full path from `video_reliability_runtime` cold-start → `restoredLocally` counter → notification
- [ ] 7.2 Add distinction between "video-only restoration" and "move restoration" in the reliability report
- [x] 7.3 Update `canonical_reconcile_service.recoverOrphansLocally` to not create move rows (manifest-only updates)
- [ ] 7.4 Verify fix: cold start should not show spurious restored moves notifications

## 8. App-Level Machine Integration

- [ ] 8.1 Create `AppMachine` as root machine with child registration and event routing
- [ ] 8.2 Register `MoveListMachine`, `MoveDetailMachine`, `AddMachine`, `TrashMachine` as children
- [ ] 8.3 Implement GoRouter location → active child mapping for event routing
- [ ] 8.4 Add cross-machine event broadcasting (e.g., move deleted → invalidate list)

## 9. Validation & Cleanup

- [ ] 9.1 Run `flutter analyze` — ensure all sealed class switches are exhaustive
- [ ] 9.2 Run `flutter test` — all existing tests pass
- [ ] 9.3 Manual smoke test: tap rename while delete confirmation is open → delete ignored
- [ ] 9.4 Manual smoke test: delete log entry → confirmation appears
- [ ] 9.5 Manual smoke test: rename with duplicate name → conflict error shown, user can retry
- [ ] 9.6 Manual smoke test: cold start → no spurious restored moves notification
