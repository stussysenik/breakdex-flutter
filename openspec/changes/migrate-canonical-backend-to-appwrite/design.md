# Design — Appwrite Canonical Backend

Decisions locked in the 2026-07-05 grill session. Each records the alternative that lost and why.

## D1 — Appwrite supersedes Convex (decision reversal, made while reversal is free)

**Decision:** Appwrite is the canonical metadata backend. Convex is dropped before deployment.

**Why now is the moment:** task 0.2 (Convex prod deploy key) was never completed; `syncBackend`
is `null` in `lib/core/providers.dart`; no data exists in Convex. The Convex-specific surface is
exactly `convex/` + `lib/core/sync/backends/convex_{transport,http_transport,sync_backend}.dart`.
The contract (`sync_backend.dart`), LWW clock (schema v23), backfill service, dual-read seam, and
all their tests are provider-neutral and carry over.

**Why Appwrite beats Convex for this product:**
- Self-hosting is the same product, not a second-class deployment. The owner already holds
  Hetzner infrastructure. Long-horizon cost and ownership were the stated drivers.
- Platform consolidation: Auth (Google OAuth incl. provider-token passthrough), Databases,
  Realtime, Functions (Dart runtime), Storage — one adoption covers identity, realtime, and a
  future thumbnail/preview sink. Convex covers only the data/functions plane.
- First-class Flutter SDK (`appwrite` on pub.dev) and Web SDK; Dart Functions runtime lets the
  server reuse the exact `fsrs ^2.0.1` package the client uses (D5).

**What we give up (recorded honestly):** Convex's reactive-query model (subscriptions that
re-run queries) is strictly more elegant than channel-based Realtime events; Convex's TS
functions had already been written and deploy-validated. Accepted: the elegance difference does
not change what the `SyncBackend` contract can express, and the sunk TS code is ~2 files whose
*semantics* (LWW push/pull, append-only events, derived cards) port directly to Dart Functions.

**Guard against repeat reversals:** this is the second backend decision reversal (Phoenix →
Convex → Appwrite). The reversal is cheap only because nothing deployed. Once Phase 0 provisions
Appwrite and Phase 4 starts moving real data, the decision is **locked** — future misgivings are
handled by the self-host lever, not another platform swap.

## D2 — Hosting: Appwrite Cloud now, self-host as a config swap

**Decision:** Launch on Appwrite Cloud (free tier; verify current limits at provisioning time).
`.env.local` carries BOTH deployments' keys from day one:

```
# Active deployment (the app reads these)
APPWRITE_ENDPOINT=https://<region>.cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=…
APPWRITE_API_KEY=…            # server-side/CLI only, never bundled into clients

# Self-host standby (provisioned later on Hetzner; cutover = swap the block above)
APPWRITE_SELFHOST_ENDPOINT=…
APPWRITE_SELFHOST_PROJECT_ID=…
APPWRITE_SELFHOST_API_KEY=…
```

Endpoint/project are runtime config (Dart: `--dart-define` / env plumbing; web: `NEXT_PUBLIC_*`
for endpoint+project only). No hostname is ever hard-coded. The self-host cutover runbook
(Phase 5) covers: Docker Compose install, Appwrite's own migration tooling for
cloud→self transfer, mariadb-dump + offsite backup schedule — because a solo-maintained box
without backup discipline is itself a data-loss vector.

**Rejected:** self-host day 1 (owner becomes SRE during launch + job-application crunch);
dual-live cloud+mirror (doubles ops surface before launch; revisit post-launch).

## D3 — Identity: Appwrite Account is THE identity, everywhere

**Decision:** Appwrite Account with the Google OAuth2 provider is the single identity on mobile
and web. One Appwrite `userId` keys all synced records.

- **Flutter:** `appwrite` SDK OAuth2 session (callback scheme `appwrite-callback-<PROJECT_ID>`).
  `google_sign_in` is retained for exactly one job: minting Drive-scope access tokens for the
  existing video plane. It no longer defines identity.
- **Web:** Web SDK `createOAuth2Session` with the Drive readonly scope requested at session
  creation; the session's provider access token is used for Drive playback (verify the current
  session/token API shape against Appwrite docs at implementation time — do not code from memory).
- **Legacy mapping:** existing Firestore records are keyed by Firebase uid. On first Appwrite
  login, a `legacyIdentities` table maps `firebaseUid → appwriteUserId` (matched via verified
  Google email, additive, auditable). Backfill and pulls resolve through this map so no record is
  orphaned. Firebase Auth retires only in Phase 5 with Firestore.

**Rejected:** web-only Appwrite auth with mobile unchanged — permanent dual-identity plumbing,
cross-system auth bugs, duplicate-user risk; cheaper today, expensive forever.

## D4 — Video bytes: Drive canonical; Appwrite Storage additive-later; locality first-class

**Decision (answering the owner's "how'd you do it?"):** the cheapest / largest-scale structure
is the one already shipped — **each user's videos live in their own Google Drive quota** (cost
scales to zero for the operator; users already own their data; self-heal shipped `c3954fc`).
Appwrite stores metadata + Drive pointers + content hashes only, exactly as the `SyncBackend`
contract models. The web studio plays video via the Drive API with the user's own OAuth token.

Appwrite Storage enters **post-cutover, behind a flag, as an additional sink** through the
existing `CloudProvider` fan-out — thumbnails/preview stills first (small, cache-friendly, makes
the web grid fast), full-video mirroring only if real usage demands it. Never primary; the
multi-sink principle stands.

**Locality is a product concept, not an implementation detail:** every video has a visible state —
`device-only` / `cloud` / `both` — surfaced in both clients (badge + filter), driven by the
existing manifest + on-demand download runtime. "Local sandbox videos" vs "cloud videos" is the
mental model the owner wants users to hold; the data already exists, the UI must expose it.

## D5 — Sync semantics: unchanged; server-side LWW lives in Appwrite Functions (Dart)

**Decision:** per-record LWW on `updatedAt` + tombstones (never hard-deletes) + idempotent
`clientOpId` + **append-only** `reviewEvents` + **server-derived** `fsrsCards`. No CRDTs: for
single-user record-shaped data on 2–3 devices, concurrent-edit merging buys nothing and costs the
launch. "Live" comes from Appwrite Realtime channel subscriptions feeding the existing
`subscribe` contract method.

LWW conflict resolution and idempotency enforcement are **server-side**, in an Appwrite Function
(`sync-push`) that accepts a batched payload — porting `convex/sync.ts` semantics. This also
solves Appwrite's lack of batched row mutations: one Function execution applies N records
atomically instead of N REST calls. `sync-pull` returns a delta plus a **server** cursor
(high-water mark), which the client persists per-entity (fixes audit finding A2, see D9).

The FSRS derive Function runs on the **Dart runtime** and imports `fsrs: ^2.0.1` — the identical
package the Flutter client uses, so scheduling math cannot skew between client and server.
Trigger: on `reviewEvents` creation (or lazily at pull; executor benchmarks both, prefers the
simpler that meets the contract's "clients pull but never push fsrsCard" rule).

Tie policy (audit A6c): equal LWW clocks → remote wins; documented and tested.

## D6 — Transport seam preserved: `AppwriteTransport` mirrors `ConvexTransport`

**Decision:** implement `lib/core/sync/backends/appwrite_transport.dart` (seam + typed
exception), `appwrite_sync_backend.dart` (contract → Function/Realtime mapping). The 9 green
transport marshalling tests from the Convex backend are ported as the parity gate; the Convex
files and `convex/` are deleted in the same task that lands parity (git history preserves them).
The `subscribe` implementation must not replicate the Convex poller's cancellation leak (audit
B1): every loop iteration must observe cancellation.

## D7 — Web: evolve `web-mirror/` in-repo into the authoring studio substrate

**Decision:** the existing `web-mirror/` (Next.js 15, React 19, UnoCSS — currently Firebase-auth
read-only manifest reader) is the web client. This change re-platforms it: Appwrite web SDK,
Appwrite OAuth login, table reads + Realtime, Drive playback via provider token. The **full
authoring studio at launch** (owner's call: combo/set builders, lifecycle management,
DELETE=TOMBSTONE, full bidirectionality) ships against this substrate per
`add-web-authoring-and-lifecycle-studio` — that change's specs are retargeted
(Firestore→Appwrite) rather than duplicated here. Priority ordering per the owner: **Flutter
backend migration completes first**, web studio phases follow.

**Rejected:** Flutter Web (bundle weight, defeats "thin client"); fresh scaffold (a working
Next-15 shell with the Drive-manifest reader already exists in-repo).

## D8 — Strangler-fig retargeted, now with dual-WRITE before any read cutover

Audit finding A1 exposed a sequencing flaw in the original plan: dual-read without dual-write
strands the shadow stale and makes the kill-switch a loaded gun. Corrected ordering per entity:

1. **Backfill** entity into Appwrite (non-destructive, byte-identical snapshot proof — mechanism
   already shipped for moves).
2. **Dual-write**: every local flush pushes to BOTH Firestore and Appwrite (idempotent, additive).
3. **Dual-read** behind the per-entity kill-switch (Appwrite first, Firestore fallback — the
   uncommitted `pullMovesFromBackend` work, upgraded per D9).
4. **Verify** two-way reconcile against (a copy of) real data; soak; then cut reads over.
5. **Tombstone** propagation verified end-to-end before any delete crosses (task-gated, last).

Entity order unchanged: `moves → combos/combo_moves → reviewEvents → fsrs_cards (derived) →
decks/deck_moves`. Rollback at every step = flip the pref off; Firestore path is untouched until
Phase 5.

## D9 — Harden the template before stamping it (audit 2026-07-05)

The dual-read template gets four interface-preserving fixes BEFORE the Appwrite copy inherits it
(full detail in tasks Phase H): dedicated per-entity backend cursor persisted from `delta.cursor`
(never the shared Firestore `last_sync_at` — closes the rollback hole and clock-skew misses);
LWW comparison normalized to whole-second precision (Drift stores DateTime as Unix seconds while
backend clocks carry milliseconds — an older remote could clobber a newer local edit within the
same second); per-record fault isolation in the merge loop (one malformed record must not abort
the batch and trigger the blind non-LWW Firestore fallback); merge loop wrapped in a transaction.
Plus: the pull-side codec moves out of the push-only backfill service into
`sync/codecs/move_codec.dart` before combos replicate the layout, and the pre-existing
`downloadVideos` bug (silently skips any video >10 MB via `getData()`'s default cap, buffers
whole files in RAM) is fixed with streamed `writeToFile()`.

## D10 — Never lose data: the safety net is layered, not aspirational

- Tombstones only across every boundary; no hard-delete propagates (existing invariant).
- Byte-identical before/after Drift snapshot test for every backfill (mechanism exists; reused
  per entity).
- Periodic **JSON export of all metadata to the user's Drive** (lock-in + disaster safety net;
  was Convex-plan task 3.2, kept verbatim).
- Appwrite Cloud: platform-managed durability; self-host runbook mandates `mariadb-dump` +
  offsite copy + restore drill before any cutover.
- The multi-sink video plane (Drive + optional future Appwrite Storage + PocketBase local backup
  per the standing project principle) is unaffected by this change.

## D11 — Overnight wave (owner ruling 2026-07-12): finish it like a product; proof split overnight/morning

**Ruling.** Merge to `main` is done (single source of truth; `main` == `f87f4fc`, pushed). The
owner believes 0.2's console half is handled — verify (task 0.5), don't wait. An autonomous
overnight executor lands the wave (see the tasks.md preamble for order + converted gates); the
owner live-proves on the physical device the next morning (Phase M).

- **"Web" = the Flutter Web product** (locked stack: the released consumer app). The
  `web-mirror/` studio (D7, Phase 6, task 3.5) is NOT in the wave — it stays queued behind the
  Flutter cutover. The wave's web surface is `add-web-first-release-and-monetization` 1.4/1.5.
- **Sign-in stays optional.** 3.3's "app requires an Appwrite session" is scoped: a session is
  required to *sync* (and for any identity-keyed feature), never to use the app. Local-only
  users boot, work, and see a clean console with no session — the locked private-per-user model.
- **Session storage = the Appwrite SDK's own store** for this wave. `flutter_secure_storage` is
  not in the repo; introducing a new native dependency hours before a device test is a worse
  risk than the SDK default. Executor verifies at implementation time where the SDK persists
  the session on iOS/web and records it here; if iOS lands outside the Keychain, schedule the
  hardening as a follow-up task — do not block the wave.
- **Web cookie posture, honestly:** the security contract says httpOnly session cookies on web.
  Against Appwrite Cloud on a third-party origin the web SDK may fall back to localStorage.
  Executor verifies against current docs; if httpOnly requires a custom domain, wire the
  fallback, record the deviation here, and queue the custom-domain fix — the private release
  does not widen before the posture is met.
- **Dual-write scope, honestly:** the Firestore half of 4.2 rides the legacy Firebase session,
  which exists on the owner's device but NOT on fresh installs signing in via Appwrite only.
  Fresh installs are Appwrite-primary with nothing to fall back to — acceptable: they also have
  no Firestore data to lose. The kill-switch story protects exactly the data that predates the
  wave.
- **Note entries join sync** (task 4.9): the actual notes feature is the multi-entry tables
  (`MoveNoteEntries`/`ComboNoteEntries`), absent from the contract until now (the `notes`
  column already rides in entity payloads). Appwrite-only — no Firestore legacy ⇒ no strangler
  ladder — with the same LWW + tombstone + `clientOpId` semantics and kill-switch pattern.
- **Overnight/morning proof split:** overnight owns everything provable headlessly — analyzer +
  tests, live data-plane via the smoke-user JWT pattern (1.5 precedent), web build + browser
  smoke, sim boot to the login screen. Morning (Phase M) owns what needs the owner: live Google
  consent, cross-restart session on the device, real-data backfill, two-surface soak, the
  console config flip. A checkbox whose residue is morning-only says so explicitly.

## Execution note — this spec is the master plan for a delegated executor

The owner runs low on interactive usage; an Opus-class executor implements from this change
directly. Executor contract: read `proposal.md` → this file → `tasks.md` top-to-bottom; prime
context from the files each task names before editing; **verify all Appwrite SDK/API shapes
against current official docs (Appwrite docs, pub.dev `appwrite`) at implementation time — never
from model memory**; obey the invariants in `proposal.md`; land tasks atomically in risk order;
red/green where a bug is being fixed; `flutter analyze` + `flutter test` (and `web-mirror` lint +
`vitest`) green at every boundary; stop and surface (never improvise) when an owner-gated step
(Phase 0 provisioning, real-data verification, store credentials) blocks progress.
