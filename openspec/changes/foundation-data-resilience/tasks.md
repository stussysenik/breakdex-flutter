## 1. Album Discovery Fix

- [x] 1.1 Update `historicalAlbumPatterns` in `lib/core/services/native_video_album.dart` with unified case-insensitive regex covering all known Breakdex naming variants
- [x] 1.2 Add `breakdexAlbumPattern` static `RegExp` getter with `caseSensitive: false` and word-boundary-anchored pattern
- [x] 1.3 Update native iOS `VideoAlbumPlugin.swift` `discoverRecoverableManagedAssets` to use `NSPredicate(format: "title CONTAINS[c] %@")` for case-insensitive album matching
- [x] 1.4 Add full-enumeration fallback in `VideoAlbumPlugin.swift` that iterates all `PHCollectionList` user albums and tests each title with `localizedCaseInsensitiveContains`
- [x] 1.5 Add deduplication by `PHAsset.localIdentifier` in Swift discovery results
- [x] 1.6 Update `_historicalMatchScore` in `managed_album_reconciliation_service.dart` to use the new unified regex
- [x] 1.7 Write unit test verifying the regex matches all known album naming variants from the spec scenarios

## 2. Loading State Machine (Pure Dart)

- [x] 2.1 Create `lib/core/utils/loading_state_machine.dart` with sealed `LoadingStateMachine<T>` class hierarchy: `Idle`, `Loading`, `Downloading`, `Ready`, `Timeout`, `Error`, `Retrying`
- [x] 2.2 Implement `transition(LoadingEvent)` method with guarded transitions per the state diagram in design.md
- [x] 2.3 Implement `Stream<LoadingStateMachine<T>>` state change broadcast
- [x] 2.4 Implement progress monotonicity (progress never decreases)
- [x] 2.5 Implement max retry enforcement and non-retryable error handling
- [x] 2.6 Write exhaustive unit test covering all valid transitions and all rejection cases (invalid transitions, non-retryable retry, max retries exhausted)
- [x] 2.7 Verify Dart 3 sealed class exhaustiveness — all state consumers must handle all 7 states

## 3. PID Pinch-to-Zoom Controller

- [x] 3.1 Create `lib/core/utils/pid_controller.dart` with `PidController` class (Kp, Ki, Kd, integral anti-windup, derivative calculation)
- [x] 3.2 Implement `update(setpoint, current, dt)` method returning filtered output
- [x] 3.3 Implement `reset()` method to clear integral and previous error (for gesture end)
- [x] 3.4 Set default tuning constants: Kp=0.4, Ki=0.05, Kd=0.3
- [x] 3.5 Wire `PidController` into `video_editor_screen.dart` `InteractiveViewer.onInteractionUpdate`, replacing raw gesture scale application
- [x] 3.6 Wire `reset()` into `InteractiveViewer.onInteractionEnd`
- [x] 3.7 Write unit test verifying: proportional response, derivative damping on sudden jerk, integral anti-windup clamping, consistent behavior across frame rates (30fps vs 60fps dt)

## 4. Database Migration v15

- [x] 4.1 Define v15 schema migration in `lib/core/database/database.dart`: `sets`, `set_items`, `provenance_events` tables
- [x] 4.2 Create `sets` table with columns: id, name, description, learning_state, created_at, updated_at
- [x] 4.3 Create `set_items` table with columns: id, set_id, item_type, item_id, position + unique constraint
- [x] 4.4 Create `provenance_events` table with columns: id, entity_type, entity_id, event_type, timestamp, metadata + index on (entity_type, entity_id, timestamp)
- [x] 4.5 Add name uniqueness enforcement for sets across moves, combos, and sets
- [x] 4.6 Write migration test verifying up/down migration, table structure, and unique constraint enforcement

## 5. Sets Entity — Table Definitions

- [x] 5.1 Create `lib/core/database/tables/sets.dart` with Drift table definition
- [x] 5.2 Create `lib/core/database/tables/set_items.dart` with Drift table definition including foreign keys and unique constraint
- [x] 5.3 Create `lib/core/database/daos/sets_dao.dart` with CRUD operations: create, update, delete, get, getAll, watchAll, watch
- [x] 5.4 Implement set item operations: addItem, removeItem (with reindexing), reorderItem
- [x] 5.5 Implement cycle detection for nested sets — reject insertion if it would create a cycle
- [x] 5.6 Implement max depth enforcement (depth ≤ 5) for set nesting
- [x] 5.7 Write DAO tests covering: create, update, delete, add/remove/reorder items, uniqueness constraint, cycle detection, name uniqueness

## 6. Sets Entity — Repository Layer

- [x] 6.1 Create `SetRepository` abstract interface in `lib/core/data/repositories.dart`
- [x] 6.2 Implement `DriftSetRepository` in `lib/core/data/drift_repositories.dart`
- [x] 6.3 Implement `SyncAwareSetRepository` decorator in `lib/core/data/sync_aware_repositories.dart`
- [x] 6.4 Register Set-related Riverpod providers in `lib/core/providers.dart`
- [x] 6.5 Write repository tests verifying CRUD, reactive streams, and sync logging

## 7. Data Provenance Events

- [x] 7.1 Create `lib/core/database/tables/provenance_events.dart` with Drift table definition
- [x] 7.2 Create `lib/core/database/daos/provenance_events_dao.dart` with insert (only — no update/delete), getTimeline, getTimelineRange, getRecentActivity, getEntityMilestones
- [x] 7.3 Create `ProvenanceService` in `lib/core/services/provenance_service.dart` with methods: logCreated, logReviewed, logEdited, logMilestone
- [x] 7.4 Wire provenance auto-logging into existing `SyncAwareMoveRepository` and `SyncAwareComboRepository` for create, update, and review operations
- [x] 7.5 Implement `purgeExpiredEvents(retentionDays)` for events older than retention period
- [x] 7.6 Write DAO tests verifying: append-only, timeline ordering, range queries, milestone filtering, purge behavior

## 8. Cloud Storage Abstraction

- [x] 8.1 Create `CloudStorageProvider` abstract interface in `lib/core/sync/cloud_storage_provider.dart` (exists as `CloudProvider` + `AssetStorageProvider` in `cloud_provider.dart`)
- [x] 8.2 Implement `S3StorageProvider` adapter (using existing project HTTP client patterns, no new dependencies)
- [x] 8.3 Implement `ICloudStorageProvider` adapter (delegates to existing native `iCloudSyncPlugin`)
- [x] 8.4 Implement `GoogleDriveStorageProvider` adapter (delegates to existing Google APIs integration)
- [x] 8.5 Create `CloudStorageProviderRegistry` to manage provider lifecycle and runtime switching
- [x] 8.6 Refactor `AssetSyncEngine` to accept `CloudStorageProvider` via constructor injection and route through it (already done)
- [x] 8.7 Write tests with mock `CloudStorageProvider` verifying sync engine routes operations correctly

## 9. UI Integration

- [x] 9.1 Create `LoadingStateWidget` in `lib/shared/widgets/loading_state_widget.dart` — renders appropriate UI for each `LoadingStateMachine` state (shimmer for Loading, progress bar for Downloading, error card for Error, retry button, etc.)
- [x] 9.2 Wire `LoadingStateMachine` into `VideoPlayerWidget` for video load state display
- [x] 9.3 Wire `LoadingStateMachine` into `VideoService` for file existence checks and iCloud download progress
- [x] 9.4 Apply minimal design refinements to video editor: border-radius consistency, outline-based affordances, reduced visual weight
- [x] 9.5 Apply minimal design refinements to move list grid: consistent border-radius on thumbnails, subtle outline borders replacing heavy shadows

## 10. Testing and Validation

- [x] 10.1 Run `flutter test` and fix any test regressions from the changes (457 tests pass, 0 failures)
- [x] 10.2 Run `flutter analyze` and resolve all warnings and errors (0 errors, 76 pre-existing warnings/infos)
- [ ] 10.3 Run database migration test on a copy of a real user database to verify v14→v15 migration
- [ ] 10.4 Test album discovery end-to-end on physical iOS device with real Photos library containing Breakdex albums in mixed cases
- [ ] 10.5 Test pinch-to-zoom feel on physical device — verify no oversensitivity
- [ ] 10.6 Test video loading with state machine on physical device under poor network conditions (mobile data, airplane mode toggle)
- [ ] 10.7 Verify all existing features (move list, combo creation, flashcard review, video editor) still function correctly after changes
