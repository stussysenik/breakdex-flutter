# Add Protobuf Event Envelope And Upload Spool — Design

## Product Contract

Breakdex should keep a simple local provenance journal for immediate debugging, but every machine-to-machine path should converge on a typed Protobuf envelope. The client must be able to capture events offline, spool them durably, and upload them later without losing causal order or schema clarity.

## Event Model

### Envelope

The top-level machine message should include:

- schema version
- event id
- session id
- client install or device identifier
- app version and platform metadata
- event timestamp
- event body

### Event body

The event body should preserve the same semantic axes already used in the local journal:

- scope
- event type
- status
- entity type
- entity id
- content hash
- move id
- connection type
- short message
- optional typed detail fields for retrieval or recovery context

### Typed detail fields

Avoid unbounded string maps for core flows. Prefer explicit typed submessages for:

- database recovery attempt
- video retrieval attempt
- crash capture
- historical asset recovery

## Relationship To Local Journal

The local journal remains:

- the immediate debug artifact
- simple to append during degraded runtime states
- exportable to humans

The Protobuf spool becomes:

- the backend upload source of truth
- structured for schema-safe ingestion
- decoupled from user-facing export formats

The client may derive spool records directly from the same event emission point that writes the local journal.

## Spool Design

### Storage posture

The upload spool should be:

- append-only
- durable across app restarts
- bounded by retention and acknowledgment compaction
- independent of Drift startup success where practical

### Flush triggers

Uploads should be attempted on:

- app launch after recovery-critical initialization
- connectivity improvement
- explicit sync or diagnostics actions
- app foreground transitions when pending records exist

### Acknowledgment model

The backend must acknowledge accepted event ids. The client should only compact spooled events after acknowledgment.

## Versioning Design

### Compatibility rules

- new fields must be additive
- enum evolution must preserve unknown value tolerance
- envelope version must be explicit
- the backend should accept at least one prior minor schema generation during rollout

### Migration posture

The local journal does not need migration symmetry with the Protobuf schema. The machine spool does.

## Risks

- letting the local journal and Protobuf envelope diverge semantically
- introducing oversized envelopes through unbounded detail fields
- building transport before the ownership boundary is clear

## Acceptance Criteria

This design is accepted when the repo clearly states:

- that Protobuf is the preferred machine transport
- what fields are stable across client and backend
- how offline spooling and acknowledgments work
- how the local journal differs from the machine spool
