# Add Protobuf Event Envelope And Upload Spool

## Summary

Define a typed machine transport for Breakdex provenance, recovery, and video-loading events using Protobuf, plus a local upload spool that works offline and survives app restarts. This creates the contract Flutter can emit locally now and Phoenix can ingest later without depending on ad hoc JSON payloads.

## Motivation

Breakdex now has a local provenance journal and diagnostics layer, but that is only the first half of the system. To graduate from local debugging into backend analysis, the app needs a stable wire format and an offline-safe upload queue.

The current local journal is intentionally simple and durable. It should not become the long-term machine transport. We need a typed contract that:

- preserves event semantics across client and backend implementations
- supports schema evolution cleanly
- avoids brittle JSON parsing on machine-only paths
- allows offline-first buffering and replay

## Scope

### In scope

- Protobuf schema for provenance and recovery events
- envelope versioning rules
- local spool ownership and retry semantics
- flush triggers and acknowledgment rules
- relationship between local journal and machine spool

### Out of scope

- Phoenix ingestion endpoint implementation
- user-facing export format changes
- replacing existing human-readable backup/export JSON
- cloud analytics dashboards

## Capabilities

1. `typed-event-envelope` — stable Protobuf schema for machine ingestion
2. `offline-upload-spool` — local durable queue for deferred upload
3. `schema-evolution-contract` — explicit versioning and backward compatibility rules

## Dependencies

- existing local provenance journal
- existing BEAM architecture direction
- existing sync/runtime recovery flows that emit provenance semantics
