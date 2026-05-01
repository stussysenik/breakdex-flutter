# Tasks — Add Phoenix Provenance Ingestion And Recovery Analysis

## Phase 1: Backend Boundary Definition
- [ ] 1.1 Define Phoenix ingestion responsibilities and API shape
- [ ] 1.2 Define raw event storage versus derived incident storage
- [ ] 1.3 Define replay-query requirements for developer debugging

## Phase 2: Analysis Model
- [ ] 2.1 Define incident classification rules from event sequences
- [ ] 2.2 Define recovery success/failure rollups
- [ ] 2.3 Define the first operator-facing summaries or alert triggers

## Phase 3: Gleam Scope
- [ ] 3.1 Define the first bounded Gleam module for provenance analysis
- [ ] 3.2 Define the interface between Phoenix ingestion and Gleam classification
- [ ] 3.3 Keep transport and framework glue outside the initial Gleam slice

## Phase 4: Future Implementation
- [ ] 4.1 Implement ingestion endpoints and persistence
- [ ] 4.2 Implement derived incident jobs
- [ ] 4.3 Implement replay/debug APIs
