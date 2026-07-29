# Tasks — Add Provenance Ledger And BEAM Ingestion Contract

## Phase 1: Local Capture
- [x] 1.1 Add append-only local provenance journaling outside the database lifecycle
- [x] 1.2 Capture startup recovery, crash, and video retrieval provenance events
- [x] 1.3 Keep the local journal bounded and exportable

## Phase 2: Developer Diagnostics
- [x] 2.1 Add a compact provenance report service for recent health summaries
- [x] 2.2 Add a Settings diagnostics surface for recent signals and raw export
- [x] 2.3 Add focused tests for journal parsing, summarization, and retrieval provenance

## Phase 3: BEAM Handoff Definition
- [ ] 3.1 Define the Protobuf event envelope for backend ingestion
- [ ] 3.2 Define Phoenix ingestion responsibilities versus Flutter local ownership
- [ ] 3.3 Define when provenance upload should occur for offline-first clients
- [ ] 3.4 Define the first Gleam-appropriate bounded module for provenance analysis

## Phase 4: Future Backend Work
- [ ] 4.1 Add a backend-facing spool/uploader once Phoenix ingestion exists
- [ ] 4.2 Add cross-session correlation and replayable recovery analysis
- [ ] 4.3 Add operator-facing summaries or alerts for repeated asset/recovery failures
