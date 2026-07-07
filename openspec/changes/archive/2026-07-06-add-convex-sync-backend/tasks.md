# Tasks — Adopt Convex via a Provider-Agnostic SyncBackend

> Sequenced strictly by risk. Additive, shadow, reversible. No task deletes or mutates existing
> local state until a safer copy is verified. Drift stays canonical until each entity is proven.

## Phase 0: Decisions & provisioning (owner-run; agent supplies exact steps)
- [ ] 0.1 **Decision 1 (RESOLVED)** — Canonical backend = **Convex** (Cloud now, self-host escape hatch); supersedes Phoenix+Postgres+S3. Recorded in `design.md`.
- [~] 0.2 Provision a Convex Cloud project (free tier). Capture deployment URL + admin key into the app's secret config (not committed). Owner-run; agent supplies CLI steps.
  - Cloud project `brilliant-mongoose-46` created; `CONVEX_URL`/`CONVEX_SITE_URL` captured in gitignored `.env.local`. **Remaining:** owner generates a Production deploy key in the dashboard so `CONVEX_DEPLOY_KEY=… npx convex deploy` can push headlessly (CLI login isn't available non-interactively). Schema+functions already proven deploy-valid against a local backend.
- [ ] 0.3 Confirm scope boundary: Firebase **Auth** and **Storage** remain in place this change; only **Firestore** metadata moves. Note follow-on changes for auth + web CRUD.

## Phase 1: SyncBackend contract + Convex shadow (additive, no client treats Convex as truth yet)
- [x] 1.1 Define the `SyncBackend` Dart interface (`push`/`pull`/`subscribe`, `SyncRecord`, `SyncTombstone`, `SyncDelta`, `SyncEntityType`) parallel to `AssetStorageProvider`. No caller wired yet. → `lib/core/sync/sync_backend.dart` (analyzer clean; additive, touches no data path).
- [x] 1.2 Author the Convex schema + queries/mutations mapped from the Drift metadata tables (`moves`, `combos`/`combo_moves`, `reviews`, `fsrs_cards`, `decks`/`deck_moves`), each with `updatedAt` + local-row id; video pointer only. → `convex/schema.ts` (descriptive envelope + append-only `reviewEvents` + derived `fsrsCards`), `convex/sync.ts` (LWW `pushRecords`/`pullRecords`), `convex/reviews.ts` (idempotent `appendReviewEvents`), `convex/fsrs.ts` (event-read + card-pull halves for the 2.4 reduce). All 15 indexes + functions verified deploy-valid (local backend, zero TS errors). FSRS scheduler math deferred to 2.4 per Decision 7 — not stubbed/faked.
- [x] 1.3 Implement the **Convex** `SyncBackend`, isolated behind a swappable `ConvexTransport` seam per design Decision 6. Shipped the working **HTTP** transport (`ConvexHttpTransport` over `POST /api/query`|`/api/mutation`, `format:"json"`) because it is fully unit-testable and runs headlessly — the native `convex_flutter` reactive transport is a documented drop-in for true realtime `subscribe` (until then the backend polls `pull`). → `lib/core/sync/backends/convex_transport.dart` (seam + `ConvexException`), `convex_http_transport.dart` (HTTP impl), `convex_sync_backend.dart` (maps the contract onto `sync:pushRecords`/`pullRecords`, `reviews:appendReviewEvents`/`pullReviewEvents`, `fsrs:pullCards`; `fsrsCard` push forbidden, `reviewEvent` delete-free). Proven: `flutter analyze` clean + 9 unit tests green (`test/core/sync/convex_sync_backend_test.dart`) round-tripping every entity's marshalling against the exact JSON the Convex functions emit. Additive — no caller wired, no data path touched.
- [~] 1.4 Implement **non-destructive backfill** (read local Drift → write Convex shadow); assert zero local deletions/mutations. Run against a **copy** of real data first.
  - Mechanism shipped: `moves.updatedAt` LWW clock (schema v23, additive + backfilled from `created_at`; `MovesDao` stamps it on write yet preserves an explicit reconcile timestamp) → `migration_v23_test`. `SyncBackfillService.backfillMoves()` reads every local move (incl. archived, as upserts never tombstones) and upserts to the shadow in idempotent batches (deterministic `clientOpId`). `moveToSyncRecord` emits a JSON-safe payload (BigInt→string, DateTime→ms) proven through the transport's `jsonEncode`. Read-only against Drift — the **non-destructive invariant is proven by a byte-identical before/after snapshot test**. → `lib/core/sync/backfill/sync_backfill_service.dart`, `test/core/sync/sync_backfill_service_test.dart` (7 green). **Remaining (owner-gated):** the live "run against a copy of real data" pass needs the Convex Production deploy key from task 0.2. `combos`/`decks` backfill waits on their own `updatedAt` (tasks 2.2/2.5).

## Phase 2: Strangler-fig per entity (dual-read; one entity at a time; reversible)
- [ ] 2.1 `moves`: wire `SyncBackend` behind `sync_service`/`sync_aware_repositories` with **dual-read** (Convex first, Firestore fallback). Verify two-way reconcile vs real data → cut over → keep rollback.
- [ ] 2.2 `combos` + `combo_moves`: same dual-read → verify → cut over.
- [ ] 2.3 `reviews` → **append-only `reviewEvents`** in Convex (with `clientOpId`); dual-read → verify → cut over.
- [ ] 2.4 `fsrs_cards` (polymorphic entityId+entityType): **derive** card state via a Convex reduce over `reviewEvents` (NOT LWW-written); verify derived state matches local against a copy of real data → cut over.
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
