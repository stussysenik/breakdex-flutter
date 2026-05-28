# OpenSpec: Breakdex MVP Robustness & Offline Verification

## Goal
Verify that Breakdex functions as a resilient, offline-first application that optimizes Firebase free-tier usage while maintaining a production-grade folder structure for video assets.

## Core Features to Verify
1. **Offline-First Lifecycle**: Data entry (Moves/Combos) must persist to local Drift DB immediately, regardless of network state.
2. **Resilient Sync Engine**: Background synchronization must handle connectivity transitions (Online <-> Offline) without data loss or UI blocking.
3. **Semantic Folder Organization**: Video assets must be stored in category-based semantic folders (`Documents/Moves/{Category}/{MoveName}/video.mp4`).
4. **Firebase Cost Optimization**: Minimize Firestore reads/writes and Storage egress through debouncing and content-addressable storage (SHA-256).

## Test Strategy (Maestro)

### 1. Offline Mode - Move Addition
- **Setup**: Disable network.
- **Action**: Add a new move "Windmill" in category "Power Moves".
- **Verification**:
  - Move appears in the Arsenal list immediately.
  - Video file exists at `Documents/Moves/Power Moves/Windmill/video.mp4`.
  - Sync status shows "Pending" or "Waiting for connection".

### 2. Network Transition - Sync Verification
- **Setup**: Start with "Pending" moves from Test 1.
- **Action**: Enable network.
- **Verification**:
  - `AssetSyncEngine` triggers upload.
  - `SyncService` pushes metadata to Firestore.
  - Sync status changes to "All synced".
  - Firebase Storage contains the move video under `videos/{uid}/moves/{contentHash}.mp4`.

### 3. Folder Integrity - Category Rename
- **Setup**: A move exists in "Footwork".
- **Action**: Rename category "Footwork" to "Floorwork".
- **Verification**:
  - Physical video folder moves to `Documents/Moves/Floorwork/`.
  - Database record updates to the new path.
  - No orphaned files left in the old directory.

## Maintenance Checklist
- [ ] Run `flutterfire configure` (Requires User Interaction).
- [ ] Ensure `FirebaseStorageProvider` is enabled in `sync_providers.dart`.
- [ ] Audit `SyncService` for Firestore batching opportunities.
