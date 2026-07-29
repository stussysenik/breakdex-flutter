# Tasks — Add Protobuf Event Envelope And Upload Spool

## Phase 1: Schema Definition
- [x] 1.1 Define the Protobuf envelope and core provenance enums
- [x] 1.2 Define typed submessages for recovery, retrieval, and crash events
- [x] 1.3 Define schema versioning and compatibility rules

## Phase 2: Client Spool Contract
- [ ] 2.1 Define local spool persistence and retention rules
- [ ] 2.2 Define flush triggers for offline-first clients
- [ ] 2.3 Define acknowledgment and compaction semantics

## Phase 3: Integration Planning
- [ ] 3.1 Define how event emitters write both local journal entries and Protobuf spool records
- [ ] 3.2 Define failure handling when spool writes fail but local journal writes succeed
- [ ] 3.3 Define test coverage expectations for schema evolution and queue durability

## Phase 4: Future Implementation
- [x] 4.1 Add `.proto` sources to the repo
- [ ] 4.2 Implement client spool writer/reader
- [ ] 4.3 Connect the spool to future Phoenix ingestion
