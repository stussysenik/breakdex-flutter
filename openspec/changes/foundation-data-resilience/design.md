## Context

Breakdex manages a dancer's video move library with Photos library integration, video editing, and FSRS-based spaced repetition review. The existing architecture is mature (Riverpod, Drift/SQLite, native iOS plugins) but has three pain points:

1. **Album discovery is fragile**: Regex patterns are case-sensitive and miss dated album variants (e.g., "Breakdex 05-05-2026"), capitalized forms, and edge-case separators.
2. **Loading feedback is absent**: Multiple ad-hoc loading state enums (`_EditorVideoLoadState`, `SyncEngineState`, etc.) with no unified contract. Users see spinners or nothing. iCloud downloads have no progress indication.
3. **Pinch-to-zoom oversensitivity**: Raw gesture deltas are applied directly to the `InteractiveViewer` transformation matrix with no filtering, amplifying micro-twitches.

Additional structural needs: Sets as a third composable entity, provenance tracking for practice history, and a cloud provider abstraction to decouple from concrete backends.

## Goals / Non-Goals

**Goals:**
- Universal album discovery: Any Photos album whose name contains any case/spacing variant of "breakdex" (or legacy patterns) is detected and its assets surfaced.
- Unified loading state machine: A single pure-Dart sealed class hierarchy modeling all media load phases with reactive progress.
- Mathematical pinch-to-zoom: PID controller on the transformation matrix eliminating oversensitivity.
- Sets entity: Move → Combo → Set hierarchy with ordered, nestable collections.
- Provenance ledger: Timestamped event tracking per entity for practice history queries.
- Cloud storage abstraction: Interface-based backend decoupled from concrete providers.

**Non-Goals:**
- Redesigning the existing video player widget or playback engine.
- Changing the FSRS algorithm or review session flow.
- Adding network-layer optimizations (CDN, chunked upload).
- UI redesign beyond the minimal border-radius/outline refinements.
- Real-time multiplayer or collaboration features.
- Push notifications or background sync triggers.

## Decisions

### 1. Loading State Machine: Sealed Class Hierarchy (Pure Dart)

**Decision**: Use Dart 3 `sealed class` with exhaustive switch, inspired by XState semantics but zero dependencies.

```
LoadingStateMachine<T>
├── Idle
├── Loading
├── Downloading(progress: double)
├── Ready(data: T)
├── Timeout(after: Duration)
├── Error(message: String, retryable: bool)
└── Retrying(attempt: int, maxAttempts: int)
```

**Transitions** (guarded via `transition(Event)` method):
- `Idle` + Start → `Loading`
- `Loading` + Progress(p) → `Downloading(p)`
- `Loading` + Complete(data) → `Ready(data)`
- `Loading`/`Downloading` + Timeout → `Timeout`
- `Loading`/`Downloading` + Fail(msg) → `Error(msg)`
- `Timeout`/`Error` + Retry → `Retrying(attempt)`
- `Retrying` + Start → `Loading`

**Rationale**: Sealed classes give compile-time exhaustiveness checking. Every consumer of the state machine gets compiler errors if they forget a state. Existing enums (`_EditorVideoLoadState`, `SyncEngineState`) can't carry data (progress percentage, error messages, retry counts). This replaces all ad-hoc loading enums.

**Alternatives considered**:
- `riverpod` `AsyncValue`: Already used for one-shot futures but doesn't model transitional states (downloading at 47%) or retry flows.
- `state_machine` package: Adds dependency for what's ~100 lines of Dart. Not justified.
- `XState` JS port: Massive overkill, no Dart port, wrong platform.

### 2. Album Discovery: Two-Layer Fix (Dart + Native)

**Decision**: Fix at both layers simultaneously.

**Dart side** (`native_video_album.dart`): Replace `historicalAlbumPatterns` with a single case-insensitive regex:
```dart
static final RegExp breakdexAlbumPattern = RegExp(
  r'(break[\s\-_]*dex|break[\s\-_]*ing|break[\s\-_]*in|b[\s\-_]*boy|b[\s\-_]*girl|break[\s\-_]*dance)',
  caseSensitive: false,
);
```
Add a fallback scan that enumerates ALL user albums (via native method channel) and matches by name against this pattern, returning the union of pattern-matched + all-album-scan results.

**Native iOS side** (`VideoAlbumPlugin.swift`): Change `discoverRecoverableManagedAssets` to:
1. Use `PHFetchOptions` with `NSPredicate(format: "title CONTAINS[c] %@", pattern)` — the `[c]` modifier enables case-insensitive matching.
2. Add a full enumeration fallback: iterate all user collections with `.userCollections` subtype, test each name against the pattern using `localizedCaseInsensitiveContains`.
3. Return results from BOTH the predicate query AND the full scan, deduplicated by `localIdentifier`.

**Rationale**: The `NSPredicate` `CONTAINS[c]` catches standard Photos metadata matches but can miss albums with complex Unicode or emoji in titles. The full enumeration fallback catches edge cases. The Dart-side scan handles album names that exist in the DB but not (yet) in Photos.

**Alternatives considered**:
- Fix only Dart: Native discovery still uses the old pattern, so assets never reach Dart.
- Fix only Swift: Dart-side scoring (`_historicalMatchScore`) would still reject valid matches.
- User-specified album list: Adds UI friction. The regex should be comprehensive enough.

### 3. PID Pinch-to-Zoom: Pure Dart Controller

**Decision**: Implement a `PidController` class in `lib/core/utils/pid_controller.dart` and wire it into the video editor's `InteractiveViewer.onInteractionUpdate`.

```dart
class PidController {
  final double kp, ki, kd;
  double _previousError = 0;
  double _integral = 0;

  double update(double setpoint, double current, double dt) {
    final error = setpoint - current;
    final derivative = (error - _previousError) / dt;
    _integral = (_integral + error * dt).clamp(-1.0, 1.0); // anti-windup
    _previousError = error;
    return kp * error + ki * _integral + kd * derivative;
  }
}
```

**Tuning** (for cinematic, intentional zoom):
- `Kp = 0.4` — moderate proportional response, not twitchy
- `Ki = 0.05` — slow integral accumulation for sustained gestures
- `Kd = 0.3` — strong derivative damping resists sudden jerks
- `dt` clocked via `Stopwatch` elapsed since last gesture update

**Rationale**: PID is the standard industrial control algorithm for this exact problem — tracking a setpoint while rejecting noise. The derivative term naturally dampens micro-twitches. The integral term ensures a user holding a steady zoom doesn't drift back.

**Alternatives considered**:
- Simple exponential moving average (EMA): Only one tuning parameter but can't distinguish sustained intent from noise.
- Kalman filter: Overkill, requires modeling gesture dynamics.
- Fixed sensitivity multiplier: Just scales the problem, doesn't solve it.

### 4. Sets Entity: Self-Referencing Junction Table

**Decision**: Single `sets` table + `set_items` junction with polymorphic `item_type`.
```sql
CREATE TABLE sets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  learning_state INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE set_items (
  id TEXT PRIMARY KEY,
  set_id TEXT NOT NULL REFERENCES sets(id),
  item_type TEXT NOT NULL,  -- 'move', 'combo', 'set'
  item_id TEXT NOT NULL,
  position INTEGER NOT NULL,
  UNIQUE(set_id, item_type, item_id)
);
```

**Rationale**: Self-referencing via `item_type = 'set'` enables nested subsets without a separate hierarchy table. Position column supports drag-to-reorder. Composite unique constraint prevents duplicates.

**Alternatives considered**:
- Separate tables per relationship (set_moves, set_combos, set_subsets): More tables, more DAOs, harder to maintain ordering across types.
- JSON column for items: Can't query, can't enforce referential integrity.

### 5. Provenance: Append-Only Event Ledger

**Decision**: `provenance_events` table as an append-only log. Never update or delete rows.
```sql
CREATE TABLE provenance_events (
  id TEXT PRIMARY KEY,
  entity_type TEXT NOT NULL,  -- 'move', 'combo', 'set'
  entity_id TEXT NOT NULL,
  event_type TEXT NOT NULL,   -- 'reviewed', 'edited', 'tagged', 'milestone_reached', 'created'
  timestamp INTEGER NOT NULL,
  metadata TEXT               -- JSON blob for extra context
);
CREATE INDEX idx_provenance_entity ON provenance_events(entity_type, entity_id, timestamp);
```

**Rationale**: Append-only ensures data integrity — you can't lose history. The index covers the primary query pattern (timeline for one entity). JSON metadata is flexible without schema changes.

**Alternatives considered**:
- Column per event type: Explodes when new event types are added.
- Event sourcing with replay: Overkill for practice tracking. Simple log is sufficient.

### 6. Cloud Abstraction: Interface + Adapter Pattern

**Decision**: `CloudStorageProvider` abstract interface with concrete adapters.
```dart
abstract class CloudStorageProvider {
  Future<void> upload(String remoteKey, Uint8List data);
  Future<Uint8List> download(String remoteKey);
  Future<void> delete(String remoteKey);
  Future<bool> exists(String remoteKey);
  Stream<double> downloadProgress(String remoteKey);
}
```

Existing sync engine (`AssetSyncEngine`) accepts `CloudStorageProvider` via constructor injection (Riverpod provider). `SyncProvidersDao` stores provider config. Adapters: `S3StorageProvider`, `ICloudStorageProvider`, `GoogleDriveStorageProvider`.

**Rationale**: The existing code already has `asset_copies` table tracking per-provider copies. The abstraction formalizes the provider contract. Constructor injection enables testing with mock providers.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Album regex too broad — picks up unrelated albums like "Breakfast Club" | Use word boundary `\b` anchors; the `break` prefix must be followed by `dex/ing/in/dance` patterns, or standalone `bboy/bgirl` |
| PID controller oscillation if mistuned | Start with conservative gains (Kp=0.4, Ki=0.05, Kd=0.3). Add anti-windup clamping on integral term. Expose tuning constants as named parameters for easy adjustment |
| Set nesting depth — infinite recursion if a set contains itself | Validate at insertion time: walk parent chain, reject cycles. Enforce a practical max depth of 5 |
| Provenance table growth — unbounded append | Partition by month in future; for now, a single table with index is fine for <100K events |
| Cloud abstraction leaks — some providers need auth tokens, others use system accounts | Provider interface includes `initialize(Map<String, dynamic> config)` factory. Auth is provider-specific but abstracted behind the interface |
| DB migration v15 fails on existing installs | Use existing `DatabaseRecoveryService` backup-before-migrate pattern. Test migration on copies of real user databases |

## Migration Plan

1. **Deploy**: Ship all changes in a single v1.4.0 release.
2. **Migration sequence**:
   - v15 schema migration creates `sets`, `set_items`, `provenance_events` tables (IF NOT EXISTS).
   - `CloudStorageProvider` interface is additive — existing sync engine code continues to work.
   - Album regex is a runtime behavior change, no data migration needed.
   - Loading state machine is a new class, existing code progressively adopts it.
   - PID controller is additive to video editor.
3. **Rollback**: Remove the new tables, revert regex to old pattern list. No data loss risk.
4. **Testing**: Full test suite (`flutter test`) + iOS device test with iCloud albums + `flutter analyze`.

## Open Questions

- **Q1**: Should the album scan run on every app foreground, or cache results? → Cache the album inventory with a TTL (1 hour), invalidate on `PHPhotoLibraryChangeObserver` events.
- **Q2**: What's the max set nesting depth? → Start with 5, enforce at DAO level.
- **Q3**: Should provenance events auto-generate from repository writes, or be explicit? → Auto-generate from `SyncAwareRepositories` (already wrap DAOs for sync logging). Add a `provenance: true` flag to relevant write operations.
