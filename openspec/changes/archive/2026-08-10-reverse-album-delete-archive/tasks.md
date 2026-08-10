# Tasks — Reverse Album Delete Archive & Recovery

> **Language: Dart (Flutter) + native iOS (PhotoKit).** Depends on: `appwrite`
> (sync metadata), `enforce-face-law-conformance` (Recently Deleted UI on `AppScreen`).
> Implementation in a fresh student session — never this one.

Ledger rule: tick in the same commit that lands the work. Binary truth: no tick
without terminal-verified evidence (analyze/test/build output). Phase 1 data work
already landed (`5707fe1`/`b28cfa1`/`d382437`); the remaining phases are implementation.

## Phase 1: Data Model (landed)
- [x] 1.1 Add move archive columns locally and in Appwrite migrations (landed `5707fe1`)
- [x] 1.2 Filter archived moves out of active move queries while preserving by-ID access (landed `b28cfa1`)
- [x] 1.3 Add DAO helpers for archived lists, tracked managed assets, and expired archives (landed `d382437`)

## Phase 2: Reconciliation
- [ ] 2.1 Extend the Photos bridge with read-access and managed-asset lookup methods
- [ ] 2.2 Add a managed album reconciliation service that archives missing assets
- [ ] 2.3 Trigger reconciliation on startup, resume, and Photos library change events
- [ ] 2.4 Add focused tests for archive reconciliation behavior

## Phase 3: Recovery
- [ ] 3.1 Add a Recently Deleted screen for archived moves (on `AppScreen`, Settings → Data)
- [ ] 3.2 Restore archived moves by recreating the managed album copy
- [ ] 3.3 Permanently delete archived moves through the existing cleanup path
- [ ] 3.4 Purge archived moves older than 30 days

## Phase 4: Sync & Backup
- [ ] 4.1 Sync `archived_at` and `archive_reason` through move metadata (Appwrite)
- [ ] 4.2 Preserve archived moves in full backup export/import
- [ ] 4.3 Add/update tests for local archive persistence and sync shape

## Phase 5: Validation
- [ ] 5.1 Run focused Flutter tests after each slice
- [ ] 5.2 Run analyzer on touched files
- [ ] 5.3 Run iOS native build validation for the PhotoKit bridge
