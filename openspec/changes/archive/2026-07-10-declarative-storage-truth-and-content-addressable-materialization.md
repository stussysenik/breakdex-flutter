# OpenSpec: Declarative Storage Truth & Content-Addressable Materialization

## Why
Current storage management is fragmented across `MoveCreationService`, `MoveDetailNotifier`, `StorageOrchestrator`, and `VideoPathHealer`. This fragmentation leads to:
1. **Truth Drift**: Database records pointing to non-existent files.
2. **Zombie Files**: Files with `Name - Hash.mp4` format existing alongside empty `Name/` folders.
3. **Manual Side Effects**: UI Providers manually copying files instead of declaring an intent to move.
4. **Weak Cleanup**: Deletions are unawaited, leaving artifacts on disk.
5. **Indeterminate UI**: "Fake" loaders in the picker that don't reflect actual processing stages (Hashing -> Moving -> Thumbnailing).

We need to treat the filesystem as a **Materialized View** of the database, governed by a declarative state machine that provides real-time, verifiable progress.

## What Changes
- **Naming Standard**: Enforce `Moves/{Category}/{MoveName} - {Hash}.{ext}` as the canonical path.
- **Input Constraints**: Update `ReviewableNamingService` to reject characters that are unsafe for cross-platform filesystems (limiting to Alphanumeric, Space, Underscore, and Dash).
- **Storage Command Machine**: Introduce a `StorageActionMachine` that processes a stream of `StorageAction` sealed classes and emits a **Granular Byte-Level Progress** state (0-100%).
- **High-Fidelity Picker**:
    - **Multi-Selection**: Add checkboxes to the `MetadataVideoPickerSheet` for both Library and App videos.
    - **Paginated Discovery**: Implement lazy-loading (infinite scroll) for the video grid to handle large libraries (1000+ assets) without complexity lag or date-cutoffs (Fixes the "October only" visibility issue).
    - **"Hot" Real-Time Progress**: Replace the indeterminate native stream with a byte-aware progress bar.
        - **Hashing (0-40%)**: Incremental SHA-256 computation with chunked progress updates.
        - **Materializing (40-90%)**: Streamed file transfer (Chunked Copy) emitting real-time throughput/percentage.
        - **Post-processing (90-100%)**: Deterministic stages for thumbnailing and DB finalization.
    - **Physical Feedback**: Trigger `HapticFeedback` at key touchpoints (Selection, Start of Processing, Completion).
- **Essentialist Debugging Logs**: Implement a "Truth Ledger" log system that emits high-signal, zero-noise intent logs:
    - `[MATERIALIZE] Identity: {Hash} | Intent: Rename | Target: {Path}`
    - `[JANITOR] Orphan Found: {Path} | Action: Archive`
    - `[PROGRESS] Stage: Hashing | Byte: {N}/{Total} | Pulse: {Haptic}`
- **Transactional Materialization**: Update `MoveRepository` decorators to ensure file operations complete before DB writes are finalized.
- **Startup Reconciliation**: Implement a "Janitor" that runs on startup to purge any file in the `Moves/` tree that doesn't have a corresponding DB record.
- **Firebase Alignment**: Ensure the `videoPath` sent to Firebase is the canonical relative path, enabling absolute reconciliation across devices.

## Capabilities

### New Capabilities
- `storage-action-machine`: A declarative machine that executes file operations (`Move`, `Copy`, `Delete`, `Prune`) as a result of DB intents, yielding a 0-100% progress stream.
- `filesystem-janitor`: A service that aggressively prunes empty folders and orphaned files based on the DB manifest.
- `naming-guardrails`: Character set constraints for move names and categories to ensure filesystem scalability.
- `verifiable-import-ux`: A high-fidelity import flow with real progress, multi-selection checkboxes, and haptic cues.

### Modified Capabilities
- `video-path-resolver`: Updated to generate `Name - Hash` filenames.
- `move-detail-crud`: Updated to yield `StorageAction` commands instead of calling imperative services.
- `metadata-video-picker`: Updated for multi-selection and real progress display.

## Impact
- `lib/core/services/storage_action_machine.dart` — New central store for storage intents and progress tracking.
- `lib/core/services/video_path_resolver.dart` — Standardize on `{Name} - {Hash}.{ext}`.
- `lib/core/services/reviewable_naming_service.dart` — Add regex-based character validation.
- `lib/core/data/sync_aware_repositories.dart` — Integrate with `StorageActionMachine`.
- `lib/core/sync/integrity_verifier.dart` — Update to include orphan detection.
- `lib/shared/widgets/metadata_video_picker_sheet.dart` — High-fidelity UI overhaul.
- **BREAKING**: Existing videos will be migrated to the new naming format by the `VideoPathHealer` on next boot.

### Explicit Deletions (Eradication)
- **REMOVE**: `MoveDetailNotifier._duplicateMove` (Replaced by Orchestrator call).
- **REMOVE**: `VideoPathResolver.semanticVideoPathLegacy` (Force all code to use Hash-based naming).
- **REMOVE**: `VideoPathHealer._cleanupMovesOrphans` (Replaced by high-speed Startup Janitor).
- **REMOVE**: `unawaited` calls on file deletions in `MoveDetailNotifier`.
