# Add Phoenix Provenance Ingestion And Recovery Analysis

## Summary

Define the backend slice that receives Breakdex provenance events, stores them canonically, correlates them across sessions, and powers replayable recovery analysis. This is the first serious operational domain that should move behind Phoenix, with Gleam reserved for bounded analysis modules where typed functional rules help.

## Motivation

Local diagnostics help a single device explain itself, but they do not solve:

- repeated failures across launches
- repeated failures across devices
- correlation between recovery attempts and later success
- operator-facing analysis of real-world video reliability

That logic is long-lived, stateful, and operational. It belongs on BEAM, not in the Flutter widget/runtime layer.

## Scope

### In scope

- Phoenix ownership of provenance ingestion
- Postgres storage model for canonical events and derived incidents
- replayable recovery-analysis contract
- bounded Gleam analysis module candidates

### Out of scope

- implementing the full backend in this change
- changing the mobile UI surface beyond what is needed for the contract
- replacing local-first client behavior

## Capabilities

1. `provenance-ingestion` — server-side intake of client event envelopes
2. `recovery-incident-analysis` — derived classification of repeated failures and recoveries
3. `developer-replay-surface` — future API basis for “what went wrong” tracing across sessions

## Dependencies

- BEAM architecture foundation
- typed Protobuf event envelope
- local provenance capture semantics already present in Flutter
