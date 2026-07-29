# Add Phoenix Provenance Ingestion And Recovery Analysis — Design

## Product Contract

Phoenix should become the canonical ingestion and correlation layer for Breakdex provenance. Flutter remains the capture client. Postgres becomes the durable queryable history. Gleam is used selectively for bounded typed analysis where pure classification rules improve confidence and maintainability.

## Backend Ownership Model

### Phoenix responsibilities

Phoenix should own:

- authenticated ingestion endpoints
- event validation and persistence
- replay APIs for developer/operator debugging
- derived incident/materialized summaries
- background jobs for correlation, rollups, and alerts

### Flutter responsibilities

Flutter should keep:

- first-write capture
- offline spool and retry
- local diagnostics and raw export
- native bridge/device-local recovery behavior

## Storage Model

### Canonical event store

Postgres should store:

- raw accepted provenance envelopes
- normalized searchable fields for common queries
- client metadata and schema version
- ingestion metadata and acknowledgment state

### Derived incidents

A second derived layer should capture incidents such as:

- repeated retrieval failures for one content hash
- repeated DB recovery failures on one device
- crash loops during startup
- recurring historical asset restore failures

## Replay And Analysis

### Replay queries

The backend should support queries such as:

- show all events for a session
- show all events for one content hash
- show all startup failures for one install
- show the sequence from retrieval request to success or failure

### Derived summaries

Useful derived summaries include:

- top failing content hashes
- crash-loop candidates
- recovery success rate after one or more retries
- frequent network-policy blocks versus genuine media failures

## Gleam Boundaries

### Good Gleam candidates

The first bounded Gleam module should likely cover:

- incident classification from raw event sequences
- deterministic recovery-state derivation
- typed rule evaluation for alert eligibility

### Not good Gleam candidates yet

- Phoenix endpoint glue
- broad persistence orchestration
- highly framework-coupled transport plumbing

## Risks

- overbuilding observability before ingest volume exists
- blurring raw events with derived incidents
- pushing too much transport/plumbing into Gleam too early

## Acceptance Criteria

This design is accepted when the repo clearly states:

- Phoenix as the provenance ingestion owner
- Postgres as canonical provenance history
- the difference between raw events and derived incidents
- the first bounded Gleam role in provenance analysis
