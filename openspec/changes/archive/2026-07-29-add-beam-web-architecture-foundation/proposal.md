# Add BEAM Web Architecture Foundation

## Summary

Define the architecture direction that connects the existing Flutter app to a future web-accessible Breakdex platform without rewriting the product around speculative abstractions. The chosen direction keeps the current Flutter client as the near-term shipping surface while standardizing on a future `Phoenix + Postgres + S3-compatible storage` system spine, with reducer-style state, selective FRP, selective CRDT usage, and provider pluggability.

## Motivation

Breakdex currently has a credible local-first mobile runtime, but its long-term system direction is under-specified. Questions around BEAM, Gleam, CRDTs, media vendors, web access, and provider pluggability risk producing parallel architectures unless the repo carries an explicit contract.

We need a spec that clarifies:

- what the current app keeps using now
- what the future backend/web direction is
- which patterns are default versus optional
- how media and metadata ownership are separated
- where pluggability belongs in the roadmap

## Scope

### In scope

- architecture contract for mobile, backend, web, and media layers
- state-management philosophy for Flutter and future web surfaces
- CRDT guidance
- storage and delivery guidance
- long-term provider pluggability posture
- documentation updates that expose the contract in the repo

### Out of scope

- implementing a Phoenix backend in this change
- migrating the app away from Flutter
- adding full web support in this change
- shipping bring-your-own-key or bring-your-own-bucket flows now

## Capabilities

1. `architecture-direction-contract` — a clear repo-level statement of the chosen stack and system boundaries
2. `web-access-foundation` — a documented requirement that user data be reachable from a future web app through the same canonical backend
3. `provider-pluggability-posture` — a documented rule that storage/media providers remain replaceable without becoming immediate blockers

## Dependencies

- existing Flutter/Riverpod/Drift/FSRS app runtime
- existing docs structure in `README.md` and `docs/`
- existing OpenSpec process under `openspec/changes/`
