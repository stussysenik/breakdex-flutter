# Product Requirements Document

## Purpose

This PRD defines the product and system direction for Breakdex as a local-first training platform for breakers. It is meant to align the mobile app, the future web app, the backend architecture, and the media/storage model around one coherent contract.

The near-term requirement is clear: ship a stable iOS TestFlight build with reliable video import, review, flow, and sync behavior. The longer-term requirement is equally clear: evolve Breakdex into a system where a user can access the same library and training state from mobile and web without fragmenting product logic or data ownership.

## Product Summary

Breakdex is a video-first practice system for breaking. It helps a dancer:

1. Capture a move or combo with source media.
2. Organize it in category and graph context.
3. Rehearse it with FSRS-based scheduling.
4. Read back performance through progress and analytics.
5. Return to the next training action with minimal friction.

Breakdex is not only a notes app, not only a flashcard app, and not only a media browser. It is a unified practice loop.

## Primary User

The primary user is an active breaker training under fatigue and time pressure:

- after practice
- between rounds
- while planning the next sprint
- while revisiting older material that risks decay

They need fast capture, honest state, reliable media, and clear next actions.

## Product Goals

### Immediate goals

- Keep the iOS Flutter app reliable enough for daily practice and TestFlight validation.
- Stabilize media import, album/archive behavior, export/share, and sync.
- Keep the UI honest about what is live, WIP, or planned.

### Medium-term goals

- Make user data available from both mobile and web.
- Keep the same canonical move/combo/review/graph model across clients.
- Separate platform adapters from core product logic.

### Long-term goals

- Support collaboration-oriented surfaces where they materially improve training.
- Support provider pluggability for storage, delivery, and optional AI/media services.
- Preserve portability so Breakdex is not trapped inside one vendor stack.

## Non-Goals

- Rewriting the current Flutter client before the next TestFlight.
- Making the whole system CRDT-first.
- Making Cloudinary, Supabase, or any third-party media vendor the source of truth.
- Building bring-your-own-keys or bring-your-own-bucket as a v1 dependency.

## Product Principles

- Video-first workflows beat text-heavy workflows whenever possible.
- State must be explicit, inspectable, and hard to corrupt.
- The user should be able to reach the same training library from mobile and web.
- Media ownership and metadata ownership must stay under Breakdex control.
- Collaboration features should be added selectively, not by making the whole core architecture speculative.

## Functional Scope

### Core mobile product

- Move capture and organization
- Combo creation and sequencing
- Flow graph inspection and set construction
- FSRS-driven review sessions
- Stats, progress, and planning feedback
- Settings, export, media archive/recovery, and sync controls

### Future web access

- User sign-in to the same account/workspace
- Read access to the same move/combo/review library
- Playback of uploaded media and generated previews
- Web surfaces for practice review, analytics, and library browsing
- Later: coach/admin/team surfaces where the BEAM stack is advantageous

## State And Logic Architecture

### UI philosophy

Breakdex should use a reducer-style, model-driven architecture:

- `Model -> Update -> View`
- explicit events
- pure state transitions where possible
- effect handlers isolated behind services/adapters

### FRP stance

Use FRP selectively, not dogmatically:

- good for streams such as sync status, playback state, background jobs, and realtime subscriptions
- bad as the only abstraction for all application logic

### Data-oriented design

Canonical state should be represented as plain records and collections:

- moves
- combos
- graph edges
- review events
- FSRS cards
- assets
- manifests
- sync jobs

UI components should render state and emit intents. Business rules should live in testable modules.

### Zustand/Nanostores stance

Breakdex does not need Zustand or Nanostores inside Flutter. Those libraries are useful references for store ergonomics, not required dependencies in this codebase.

The equivalent philosophy in Breakdex is:

- small focused state modules
- immutable state payloads
- reducer/update functions
- narrow reactive subscriptions
- side-effect boundaries

In Flutter, Riverpod remains the primary state tool. The team should adopt the discipline those libraries encourage without importing JS-specific tooling into the mobile stack.

## Sync And Concurrency Model

### Default model

Most product data should remain:

- relational
- evented
- local-first
- syncable through explicit contracts

### CRDT stance

CRDTs are not the default storage model for Breakdex. They are reserved for future surfaces where concurrent collaboration truly requires them, such as:

- shared notes
- collaborative graph editing
- live coaching annotations
- multi-user presence-heavy sessions

Videos, review events, manifests, and most move metadata should not be modeled as CRDTs.

## Runtime Stack

### Near-term runtime

- `Flutter` mobile client
- `Riverpod` for state and reactivity
- `Drift + SQLite` for local persistence
- `FSRS` for scheduling
- thin `Swift` iOS plugins for media/device capabilities

This remains the shipping stack for the current app.

### Target system spine

- `Phoenix` on the `BEAM` for backend, realtime, jobs, and web-facing surfaces
- `Postgres` as canonical metadata and sync truth
- `S3-compatible object storage` for original media and derived artifacts
- optional `Gleam` for bounded, typed BEAM-domain modules

### Rust and Nim stance

- `Rust` is allowed for proven performance-critical kernels only
- `Nim` is not a primary architecture dependency

The architecture bet is on `Flutter + Phoenix + Postgres + S3-compatible storage`, not on broad polyglot expansion.

## Media And Storage Model

### Source of truth

- Postgres owns metadata and system state.
- S3-compatible object storage owns original and derived media blobs.
- Asset identity should be content-addressed where practical.

### Delivery model

- server-issued signed URLs for upload and download
- provider-agnostic asset references
- web and mobile consume the same asset graph

### Vendor stance

- `Cloudinary` is optional for transformation and delivery later
- `Supabase Storage` is acceptable as a near-term implementation if kept behind interfaces
- the product must remain portable across S3-compatible backends

## Web Access Requirements

Users should be able to access their data from a web app. That means:

- one canonical identity model
- one canonical move/combo/review/asset model
- one backend contract for permissions and sync
- no separate shadow system for web

The web app is not a sidecar demo. It is another client of the same product system.

## Pluggability Requirements

Breakdex should be designed for later pluggability without making it a near-term blocker.

### Long-term pluggable areas

- storage provider
- media delivery/transformation provider
- optional AI provider
- optional bring-your-own keys or bring-your-own bucket

### Near-term implementation rule

Design provider interfaces now, but ship a managed path first.

## Performance Requirements

- move capture and save flows must feel immediate on-device
- media paths must degrade safely when network/cloud providers are unavailable
- sync should prefer correctness and resumability over brittle optimism
- web access should not require large client bundles to become useful

## Quality Requirements

- local state must remain coherent across app restarts, backgrounding, and reconnection
- sync failures must fail soft and preserve user work
- media unavailability must not silently destroy metadata
- UI should accurately represent active, archived, syncing, and unavailable states

## Success Criteria

Breakdex is succeeding when:

- the mobile app is trusted during real training
- users can access the same library from mobile and web
- media and metadata stay under product control
- new providers or delivery layers can be added without rewriting the core
- the system remains understandable enough to evolve safely
