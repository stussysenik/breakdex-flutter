# Tasks — Evolve the Web Mirror into a Read-Write Platform

> Sequenced strictly by risk. Each phase is independently shippable and reversible. No phase
> deletes or mutates existing user state until a safer copy is verified.

## Phase 0: Decisions & provisioning (owner-run; agent supplies exact commands)
- [x] 0.1 **Decision 1 (RESOLVED 2026-06-16)** — Firestore interim (B) behind the provider-agnostic contract (C); swappable to `Phoenix+Postgres+S3` (A) later. Recorded in `design.md`.
- [x] 0.2 **Decision 2 (RESOLVED 2026-06-17)** — Drive scope = `drive.readonly`. The phone app creates the `Breakdex/` folder + media under its own OAuth client, so `drive.file` (per-app-created-files only) cannot enumerate them cross-client. `drive.readonly` is the documented fallback (README "Scope notes") and the minimal scope that both (a) sees the existing library and (b) cannot write/delete — correct for sensitive read-only viewing. Set in `web-mirror/.env.local`.
- [x] 0.3 **Identity decided 2026-06-17: `senik456@gmail.com` is the canonical account** (owner directive). The web mirror reads senik456's Drive; if the phone currently syncs elsewhere, the non-destructive media migration (per `identity-centralization`) is tracked there. OAuth consent screen has no test-user restriction (owner confirmed empty), so senik456 signs in without a test-user step.
- [x] 0.4 `senik456@gmail.com` set as **sole** web owner — `NEXT_PUBLIC_OWNER_ALLOWLIST=senik456@gmail.com` (itsmxzou removed per centralization directive). Sign-in verification against the real Drive is owner-run (interactive Google popup).

## Phase 1: Shared-truth + cache foundation (additive, shadow, reversible) — THE UNLOCK
- [ ] 1.1 Define the provider-agnostic **sync contract** interface (truth read/write, reconcile, `updatedAt`, soft-delete) shared in concept across Flutter and web.
- [ ] 1.2 Stand up the chosen backend (per 0.1) as a **shadow** store; no client treats it as truth yet.
- [ ] 1.3 Implement **non-destructive backfill**: read local Drift → write backend; assert zero local deletions/mutations. Test on a copy of real data.
- [ ] 1.4 Implement two-way **reconcile** (backend ↔ local cache) with last-writer-wins per field; local DB stays authoritative.
- [ ] 1.5 Web: persistent local cache (IndexedDB) + **persistent media cache** (Cache API) so a video downloads once and survives reload; reuse the existing object-URL cache as the in-session layer.
- [ ] 1.6 RxJS sync/cache streams on web; Riverpod (+ `rxdart` only if needed) on Flutter. No RxJS in Dart.
- [ ] 1.7 **Verify reconcile** end-to-end against real data; document the reversible cutover and rollback procedure. (Gate for Phase 2.)
- [ ] 1.8 Validation: backfill + reconcile unit/integration tests green; `flutter test` and web build green; manual reconcile verified.

## Phase 2: Web CRUD against verified truth
- [ ] 2.1 Flip web (then phone) to treat the backend as truth — only after 1.7 verified; keep rollback path.
- [ ] 2.2 Journal create/edit write-through with optimistic UI + per-edit sync status (`web-library-crud`).
- [ ] 2.3 Rename moves/combos + metadata edits as write-through; media blobs untouched.
- [ ] 2.4 Soft-delete/archive with recovery wired to existing archive semantics; no hard deletes.
- [ ] 2.5 Validation: round-trip a desktop edit → phone reconcile; conflicting-edit test resolves deterministically and retains history.

## Phase 3: Media governance & video swap-out (copy-then-verify)
- [ ] 3.1 Video swap-out: upload new content-addressed blob → update index → mark old orphaned only after confirm (`media-governance`).
- [ ] 3.2 Export with explicit scope selection; read-only w.r.t. truth.
- [ ] 3.3 Audited GC for orphaned blobs as a distinct, non-inline step.
- [ ] 3.4 Validation: failed-swap leaves original intact; export mutates nothing; GC only touches confirmed orphans.

## Phase 4: Enterprise web shell (additive UI, can land alongside Phases 2–3)
- [x] 4.1 Persistent toolbar (brand lockup, **Synced** status chip, source label, sign-out) across all sections (`Mirror.tsx` header).
- [x] 4.2 Sectioned navigation for Library / Combos / Journal / Plans / Stats (tablist; Export section lands with Phase 3).
- [x] 4.3 **Breadcrumbs** (`Breakdex ▸ Section ▸ [Subsection] ▸ [Item]`), each segment navigable, `nav[aria-label=Breadcrumb]` landmark. (Item-level crumb fully lands when items get routes in Phase 2; today items open as modals.)
- [x] 4.4 Purposeful, non-blocking section transition animation (`key={tab}` + `anim-rise`, honoring `prefers-reduced-motion`).
- [x] 4.5 Validation: toolbar + breadcrumb + section-switch verified in chrome-devtools (demo fixture); `next build` green (types valid, 5/5 pages). Real-data pass deferred to owner sign-in.

## Phase 5: Deploy & verify
- [ ] 5.1 Vercel env for the new backend + auth; deploy a **preview**; validate sign-in + CRUD + media swap against the owner's real Drive/backend.
- [ ] 5.2 Confirm non-owner rejection and that no flow hard-deletes user state.
- [ ] 5.3 Promote to production; record the URL.
- [ ] 5.4 Mark `add-web-mirror-player` superseded for write scope; update `add-beam-web-architecture-foundation` `web-access-foundation` (first read-write slice shipped).
