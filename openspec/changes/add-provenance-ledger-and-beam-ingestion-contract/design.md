# Add Provenance Ledger And BEAM Ingestion Contract — Design

## Product Contract

Breakdex should be able to explain what happened during startup recovery, video loading, and crash-adjacent flows without relying on transient in-memory state or console logs. The immediate runtime remains Flutter + SQLite + native bridges. The event semantics introduced here are intentionally shaped so Phoenix/Gleam can own long-lived orchestration later.

## Local-First Design

### Capture model

The client owns first-write capture of provenance events because the most important failures can happen:

- before the database is open
- while connectivity is missing
- while the backend does not exist yet

This requires a storage target that does not depend on Drift migrations or server reachability.

### Local storage shape

The provenance journal is:

- append-only
- file-backed in app documents storage
- bounded by simple retention/pruning rules
- structured by stable fields rather than opaque debug blobs

Recommended field set:

- recorded timestamp
- session id
- scope
- event type
- status
- entity type
- entity id
- content hash when relevant
- move id when relevant
- connection type when relevant
- local path when relevant
- short human-readable message

### Why not JSON for the local journal

The local journal should optimize for:

- append simplicity
- low parsing overhead
- resilience during degraded runtime states

It does not need to be the backend transport format. Human backup/export JSON remains acceptable elsewhere in the app. Machine-to-machine transport should prefer typed formats later.

## Diagnostics Design

### Developer-facing summary

The app should derive a compact report from recent provenance events so developers can inspect:

- recent crash signals
- recent retrieval failures
- recent database recovery activity
- the latest critical events

This summary belongs in Settings because that surface already hosts backup/export flows and recovery-adjacent controls.

### Export design

The raw provenance ledger should be exportable directly from the app. The exported artifact is intentionally raw because it is the source of truth for later backend ingestion and offline debugging.

## BEAM Boundary Design

### Flutter ownership

Flutter should continue to own:

- UI rendering and local developer diagnostics
- first-write event capture
- native bridge coordination
- local cache/index state
- optimistic and offline-first interaction behavior

### Phoenix/Gleam ownership

When the backend slice exists, Phoenix/Gleam should own:

- provenance ingestion
- session and device correlation
- replayable recovery analysis across launches
- policy decisions for retrieval/recovery orchestration
- alerting and operational summaries

### Why this boundary is correct

The unstable logic is not the widget tree. The unstable logic is:

- retry policy
- recovery policy
- cross-session reasoning
- correlation of multiple failures over time

That is exactly where BEAM has leverage.

## Future Transport Contract

### Typed transport preference

For backend ingestion, the preferred machine contract is:

- Protobuf event envelope
- batched upload or streaming transport later
- explicit schema versioning

This satisfies the requirement to avoid long-term machine reliance on ad hoc JSON while keeping current local export/debug paths simple.

### Draft event envelope shape

The future transport should preserve the same semantic fields as the local journal:

- event id
- schema version
- session id
- device/runtime metadata
- provenance event body

The event body should preserve stable enums for:

- scope
- status
- event type

## Risks

- overfitting the event vocabulary too early
- logging too much low-signal noise
- mixing local debug needs with backend transport concerns
- letting provenance stay local forever instead of becoming an ingestion boundary

## Acceptance Criteria

This design is accepted when the repo clearly states:

- the local provenance capture goal
- the diagnostics role of the Flutter client
- the future Phoenix/Gleam ownership boundary
- the preference for Protobuf on future machine ingestion paths
