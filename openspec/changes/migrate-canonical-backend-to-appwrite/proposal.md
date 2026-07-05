# Migrate the Canonical Backend to Appwrite (superseding Convex) + Unified Identity + Web Studio Enablement

## Summary

Replace **Convex** with **Appwrite** as Breakdex's canonical metadata backend — before any data
ever reaches Convex — and widen the change to cover what Appwrite uniquely consolidates: a
**single Google-OAuth identity across mobile and web** (Appwrite Account, retiring Firebase Auth
with Firestore), **first-class realtime** (Appwrite Realtime channels replacing the polling
`subscribe`), and the platform substrate the **web authoring studio**
(`add-web-authoring-and-lifecycle-studio`) needs to ship against.

The provider-agnostic **`SyncBackend`** contract, the `moves.updatedAt` LWW clock (schema v23),
the tombstone/idempotency semantics, the non-destructive backfill mechanism, and the in-flight
`moves` dual-read work **all survive unchanged** — they were designed exactly so the concrete
backend could be swapped without caller changes. What gets replaced is precisely the
Convex-specific shell: `convex/` (schema + functions) and the three transport/backend Dart files.

The strangler-fig plan from `add-convex-sync-backend` is **retargeted, not redesigned**:
Firestore remains the live path; Appwrite becomes the shadow; entities cut over one at a time
behind per-entity kill-switches; **Drift stays canonical on-device** until each entity's two-way
reconcile is verified against real data.

## Motivation

- **Self-hosting is first-class, not an escape hatch.** Appwrite is one product whether run on
  Appwrite Cloud or on the owner's own hardware (a Hetzner token is already provisioned in
  `.env.local`). Convex's self-host story is second-class relative to its cloud. The owner's
  long-horizon requirement is genuine ownership of the data plane; with Appwrite the cloud→self
  cutover is a config swap on the same `SyncBackend` implementation, not a platform migration.
- **One platform consolidates three planned migrations.** Appwrite ships Auth (Google OAuth with
  provider-token passthrough for Drive), Databases, Realtime, Functions, and Storage. That
  collapses: (a) the eventual Firebase Auth retirement, (b) the web client's identity problem,
  and (c) a future additional blob sink (thumbnails/previews) into the same platform this change
  already adopts — instead of Convex-for-data plus something else for each.
- **The switch will never be cheaper.** Task 0.2 (Convex production deploy key) was never
  completed; `syncBackend` is `null` in `providers.dart`; **zero production data exists in
  Convex**. The Convex-specific surface is 3 Dart files + the `convex/` directory. Everything
  above the transport seam transfers.
- **Launch pressure favors a managed start with an owned exit.** Appwrite Cloud now (zero ops
  while the owner ships and interviews), self-hosted Appwrite on Hetzner as a keys-in-`.env`
  cutover later — the same binary choice Convex offered, but with both halves of it credible.

## Scope

**In scope**
1. **Template hardening first** (Phase H): fix the four audit-confirmed defects in the dual-read
   template *before* it is stamped onto a second provider and five more entities (cursor rollback
   hole, LWW clock-precision mismatch, per-record fault isolation, dual-write precondition), plus
   the pre-existing `downloadVideos` >10 MB silent-skip bug and the lint-rule additions.
2. Appwrite provisioning (Cloud project + Google OAuth provider + `.env` conventions carrying
   both cloud and self-host keys).
3. Appwrite schema + server-side sync functions (LWW push/pull, append-only review events,
   server-derived FSRS via a **Dart** Appwrite Function reusing `fsrs ^2.0.1` — identical
   scheduling math client and server).
4. `AppwriteSyncBackend` + `AppwriteTransport` behind the existing seam; Realtime-backed
   `subscribe`; removal of the Convex implementation and `convex/` once parity tests are green.
5. **Unified identity**: Appwrite Account with Google OAuth as THE identity on mobile + web;
   Flutter login screen + auth logic; `google_sign_in` retained solely to mint Drive-scope tokens
   on mobile; legacy Firebase-uid mapping so existing records are claimed, never orphaned.
6. Strangler-fig cutover per entity (moves → combos → reviews → fsrs_cards → decks), dual-read
   **and dual-write**, per-entity kill-switches, tombstone verification.
7. Firestore + Firebase Auth retirement, Drive JSON-export safety net, self-host cutover runbook.
8. Web studio enablement: evolve the in-repo `web-mirror/` (Next.js 15) onto Appwrite (auth, data,
   realtime) as the substrate for the full authoring studio; the studio's own capabilities remain
   specified by `add-web-authoring-and-lifecycle-studio` and are **retargeted, not respecified**.
9. Video-locality (device-only / cloud / both) surfaced as a first-class concept in both clients.

**Out of scope**
- Moving video bytes. **Google Drive stays the canonical blob store** (user-owned quota is the
  cheapest structure at scale and it is already shipped + self-healing). Appwrite Storage enters
  later, flagged, as an *additional* sink (thumbnails first) through the existing `CloudProvider`
  fan-out — never as a replacement, per the multi-sink principle.
- CRDTs. Per-record LWW + tombstones + append-only events is the sync model; "realtime feel"
  comes from Appwrite Realtime subscriptions, not merge-free data types.
- Native Swift/Kotlin clients (Appwrite has first-party SDKs when that day comes).

## Non-negotiable invariants (inherited and re-asserted)

- Additive-only, migration-safe: no task deletes or mutates local user state; deletes cross the
  boundary only as tombstones.
- Drift remains authoritative on-device per entity until that entity's two-way reconcile is
  verified against (a copy of) real data.
- Every cutover step has an instant, config-level rollback (per-entity kill-switch prefs).
- No secrets in the repo; all endpoints/keys via gitignored `.env.local`.
- `flutter analyze` clean and full test suite green at every task boundary.

## Relationship to prior changes

- **Supersedes** `add-convex-sync-backend` Phases 0.2/1.2/1.3 (Convex-specific shell) while
  **absorbing** its contract, backfill, LWW-clock, and dual-read work and its Phase 2/3 plan.
  Archive that change as superseded when this one lands.
- **Honors** `add-beam-web-architecture-foundation`'s abstract capabilities
  (web-access-foundation, provider-pluggability-posture) with Appwrite as the concrete provider.
- **Enables** `add-web-authoring-and-lifecycle-studio` (FULL-BIDIRECTIONAL-FIRST) by supplying
  its missing prerequisite: the shared source of truth + web identity.
