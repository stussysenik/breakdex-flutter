# Tasks — Adopt Convex via a Provider-Agnostic SyncBackend

> Sequenced strictly by risk. Additive, shadow, reversible. No task deletes or mutates existing
> local state until a safer copy is verified. Drift stays canonical until each entity is proven.

## Phase 0: Decisions & provisioning (owner-run; agent supplies exact steps)
- [ ] 0.1 **Decision 1 (RESOLVED)** — Canonical backend = **Convex** (Cloud now, self-host escape hatch); supersedes Phoenix+Postgres+S3. Recorded in `design.md`.
- [ ] 0.2 Provision a Convex Cloud project (free tier). Capture deployment URL + admin key into the app's secret config (not committed). Owner-run; agent supplies CLI steps.
- [ ] 0.3 Confirm scope boundary: Firebase **Auth** and **Storage** remain in place this change; only **Firestore** metadata moves. Note follow-on changes for auth + web CRUD.

## Phase 1: SyncBackend contract + Convex shadow (additive, no client treats Convex as truth yet)
- [ ] 1.1 Define the `SyncBackend` Dart interface (`push`/`pull`/`subscribe`, `SyncRecord`, `Tombstone`, `EntityType`) parallel to `AssetStorageProvider`. No caller wired yet.
- [ ] 1.2 Author the Convex schema + queries/mutations mapped from the Drift metadata tables (`moves`, `combos`/`combo_moves`, `reviews`, `fsrs_cards`, `decks`/`deck_moves`), each with `updatedAt` + local-row id; video pointer only.
- [ ] 1.3 Implement the **Convex** `SyncBackend` (community `convex_flutter` client; isolate it so the HTTP API is a drop-in fallback per design Decision 6).
- [ ] 1.4 Implement **non-destructive backfill** (read local Drift → write Convex shadow); assert zero local deletions/mutations. Run against a **copy** of real data first.

## Phase 2: Strangler-fig per entity (dual-read; one entity at a time; reversible)
- [ ] 2.1 `moves`: wire `SyncBackend` behind `sync_service`/`sync_aware_repositories` with **dual-read** (Convex first, Firestore fallback). Verify two-way reconcile vs real data → cut over → keep rollback.
- [ ] 2.2 `combos` + `combo_moves`: same dual-read → verify → cut over.
- [ ] 2.3 `reviews`: same dual-read → verify → cut over.
- [ ] 2.4 `fsrs_cards` (polymorphic entityId+entityType): same dual-read → verify → cut over.
- [ ] 2.5 `decks` + `deck_moves`: same dual-read → verify → cut over.
- [ ] 2.6 Tombstone deletes verified end-to-end across clients (no hard-delete crosses the boundary).

## Phase 3: Retire Firestore metadata path + safety net
- [ ] 3.1 Remove the Firestore **metadata** read/write paths only after **all** entities are green; leave Firebase Auth/Storage untouched.
- [ ] 3.2 Add periodic **JSON export** of all metadata to the user's Drive (data-ownership / lock-in safety net).
- [ ] 3.3 Document the self-host cutover procedure as the escape hatch (no provisioning yet).

## Validation
- [ ] V.1 Backfill + per-entity reconcile unit/integration tests green; tombstone + dual-read tests green.
- [ ] V.2 `flutter analyze` clean; `flutter test` green; app builds for iOS + Android.
- [ ] V.3 Manual: edit on phone reflects on a second subscribed client (eventual-realtime); offline edit flushes on reconnect; no local row lost across a full cutover on a copy of real data.
- [ ] V.4 `openspec validate add-convex-sync-backend --strict --no-interactive` passes.
