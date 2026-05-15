## 1. Core State Machine Infrastructure

- [ ] 1.1 Create `lib/core/state_machines/` directory structure
- [ ] 1.2 Implement `Machine<S, E>` base class with sealed `S` and `E` generics, pure `transition` function, `send` method, `onEntry`/`onExit` hooks
- [ ] 1.3 Implement hierarchical child machine composition in base `Machine` class
- [ ] 1.4 Write unit tests for `Machine`: valid transitions, invalid transitions ignored, entry/exit hook invocation, child delegation
- [ ] 1.5 Create Riverpod `machineProvider` factory for scoping machines to widget lifecycle

## 2. Replace DeleteStateMachine

- [ ] 2.1 Define sealed states for `TrashMachine`: `Viewing`, `ConfirmingTrash`, `Trashing`, `Trashed`, `ConfirmingRestore`, `Restoring`, `ConfirmingPurge`, `Purging`, `Failed`
- [ ] 2.2 Define sealed events: `TapTrash(hash, reason)`, `TapRestore(hash)`, `TapPurge`, `Confirm`, `Cancel`, `TrashSucceeded`, `TrashFailed`, `RestoreSucceeded`, `RestoreFailed`, `PurgeSucceeded`, `PurgeFailed`
- [ ] 2.3 Implement `TrashMachine` transition function and entry actions (DB writes, file deletion, ledger updates)
- [ ] 2.4 Replace all references to `DeleteStateMachine` with `TrashMachine` in providers and consumers
- [ ] 2.5 Delete `lib/core/services/delete_state_machine.dart`
- [ ] 2.6 Run existing trash/restore tests and verify they pass

## 3. Move Detail State Machine

- [ ] 3.1 Define sealed `MoveDetailState` hierarchy: `Idle`, `Renaming`, `ValidatingName`, `NameConflict`, `SavingName`, `AlbumSyncFailed`, `ChangingState`, `SavingState`, `ChangingCategory`, `SavingCategory`, `ChangingCount`, `SavingCount`, `ConfirmingDelete`, `Deleting`, `Gone`, `ConfirmingRemoveVideo`, `RemovingVideo`, `PickingVideo`, `SavingVideo`, `AddingLog`, `SavingLog`, `ConfirmingDeleteLog`, `DeletingLog`, `NotesDirty`, `SavingNotes`, `PhotosDirty`, `SavingPhotos`
- [ ] 3.2 Define sealed `MoveDetailEvent` hierarchy: all user intents, async results, and stream update events
- [ ] 3.3 Implement `MoveDetailMachine` transition function with all valid transitions; invalid transitions return null
- [ ] 3.4 Implement entry actions: DB writes via `moveRepositoryProvider`, album sync, media cleanup, video import hook
- [ ] 3.5 Implement `NameValidating` entry action: call `ReviewableNamingService.isNameTaken` and send `NameAvailable`/`NameTaken`
- [ ] 3.6 Implement stream gating: only update move context in `Idle` state; ignore during all other states

## 4. Move Detail Inline Overlays

- [ ] 4.1 Rewrite `MoveDetailScreen.build()` to render a `Stack` with main content + state-gated overlays
- [ ] 4.2 Extract `_RenameOverlay` from current `_rename` dialog code, wire to machine `SaveName`/`Cancel` events
- [ ] 4.3 Extract `_DeleteConfirmOverlay` showing full cascade scope, wire to machine `Confirm`/`Cancel` events
- [ ] 4.4 Extract `_CountEditorOverlay` from `_CountEditor`, wire to machine events
- [ ] 4.5 Extract `_StatePickerOverlay` from `StatePickerSheet`, wire to machine events
- [ ] 4.6 Extract `_CategoryPickerOverlay` from category bottom sheet, wire to machine events
- [ ] 4.7 Extract `_RemoveVideoOverlay` from `_removeVideo` dialog, wire to machine events
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
- [ ] 6.3 Wire add screen to consume machine state for type selection, creation, validation

## 7. Fix Restored Moves Bug

- [ ] 7.1 Trace the full path from `video_reliability_runtime` cold-start → `restoredLocally` counter → notification
- [ ] 7.2 Add distinction between "video-only restoration" and "move restoration" in the reliability report
- [ ] 7.3 Update `canonical_reconcile_service.recoverOrphansLocally` to not create move rows (manifest-only updates)
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
