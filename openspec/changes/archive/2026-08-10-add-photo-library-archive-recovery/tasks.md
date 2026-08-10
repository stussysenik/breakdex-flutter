# Tasks — Add Photo Library Archive Recovery

## Phase 1: Archive Model
- [x] 1.1 Add move archive columns locally and in Supabase migrations (landed `5707fe1`)
- [x] 1.2 Add active vs archived move DAO queries and restore/archive helpers (landed `d382437`)
- [x] 1.3 Route repository-backed active surfaces through non-archived move queries (landed `b28cfa1`)

## Phase 2: Native Photos Reconciliation
- [ ] 2.1 Extend `VideoAlbumPlugin` with tracked-asset reconcile APIs and stream events
- [ ] 2.2 Add Dart bridge models/methods for reconcile and managed-asset restore
- [ ] 2.3 Add a service that updates tracked assets, archives moves on external deletion, and attempts local recovery from Photos/iCloud assets

## Phase 3: Recovery UI
- [ ] 3.1 Add a Recently Deleted screen for archived moves
- [ ] 3.2 Add restore and permanent-delete actions
- [ ] 3.3 Link Recently Deleted from Settings > Data

## Phase 4: Validation
- [ ] 4.1 Add/update unit tests for archive filtering and reconcile behavior
- [ ] 4.2 Add native bridge tests for reconcile/restore channel payloads
- [ ] 4.3 Run analyze and focused Flutter/native validation commands
