# Add Provenance Ledger And BEAM Ingestion Contract

## Summary

Add a local provenance ledger for startup recovery, crash capture, and video retrieval debugging, plus a clear contract for how those events should later flow into a Phoenix/Gleam backend. The immediate result is developer-visible diagnostics inside the Flutter app. The long-term result is a stable event boundary for replayable recovery analysis and policy offload.

## Motivation

Breakdex already has several self-healing paths:

- database backup and restore
- historical Photos recovery
- cloud video retrieval
- asset sync retry/recovery

Before this change, those flows were hard to reconstruct after the fact. Debugging depended on ad hoc `debugPrint` output, current controller state, or user memory. That makes it difficult to answer:

- what exactly failed
- whether the app recovered on its own
- whether a loading issue was policy-related, network-related, metadata-related, or media-related
- what should move into BEAM first

We need an explicit provenance layer that starts local-first, remains portable, and cleanly graduates to backend ingestion when Phoenix/Gleam is introduced.

## Scope

### In scope

- append-only local provenance capture for critical recovery/loading/crash flows
- compact developer-facing diagnostics summary in the app
- explicit architecture contract for future backend ingestion of provenance events
- typed-machine transport guidance for future backend handoff

### Out of scope

- implementing Phoenix ingestion in this change
- shipping Gleam runtime code in this repo in this change
- replacing user-facing backup/export JSON with Protobuf
- full observability dashboards or alerting backends

## Capabilities

1. `local-provenance-ledger` — durable local event capture for recovery and playback flows
2. `developer-diagnostics-surface` — fast summary and export path for debugging in the app
3. `beam-ingestion-contract` — a defined ownership split for future Phoenix/Gleam ingestion and analysis

## Dependencies

- existing Flutter startup recovery flow
- existing video retrieval/runtime sync flows
- existing Settings surface for export/debug affordances
- existing BEAM architecture direction in `add-beam-web-architecture-foundation`
