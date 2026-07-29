## Why

Past Breakdex album videos don't surface in the app, video loading feels slow with no feedback on iCloud downloads, pinch-to-zoom in trim mode is oversensitive, and the data model can't express hierarchical collections (sets). The dancer needs a trustable, fast-loading scratchpad where every past move is immediately available and every interaction feels intentional — not a technical hurdle.

## What Changes

- **Album discovery regex hardened**: Patterns made case-insensitive with separator-agnostic matching, native iOS PHFetchOptions widened to catch all Breakdex-named albums — including dated variants (`Breakdex 05-05-2026`), legacy patterns (`breakin`, `bboy`, `bgirl`), and edge cases (`BreakDex`, `Break Dex`, `breakdex_videos`).
- **Loading state machine**: Pure Dart sealed-class state machine modeling all media load phases — idle → locating → downloading (with progress) → ready / timeout / error → retry. Wired into video service, thumbnail coordinator, and iCloud download paths. Provides reactive progress to the UI shell.
- **PID pinch-to-zoom controller**: Mathematical PID (Proportional-Integral-Derivative) controller on the `InteractiveViewer` transformation in trim mode. Replaces raw gesture sensitivity with calibrated response — fast for intentional zooms, dampened for micro-twitches.
- **Sets entity**: Third composable entity in the data model: `move → combo → set`. Sets contain moves, combos, and nested sub-sets. Enables hierarchical organization (e.g., "Power Moves Set" containing windmill, flare, headspin, and a "Windmill Variations" subset).
- **Data provenance timeline**: Activity ledger tracking every review, edit, and milestone per entity. Surfaces "when did I last practice this?" and "how has this move progressed over 30 days?" queries.
- **Cloud provider abstraction**: Interface-based storage backend decoupled from concrete providers. S3-compatible, iCloud, and Google Drive become pluggable adapters behind a single `CloudStorageProvider` contract.

## Capabilities

### New Capabilities

- `album-discovery`: Universal Photos library scanning that discovers all Breakdex-named albums regardless of case, word separators (space/hyphen/underscore), date suffix formats, or legacy naming conventions (breakin, bboy, bgirl, breakdance). Produces a complete asset inventory on startup and on library change notifications.
- `loading-state-machine`: XState-inspired, pure Dart state machine for all media loading operations. Models states (idle, locating, downloading, ready, timeout, error, retrying) with typed events and guarded transitions. Emits reactive progress to Riverpod providers for UI rendering.
- `pid-pinch-zoom`: PID controller applied to `InteractiveViewer` transformation matrix in video trim mode. Replaces raw gesture scaling with proportional (current error), integral (accumulated error), and derivative (rate of change) terms. Produces smooth, intentional zoom that resists micro-twitch amplification.
- `sets-entity`: Database table and repository for Set entities — ordered, nestable collections of moves and combos. Supports move → combo → set → subset hierarchy. Includes DAO with CRUD, ordering, and reordering operations.
- `data-provenance`: Activity ledger table tracking timestamped events per entity (reviewed, edited, tagged, milestone_reached). Supports time-range queries ("what did I practice in March?") and per-move progression queries ("show me every review of this windmill").
- `cloud-storage-abstraction`: Abstract `CloudStorageProvider` interface with concrete adapters for S3-compatible, iCloud (via native plugin), and Google Drive. Asset sync engine routes through provider abstraction instead of direct implementations.

### Modified Capabilities

_None_ — all capabilities are new additions. Existing behavior is preserved.

## Impact

- **Dart code**: `lib/core/services/native_video_album.dart` (regex list), `lib/core/services/managed_album_reconciliation_service.dart` (scoring), `lib/core/services/video_service.dart` (state machine wiring), `lib/features/video_editor/video_editor_screen.dart` (PID controller), `lib/core/database/tables/` (new sets + provenance tables), `lib/core/database/daos/` (new DAOs), `lib/core/data/` (new repository interfaces), `lib/core/sync/` (provider abstraction)
- **Native iOS**: `ios/Runner/VideoAlbumPlugin.swift` (PHFetchOptions predicates, case-insensitive album scan)
- **Database**: Schema migration v15 (sets table, provenance_events table, set_items junction table)
- **Dependencies**: No new packages required. PID controller is pure Dart math. State machine is sealed classes. Cloud abstraction is interface-based.
