# Add BEAM Web Architecture Foundation — Design

## Product Contract

Breakdex remains a local-first training product with a mobile-first surface today and a shared mobile/web system tomorrow. The current Flutter client stays in place. The future system spine is standardized so later work does not splinter into incompatible stacks.

## Architecture Decision

### Near-term shipping runtime

The current client stack remains:

- Flutter
- Riverpod
- Drift + SQLite
- FSRS
- thin Swift bridges for iOS media/device integration
- local provenance journaling for startup recovery, retrieval, and crash breadcrumbs

This is the stack used for TestFlight and near-term product validation.

### Target system spine

The future shared system is:

- Phoenix on BEAM for backend, realtime, jobs, and web-facing surfaces
- Postgres for canonical metadata and sync truth
- S3-compatible object storage for original and derived media
- optional Gleam for bounded typed domain modules on the BEAM

This keeps realtime, fault tolerance, and long-lived workflow logic where BEAM has clear leverage.

### Unstable orchestration boundaries

The first unstable domains that should migrate behind Phoenix/Gleam contracts are:

- video retrieval policy and replayable transfer decisions
- provenance ingestion, crash breadcrumb analysis, and recovery auditing
- long-running recovery/bootstrap jobs that should survive client restarts

Flutter should keep:

- rendering
- local cache/index state
- native media/device bridges
- optimistic client interaction state

## State And Update Model

### Default philosophy

Breakdex should prefer:

- reducer-style updates
- explicit events
- data-oriented state
- pure transition logic where practical
- effects isolated behind adapters/services

This is the repo’s version of an MVU-like contract.

### Flutter state posture

The codebase does not need Zustand or Nanostores directly. Those libraries are reference points for ergonomics, not architecture requirements.

Equivalent native posture:

- Riverpod as the state/runtime tool
- small stores/providers rather than giant state bags
- immutable state values
- focused subscriptions
- logic extraction from widgets

### FRP posture

FRP is used for streams and subscriptions:

- sync connectivity
- upload/download progress
- playback state
- realtime presence or event feeds

FRP is not the only abstraction for all business logic.

## Concurrency And Collaboration Model

### Default sync model

Most Breakdex state remains relational and evented:

- moves
- combos
- graph edges
- FSRS cards
- reviews
- manifests
- assets

### CRDT posture

CRDTs are reserved for surfaces where concurrent collaboration justifies them:

- annotations
- shared notes
- simultaneous graph edits
- live coaching overlays

Videos and most core training records are not modeled as CRDT-first entities.

## Media And Storage Design

### Ownership

- Postgres owns metadata and product truth.
- Object storage owns media blobs.
- Asset IDs should be durable and content-oriented where practical.

### Delivery contract

- upload/download through signed URLs
- provider-specific details hidden behind provider interfaces
- shared asset references across mobile and web clients

### Vendor guidance

- Cloudinary is optional for transformation/delivery later
- Supabase Storage is acceptable as a near-term S3-compatible implementation
- the system must stay portable across S3-compatible storage vendors

## Web Access Design

The web app is a first-class client of the same system, not a separate product.

Requirements:

- same canonical identity model
- same metadata truth
- same asset references
- same permission model
- same sync semantics

Phoenix is the preferred home for web access and realtime surfaces.

## Pluggability Design

### Immediate design rule

Interfaces should be introduced so providers can change later without forcing provider choice into every product surface.

### Long-term pluggable domains

- storage provider
- media delivery/transformation provider
- optional AI provider
- optional bring-your-own-key or bring-your-own-bucket configuration

### Explicit deferral

User-facing BYOK/BYOB is not required now. It is a future capability enabled by clean boundaries.

## Gleam And Squirrel Guidance

Gleam is a selective tool inside the BEAM architecture, not an all-or-nothing requirement.

Recommended use:

- typed domain modules
- bounded backend services
- query/model packages where strong functional contracts help

`squirrel` can be used as a type-safe SQL tool in Gleam-backed backend slices, but it should support the architecture rather than define it.

## Risks

- over-specifying future collaboration features before product demand exists
- introducing too many languages too early
- coupling storage/media truth to a single vendor
- letting web access fork the product model from mobile

## Acceptance Criteria

This design is accepted when the repo clearly states:

- the current shipping stack
- the future backend/web stack
- the state-management philosophy
- the CRDT boundaries
- the media/storage ownership model
- the long-term pluggability posture
