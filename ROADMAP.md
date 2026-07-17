# Breakdex — Roadmap & Backlog

> **The single roadmap.** (`docs/ROADMAP.MD` and `docs/PROGRESS.MD` were folded in here and
> removed, 2026-07-06.) Captures decisions, what already exists in the code, the remaining
> delta, and a recommended sequence toward launch.
> Last consolidated: 2026-07-06.

> ⚠️ **Backend decision updated (2026-07-05).** The "Firebase (Firestore)" rows in the
> LOCKED table and workstreams below are **superseded**. The canonical backend is now
> **Appwrite** (open-source, self-hostable; decided after grilling, reversal was free —
> nothing was deployed). The provider-agnostic `SyncBackend` contract, LWW clock,
> non-destructive backfill, and dual-read cutover all carry over. See the root `CLAUDE.md`
> and `openspec/changes/migrate-canonical-backend-to-appwrite`. Read anything below that
> says "Firestore" as "the canonical sync backend, now Appwrite."

---

## NOW — the single active task (queue head; every session starts here)

> Any session, human or agent: read this block, open the named change's `tasks.md`, do
> exactly the next unticked task, verify (binary truth), tick + update this block **in the
> same commit**. Nothing else starts until this block says so.

- **Change (active, owner-launched 2026-07-17):** `fix-video-backup-truth-and-unify-account`
  — the video-backup pipeline was structurally dishonest (verifier reported 67/67 "missing"
  on a relative-path bug; one deferred file aborted the whole upload sweep; a cycle drained
  only one `maxConcurrent` batch; "All synced" was an unemitted-stream default). **Phase 1
  (backup truth & throughput) DONE by agent 2026-07-17**, each fix red/green: 1.1 verifier
  resolves relative paths (`9d6625c`), 1.2 sweep skips deferred files + all-deferred still
  surfaces waitingForWifi (`5e7db70`), 1.3 queue drain loop (`4a57587`), 1.4 honest health
  derived from `watchUnderprotectedCount()` in Drift + real pending count in Video Backup
  subtitle and Sync Status header, localized (`3e7c2c5`), 1.5 dev diagnostics dump
  (`5fd1380`), 1.6 field-split reclassification note filed in `make-sync-total`'s §D6.
  Binary truth: `flutter analyze` 0 errors (9 pre-existing infos untouched), targeted
  suites + provider/sync/database dirs green (317+), `check_l10n.sh` green, 0 regressions.
  **Next unticked: 1.7 owner 30-second device proof** — rebuild, Sync Status header shows
  the real pending count (~66), one Sync Now on Wi-Fi, Drive shows the full library,
  Verify Integrity reports 67 OK (screenshot + Drive count in the tick). **Phase 2**
  (2.1 Drive-row account email, 2.2 web unavailable affordance) is agent-runnable next;
  **Phase 3** stays owner-gated on design O1/O2.

- **Change (owner-driven, parallel):** `add-dev-auth-and-sync-rehearsal` — de-risks the owner's Phase-M pass
  by letting a dev **user #0** rehearse the whole sync ladder without Google OAuth. **Agent
  wave DONE 2026-07-14** (owner greenlit; slots ahead of Phase M). Committed on `main`
  (UNPUSHED): proposal (`8da0253`) → **Phase 1** dev email/password auth seam (flag
  `DEV_EMAIL_AUTH`, OFF) → **Phase 2** runtime sync-cutover panel (flag `DEV_SYNC_PANEL`, OFF;
  the missing on-device switch-hand for `migrate-canonical-backend-to-appwrite` M.4) → **3.4**
  `docs/sync-rehearsal-runbook.md` (R1–R7 ledger + D7 fence). Binary truth: `flutter analyze`
  clean, `flutter test` green both flag configs, `flutter build web` green flags-OFF
  (byte-identical). **2026-07-14 owner-present wave:** 3.1/3.2 **DONE** — §A–§D all live
  (note tables + functions verified; web platforms `localhost` + `breakdex.vercel.app`
  registered via API, no console click); `dev0` minted (creds in `.env.local`) **plus** the
  owner account (`itsmxzou@gmail.com`, email-verified so Google OAuth later attaches to the
  SAME user — both auth doors, one account); spec gained **2.4** the panel's **Backfill now**
  takeover trigger (composed `fullBackfillServiceProvider`, per-entity row/batch report =
  M.3 parity evidence; backfill previously had NO runtime caller). **Remainder (owner-in-
  the-loop, next):** 3.3 `argent init` + smoke, **Phase 4** the live R1–R8 ladder on sim +
  web (owner drives; entry = `docs/sync-rehearsal-runbook.md`, prereqs banner says ready),
  then 4.9 ledger + the real **Phase M** pass (`docs/phase-m-runbook.md`) — the rehearsal
  raises its confidence but its M boxes stay the owner's. **2026-07-16: live Google OAuth
  PROVEN on the senik device** — two stacked faults fixed (SDK-25.x swallowed callback params
  → gateway rewritten to the token flow via `flutter_web_auth_2`; Appwrite Google provider had
  no client secret → pushed via console API). Server confirms the Google session + identity on
  the owner account; evidence in the Appwrite change's Phase-M note. **2026-07-16 (cont.):
  M.3 DONE + proven both layers** — owner's `Backfill now` seeded 139 rows into
  `itsmxzou@gmail.com`'s Appwrite space; a direct server `tablesdb …/rows` count == the
  phone's per-entity report exactly. **Inbound hydration built (unblocks M.6):**
  `Backfill now` was push-only and reads are local-Drift-only, so a fresh web client would
  show empty on sign-in → added `SyncService.hydrateAllFromBackend()` (inbound mirror,
  bypasses dual-read gates via the existing LWW core), fired **automatically on first login**
  + a dev **"Pull from backend now"** button. `flutter analyze` clean, `flutter test` 950
  green / 9 pre-existing reds / 0 regressions (+6 new), `flutter build web` green. **2026-07-17: M.6 DONE both halves** — agent-driven web proof
  (fresh Chrome profile, dev email door as owner: auto-hydrate 164 rows, library renders,
  session + data survive reload, re-hydrate no-ops) **plus the owner's live Google OAuth on
  web** (server sessions list shows `provider: google`, Chrome/Mac, expires 2027-07-17).
  D11 posture recorded in the M.6 tick: localStorage `cookieFallback` (cross-origin), httpOnly
  needs a custom API domain later. **Next unticked (owner-driven):** the **R1–R8 rehearsal
  ladder** (`docs/sync-rehearsal-runbook.md`, dev0 on sim + web) → then Phase-M remainder
  **M.4** cross-surface soak (phone must be signed in — its Google session was dropped when
  the owner dev password was set 2026-07-16; one re-sign-in) and **M.5** remote-config flip
  (provision the `appConfig/current` row). Push decision still the owner's (main ahead,
  unpushed).
  Prior queue head
  (`add-web-first-release-and-monetization`, launch wave L1–L6) is **DONE** — history below.

- **Change:** `add-web-first-release-and-monetization` — **🚀 Launch wave (owner ruling
  2026-07-13; launching today).** A fresh Opus 4.8 session executes it: read that `tasks.md`'s
  **"🚀 Launch wave — executor entrypoint"** preamble FIRST — it sets the order (L1 GUIDE.md →
  L2 versioning → L3 argent-driven web smoke → L4 Vercel deploy pipeline → L5 invites flag-OFF →
  L6 Lemon Squeezy payments seam) and records the four Phase-0 rulings (LS / 3-tier one-time
  $4.20–$6.99–$9.99 / `breakdex.vercel.app` / crew–beta–owner cohorts). Runs **parallel to the
  owner's Phase M device pass** (`docs/phase-m-runbook.md`, `migrate-canonical-backend-to-appwrite`) —
  neither blocks the other; nothing in the launch wave needs the soak, and nothing destructive
  (Appwrite 5.1/5.2, Phases 6–7) starts until the soak passes.
- **🚀 Launch wave (2026-07-13): L1–L6 ALL DONE — every agent-runnable item landed.** Commits on
  `main`, **PUSHED** to `origin/main` 2026-07-13 (owner-authorized, all 26 wave+launch commits,
  fast-forward `76840af..418c550`). Binary truth throughout: `flutter analyze` 0 errors,
  each Function `dart test` green, client `flutter test` green, `flutter build web` green, 0
  regressions. Summary:
  - **L1 (4.1 `GUIDE.md`)** — rider-facing guide at repo root.
  - **L2 (4.2 versioning)** — convention in GUIDE + **repaired rotted release pipeline** the verify
    surfaced (`@semantic-release/changelog` + `update_release_metadata.cjs` still pointed at
    root/deleted docs from the 2026-07-06 consolidation → would crash `semantic-release` on the next
    `feat`/`fix` push; now target the real `docs/` set; script dry-run exit 0).
  - **L3 (1.6 web smoke)** — `/breakdex`,`/add`,`/review` render clean in real Chrome, **0 console
    errors**; perf baseline FCP 772 ms / CLS 0.00 / main.dart.js 5.47 MB uncompressed. chrome-devtools
    MCP (sanctioned fallback); full canvas-tap click-through fenced to argent/Phase-M.
  - **L4 (4.3 Vercel pipeline)** — `deploy-web.yml` builds web + `vercel deploy --prod` to
    breakdex.vercel.app; `release.yml` auto-calls it on a published tag (sidesteps the GITHUB_TOKEN
    tag-trigger gotcha); `web/vercel.json` SPA + no-cache + **no COEP** (keeps Drive video + OAuth);
    rollback = dispatch on a prior tag / Vercel Instant Rollback; `docs/web-deploy.md` owner setup.
  - **L5 (Phase 2 invites, flag-OFF)** — `invites`/`entitlements` tables; `invites-redeem` Dart
    Function (idempotent per (user,code), typed rejections, 10/10); `EntitlementGate` pure gate +
    root `EntitlementGatePrompt` (`kEntitlementGateEnabled` **OFF** → inert, byte-identical builds);
    `userCohortProvider` binds cohort into `RemoteConfig.flag(cohort:)`; client tests 13/13.
  - **L6 (Phase 3 Lemon Squeezy payments)** — `payments-webhook` Dart Function (constant-time HMAC
    verify fail-closed, idempotent per LS order id, `order_created`→grant, `order_refunded`→revoke
    **status-only, never deletes data** = lockout not loss, 12/12); `checkout.dart` offerings
    ($4.20/$6.99/$9.99) + pure LS checkout-URL builder; entitlements schema gained `status`/`orderId`.
  - **Owner-gated remainder (NOT agent-runnable):** ~~the push decision~~ (✅ pushed 2026-07-13);
    **live provisioning** (targeted `tables-db create-*` for `invites`/`entitlements` + `push
    functions --activate` for `invites-redeem`/`payments-webhook` — NEVER `push tables --all`); the
    Vercel OAuth + 3 secrets (`docs/web-deploy.md`); the Lemon Squeezy account + variant ids + webhook
    secret; flipping `kEntitlementGateEnabled` on; `4.4` wave-1 mint+send; `4.5` soak; and the
    Appwrite Phase M device pass. **No agent-runnable launch task remains** — the wave is code-complete.
- **Prior change:** `migrate-canonical-backend-to-appwrite` — **⚡ Overnight wave (owner ruling
  2026-07-12), COMPLETE + maximally advanced pre-soak.** Its wave preamble + `design.md` D11
  remain the reference. `main` is the merged single source of truth; all wave commits **pushed**
  to `origin/main` 2026-07-13.
- **▶ NEXT SESSION ENTRYPOINT (`openspec apply migrate-canonical-backend-to-appwrite`):**
  **Phase M — the cross-surface "same data everywhere" proof.** Everything code-side is done,
  green, pushed, pref-OFF. What remains is the live half, run start-to-finish from
  `docs/phase-m-runbook.md` with the owner present: **(A)** CLI auth from `.env.local` (keys
  verified present 2026-07-13) → **(B)** provision `moveNoteEntries`/`comboNoteEntries` via
  targeted `create-*` (never `push tables --all`) → **(C)** `push functions --activate` →
  **(D)** console: register web origin(s) → **(E)** device pass **M.1–M.6** (build/boot → live
  iOS Google login → real-data backfill → **M.4 flip-the-prefs cross-surface soak** = phone edit
  seen on web + back, per-entity, notes+tombstones last → remote-config flip 1R.4 → web login) →
  tick M.1–M.6 + V.3 in the master `tasks.md`. Launch-side provisioning (invites/entitlements
  tables + `invites-redeem`/`payments-webhook` Functions + Vercel + Lemon Squeezy) can ride the
  same authenticated session — see the launch-wave block above.
- **Phase 5 advance (owner-directed 2026-07-13):** both unblocked Phase-5 tasks landed —
  `5.3` (Drive metadata safety-net export; code-complete + flag-OFF: tombstone-safe v10 codec +
  `MetadataBackupService`, gated `kMetadataDriveBackupEnabled` default OFF, commit `9e1748e`) and
  `5.4` (self-host runbook `docs/appwrite-selfhost.md`, commit `4b65df6`). **Phase 5 is now
  maximally advanced pre-soak.** Everything left in Phases 5–7 is hard-gated on the owner's
  Phase M device soak: `5.1`/`5.2` (destructive Firestore/Firebase removal) need "all entities
  green + soaked"; Phase 6 (web studio on new substrate) needs the Flutter cutover live; Phase 7
  is flagged "do not start before Phase 6 ships". Do not start any of them pre-soak.
- **Next task:** ✅ **Overnight wave COMPLETE** (2026-07-13). All items 1–7 landed on `main`
  (9 local commits `46abea0..` the V.1/V.2 commit, **not pushed** — owner-gated). `flutter analyze`
  0 errors; `flutter test` 916 green / 9 pre-existing reds / **0 regressions**; `flutter build web`
  green. See the master `tasks.md` **✅ Wave report — 2026-07-13** for the full proven-vs-Phase-M
  split. **Next is owner-in-the-loop: Phase M** (physical device, this morning) — M.1 build/install,
  M.2 live iOS Google login, M.3 real-data backfill, M.4 cross-surface soak (the flip-the-prefs
  proof), M.5 config flip, M.6 web login — plus the owner-gated live Appwrite provisioning
  (targeted `tables-db create-*` for the note-entry tables + `push functions --activate`; never
  `push tables --all`). ~~Push decision~~ ✅ done — everything is on `origin/main` (2026-07-13).
  **Done in the wave so far:** `0.5` → `0.2` → `3.3` → `3.4` → `4.1`–`4.3` (moves cutover template
  complete) → `4.4` (combos + combo_moves; 23/23) → `4.5` (reviews append-only; 18/18) → `4.6`
  (fsrs_cards pull-only server-derived; 13/13) → `4.7` (decks + deck_moves; 24/24) → `4.8`
  (tombstones end-to-end for all 5 delete-bearing entities, schema v26 `deleted_at`; 9/9) →
  **`4.9` (note entries become Appwrite-only synced entities: schema v27 `updated_at`+`deleted_at`
  on both note tables, `note_entry_codec`, `SyncEntityType.{move,combo}NoteEntry`, DAO
  dirty-tracking + soft-hide read-filters, dual-write/read + inbound-tombstone engines, backfill,
  config tables authored + Function allowlist→7 + tests; pref OFF until M.4. 24/24 new tests,
  Function tests 19/21 green, `test/core` 789 green 0 regressions; live provisioning + Function
  redeploy + two-device note soak ride M) → **web-first `1.4` (URL video seam: `networkVideoController`
  + `supportsUrlVideoPlayback` + `RobustVideoPlayer.videoUrl`; HTML `<video>` playback web-capable;
  Drive-URL resolver + web import + live playback ride M.4) + `1.5` (web Appwrite OAuth: success/failure
  redirect URLs on web via `Uri.base.origin`, httpOnly-cookie posture code-clean, SyncBackend transport
  already web-safe; live web login rides M.6) — cross-change, both ledgers ticked; auth 15/15 + video 7/7
  green, 0 regressions.**
  Remaining wave order: `V.1`/`V.2` sweep + wave report. **Phase M (morning 2026-07-13,
  owner on the physical device)** holds every owner-in-the-loop proof: live Google login (M.2),
  real-data backfill (M.3), two-surface soak (M.4), config flip 1R.4 (M.5), web login (M.6).
- **Owner-gated residue (parked, does not block the wave):** 0.4's Convex console delete; final
  brand art (`harden-code-ownership-and-config-purge`); web-first Phase 0 rulings
  (payments/domain/invites).
- **⚠ Ops hazard (learned 1R.1):** do **NOT** run `appwrite push tables --all` against the live
  `breakdex` project. This CLI (22.6.1) diffs omitted-`array` (config) vs `array:false` (deployed)
  as a change and **recreates existing columns** — it deleted all of `moves`'s attributes mid-run
  and left dangling `stuck` indexes (unrepairable via `delete-index`; only a table drop+recreate
  cleared them). `moves` was rebuilt from config (0-row, pre-cutover → no data loss) and all 10
  tables re-verified green. Provision NEW tables via **targeted** `tables-db create-*-column` /
  `create-index` calls (auth: `set -a; source .env.local` → export `APPWRITE_ENDPOINT/PROJECT_ID/
  KEY` — the CLI prefs `current` points at throwaway `6a51…` projects, not `breakdex 6a50f25b…`).
- **State pointer:** per-phase progress notes live in the ledgers (each change's `tasks.md`
  task notes), not here — this block stays a pointer. Shipped so far: master phases H, 0 (minus
  the 0.2-verify + 0.4 console click), 1, 1R (minus 1R.4), 2 complete; 3.1/3.2 built seam-only
  and unwired; web-first 1.0–1.3 done + the CI web-build half of 1.6.

## Backlog — OpenSpec change order (D8, canonical)

Priority order for pending OpenSpec changes, top first. This is the authoritative sequencing
(align-cross-client-foundations D8); the risk-ordered workstream narrative further down is the
older intra-app view and is kept for context.

1. **`migrate-canonical-backend-to-appwrite`** — the backend spine. Phase H done
   (`phase-h-hardening`); **Phase 0 provisioning is NEXT and owner-gated** (Appwrite Cloud
   project + Google OAuth; owner confirmed ready 2026-07-08). Now also carries **Phase 1R
   remote config** (flags, kill-switches, min-version gate, cohort profiles) and the flagged
   Shorebird code-push evaluation (7.4).
2. **`add-web-first-release-and-monetization`** — ⭐ NEW (2026-07-08 grilling): web-first
   private release of the product itself. Flutter Web bring-up (Phase 1, startable NOW),
   invite codes + entitlements + $4.20–$9.99 offerings (gated on Appwrite Phases 0–3/1R),
   GUIDE.md + release hygiene, then iOS TestFlight → App Store → Android after the web soak.
3. **`add-web-authoring-and-lifecycle-studio`** — web = trustworthy system-of-record +
   authoring studio; targeted by Appwrite Phase 6. **Supersedes
   `evolve-web-mirror-to-crud-platform` (owner ruling 2026-07-08; archived):** absorbed its
   unshipped write scope as Phases 4–6 plus the `web-library-crud` + `media-governance`
   deltas. Now also carries **Phase 7 MDX developer docs** (seam docs + runbooks live with
   the studio, build in CI).
4. **`redesign-visual-first-experience`** — ⭐ NEW (2026-07-08 product-finish): visual
   anchors over text (Add flow de-text, media-grid membership + 4-slot tiles), 3 view modes
   (Glance → Scan → Study), review WYSIWYG (one screen, `xxs` radius, customizable fill),
   Fluid/Morph motion doctrine. **Release-blocking for wave-1 invites**; no backend
   dependency — parallel with Appwrite phases.
5. **`harden-marathon-reliability`** — ⭐ NEW (2026-07-08): 8-hour soak bar, startup budgets
   (≤2.5s mobile / ≤5s web), **device-diagnostics status page** (deterministic per-device
   checks + redacted JSON export), 3-platform E2E matrix (Patrol/Maestro/Playwright) — the
   matrix IS the wave-1 invite gate. Phases 1–3 independent; startable now.
6. **`add-personalization-and-accessibility`** — NEW (2026-07-08): parametric naming of the
   Moves/Combos data-banks, add-flow order preference (edit-while-adding), party default ON
   (fresh installs only; stored prefs untouched), settings IA + live self-confirming
   customization, color-blind + monochrome themes, i18n foundation (gen-l10n + ARB).
7. **`add-capture-and-pro-metadata`** — NEW (2026-07-08): Record entry (system camera path
   already in `video_service.dart`), fps/resolution/codec probe + additive migration,
   bytes/names-preserved invariant + NLE JSON sidecar (DaVinci/Blackmagic interop),
   open-with-Breakdex (iOS/Android/web), deck/set annotations.
8. **`align-cross-client-foundations`** — this change (gap-filler: multi-user sync model,
   security posture, tokens, notes dirty-guard, web state machines, ledger hygiene). Wave 1
   lands now with no Appwrite dependency; Waves 2–3 ride Appwrite Phases 4/6.
9. **`harden-code-ownership-and-config-purge`** — NEW (2026-07-08): per-directory purge +
   justify sweep (zero behavior change, pure deletions, git history = undo). Rolling: a
   directory sweeps only after its migration lands; gate before invites go broad.
10. Nearly-done finishing passes: `foundation-data-resilience` (59/64),
    `tighten-combo-journey-and-review-polish` (33/36), `repo-organization-and-readme-refresh`
    (12/15), `add-historical-photos-bootstrap` (7/9), `add-web-mirror-player` (19/26).
11. **`state-machine-crud`** — kept open as the tracker for genuinely unshipped residual work
    (TrashMachine, MoveListMachine, AppMachine, notes/log overlays); the `Machine<S,E>`
    framework + move-detail vertical already shipped (see its `tasks.md` Residual header).
12. Everything else parked (labs, provenance/beam ingestion, research workbench, photo
    archive recovery, etc.).

**Recently reconciled (2026-07-06 ledger audit):** archived `add-convex-sync-backend`
(superseded by Appwrite), `add-discovery-graph-interface` (26/26 shipped), and
`add-silent-video-mode-and-accessible-drill-launcher` (duplicate of the 2026-06-16
silent-playback change). `add-quiet-playback-and-senior-drill-ui` re-scoped to its unshipped
settings-dedup Phase 4 only.

---

## Product steering (folded from docs/ROADMAP.MD + docs/PROGRESS.MD, 2026-07-06)

Product-lane view — what to stabilize now, what expands the practice loop next, what is
deferred. (Backend-sync lanes now mean **Appwrite**, per the banner above.)

| Horizon | Lane | Goal | Status |
| --- | --- | --- | --- |
| Now | Review-loop clarity | Calmer, more controllable, more trustworthy sessions. | Active |
| Now | Progress ergonomics | Parent-first navigation + immediate graph entry; less random analytics. | Active |
| Now | Flow truthfulness | Honest move-first graph before richer entities. | Active |
| Now | Native media reliability | Keep import/album/export stable on iOS. | Active |
| Next | Combo & set graphing | Graph beyond move-only nodes without overstating what is live. | Planned |
| Next | Planning surfaces | Make Lab / sprint tools genuinely useful prep boards. | Planned |
| Next | Stronger analytics | Calendar, heat-map, retention around real coaching decisions. | Planned |
| Next | Sync hardening | Tighten migration, conflict, cloud consistency (Appwrite). | Planned |
| Later | Cross-platform parity | Keep iOS quality while validating broader device support. | Deferred |
| Later | Research feedback loop | Feed scientific-workbench findings back into scheduling. | Ongoing |
| Later | Coach & team workflows | Shared practice intelligence after the solo loop is stable. | Deferred |

**Current product shape:** Arsenal (moves/combos/source video), Review (FSRS spaced
repetition), Flow (move-transition graph + set building), Stats (review history → progress
signals), Settings (theme/color/sync/export). Active WIP: Progress (parent-first + secondary
superfan analytics), Lab (marked unfinished in nav), Flow (honest move-first graph), Review
(instrument-panel controls, color-state customization, quieter playback tightening).

**Release snapshot:** `v1.3.0` (`1.3.0+5`), released 2026-04-28. Release/provenance metadata
is generated by `scripts/update_release_metadata.cjs`.

---

## North Star (the thesis)

**Breakdex is a thin shell + a logic kernel over data the user owns.** The footage and
the practice graph live in environments the user already trusts (their device + their
cloud), reachable anywhere — not locked inside the app. This is **local-first + BYO-cloud**
(the "your data is just files in your Drive" philosophy, applied to breaking).

- The **video (move) is the primitive.** Combos, journals, plans, FSRS all compose around it.
- The app is a **lens/editor**, not the vault.

### The product spine — the practice loop (the differentiator)

Review + journal + todo are **one loop**, not three features. The `ReviewCard`
(`flashcard_review/widgets/review_card.dart`) already fuses **watch → state → rate**;
the loop closes when reflection feeds the next session:

```
FSRS surfaces an item → ReviewCard (video) → RATE (again/hard/good/easy → reschedule)
                                            → STATE (idea→attempting→landed→clean; auto-logs kind='status')
                                            → JOT  (free reflection)            ← MISSING UI
                                            → PLAN (jot/state → ComboPlans date) → calendar → back to top
```

**Verified state of the parts:** rating (`rating_button_row`), state pill
(`state_picker_sheet`, `InstrumentPanel`), and the immutable status timeline
(`CombosDao.updateStatus` → `kind='status'`) all exist. **Only the inline jot capture is
missing** — `ComboNoteEntries(kind:'jot')` table + DAO exist, but `insertJot` has **zero
callers in any feature**. This is the cheapest, highest-leverage weave in the whole app.

---

## ⚠️ Brownfield reality — governing constraints

**This is a late-stage production app with real users and real data.** Risk discipline
overrides architectural purity. Every item below is filtered through these:

- **Additive over invasive.** New capability via new code paths; don't rewrite working ones.
- **Never delete or orphan user state.** Videos, the graph, Drive blobs — all sacred.
- **Migrations are one-way and tested.** Schema is at v22; any change = forward migration,
  proven on a copy of real data, never destructive.
- **Drive renaming is lazy + backward-compatible.** Write new (semantic) names going forward;
  resolve *both* old hash-names and new names; never bulk-move existing blobs blindly.
- **Risky changes ship behind feature flags + staged rollout**, reversible.
- **Don't refactor a working critical path without a test around it first** — especially the
  settings "delete all data" path and the sync engine.
- **Verify on a real build before claiming done.**

> Consequence: the "clean the kernel" refactor is **opportunistic + test-guarded**, not a
> prerequisite sweep. Reorder the sequence by **risk**, not just value (see below).

---

## Architecture decisions — LOCKED

| Decision | Choice | Notes |
|---|---|---|
| Cross-platform | **Flutter, one codebase** | Web is a build target, not a second app. No Turborepo (JS-only). Melos only if we split Dart packages later. |
| Source of truth | **Local sandbox** (SQLite + canonical folder) | Opens the proper move, works offline. |
| Video bytes | **Google Drive** | Human-named, browsable, user-owned; the web viewer reads from here. |
| Graph (moves/combos/FSRS/notes) | **Firebase (Firestore)** | Small relational state; syncs across devices (Android+iOS super-user); backs web login. |
| "Double-backed up" | **Split by type, not duplicate** | Videos = local + Drive. Graph = local + Firestore (+ JSON manifest mirrored to Drive). NOT every video copied into Firebase (cost). |
| Web layer | **Thin, login, view-only** | No recording on web — major simplification. |
| Conflict model | **Last-writer-wins + version log** | **No CRDT** — single user, ~one device at a time. Revisit only if real multi-device conflicts appear. |
| Scale | **Not a current problem** | Backend is the user's Drive/Firebase; Google handles scale. Ship to user #1 first. |
| Security baseline | **Keychain tokens + `drive.file` scope + no repo secrets** | `drive.file` already in use (app sees only its own files). Don't invent crypto. |

---

## Workstreams

### 1. Storage & Sync  — *partially built*
- **EXISTS:** `gdrive_provider.dart` (OAuth, upload/download/verify, `Breakdex/<hash>.mp4`),
  `canonical_folder_service.dart` (`.breakdex-master/`, ledger, relative paths),
  `video_path_resolver.dart` (relative DB paths + **semantic paths** `Moves/{Cat}/{Name} - {Hash}.ext`, path healing),
  `asset_sync_engine.dart` (2-copy minimum), `cloud_provider.dart` (provider interface),
  `library_manifest.dart` (whole-library JSON export).
- **DELTA:** Drive is currently a *replica*, not the user-facing library. Videos are
  **hash-named** in Drive (`a3f9.mp4`) — not browsable. Firebase provider is a stub.
  `MediaDeliveryProvider` (signed URLs) unimplemented.
- **TO DO:** use semantic naming **in Drive** so the folder is a real library; finish
  Firestore graph sync; mirror the JSON manifest to Drive.

### 2. Data ownership & deep-link ("open the literal video")  — *~80% built, just disconnected*
- **EXISTS:** iOS registers as viewer for `public.movie`/`public.video` (`Info.plist:11`);
  `AppDelegate.swift` `FileOpenPlugin` buffers the opened file URL;
  `deep_link_resolver.dart` has 3-tier matching (filename → size → combo notes) → returns move/combo route.
- **DELTA:** the **Swift→Dart bridge is unwired** — `deep_link_resolver` has no caller.
  (This is the "zombie" the quality scan flagged: not dead, *disconnected*.)
- **TO DO:** wire the channel → resolver → router. Opening a video lands on **that move**, not home.

### 3. Thin web viewer  — *not started*
- **EXISTS:** nothing web (no `web/` dir; 33 `dart:io` imports in `lib/core`).
- **DELTA:** view-only viewer = login (Firebase Auth) + list Drive folder + play + show notes.
- **TO DO:** cheap **once #1 (readable Drive) + #6 (clean kernel) are done.** Build last.

### 4. Combos UX  — *~80% built; needs reshaping*
- **EXISTS:** `combos_screen.dart` — one screen, 3-segment toggle **Library / Planned / Calendar**.
  Calendar = month grid with activity heat + future plan-dots + day-detail. Planner flow
  (`plan_combo_flow.dart`) writes `ComboPlans(planDate)`. Status: idea/attempting/landed/clean.
- **DELTA:** Calendar **first** (currently last); fold **Planned into Calendar**
  (2 modes, not 3 — the calendar *is* the planning timeline); add **week/day zoom**;
  unify CTA to **View / Plan**. No status filtering today.
- **OPEN Q:** 2 modes (fold Planned in) vs keep a separate flat "upcoming" list. *(lean: fold in)*

### 4b. Combo planning — audited logical errors (2026-06-16)
- **GOOD:** the historical disposed-`ref` silent-plan-drop bug is **genuinely fixed** —
  `plan_combo_flow.dart:25-65` moved the write onto a live caller `ref`, every async gap guarded.
- **P1 — silent jot/completion-stamp failure: ✅ FIXED.** `jot_composer.dart` `_send`/`_attachVideo`
  catch blocks now surface a `mounted`-guarded SnackBar ("Couldn't save your jot." / "Couldn't link the
  video.") instead of swallowing the error. Pure additive.
- **P1 — TZ/DST mis-stamp: ✅ FIXED (read-path only, no migration).** `combo_plans_dao.stampCompletionsFromEvidence`
  now anchors `plan_date` at local **noon** (`date(plan_date,'unixepoch','localtime','+12 hours')`) before
  comparing days, so any device-offset change under 12h can't flip the plan's day. Chose this over the
  `'yyyy-MM-dd'` write-format change to avoid a migration on deployed data; fixes existing and new rows alike.
- **P1 — `deleteCombo` orphan leak: ✅ FIXED (non-destructive).** `deleteCombo` now also clears the
  structural `combo_moves` (joins the comboPlans precedent — meaningless once the combo is gone), but
  **deliberately keeps user-authored `combo_note_entries`**. The "Practiced" strip (`watchProgressStrip`)
  and calendar heat (`watchActivityRollup`) are now **scoped via `EXISTS (... combos ...)`** so orphaned
  jots stop inflating stats without anything being deleted. Honours the never-delete-user-state rule.
- **Coverage:** `test/core/database/combo_journey_dao_test.dart` adds orphan-scoping + jot-preservation cases.
- **P2s:** cross-day reorder bounce-back; non-transactional combo create (partial moves); same combo
  plannable twice for one day; calendar counts completed plans as "planned". (See audit for file:line.)

### 5. Loading reliability  — *WIP*
- **EXISTS:** `stall_detector.dart` (uncommitted), boot/transfer progress (commit `757d909`).
- **PROBLEM:** loading gets stuck in a stage, no 0→100 — likely **video access coupled to a
  cloud/boot stage that can hang**.
- **TO DO:** (a) **local video access never blocks** on any sync/cloud stage; (b) optimistic
  paint from cached DB; (c) incremental render from Drift `watch*` streams; (d) per-stage
  watchdog via `stall_detector` → **degrade, don't freeze**; determinate aggregate progress.
- **OPEN Q:** where does it stick — cold boot / opening a video / during sync?

### 6. Headless kernel cleanup  — *the prerequisite*
- **PROBLEM (P0 from scan):** views touch the DB / filesystem directly —
  `settings_screen.dart:542` raw `db.delete`, `battle_providers.dart:184` raw `insert`,
  `metadata_video_picker_sheet.dart:160-202` raw file I/O. 13 widgets import `dart:io`.
- **TO DO:** push these through services/repos. This **is** your "function kernel vs view
  rendering" split, and it's the gate for any web layer.
- **ZOMBIES to delete:** `S3Provider` (6 TODO stubs, never instantiated), `DeleteStateMachine` (never constructed).

### 7. Journaling = the practice-loop weave  — *seed exists, the spine is one gesture away*
- **EXISTS:** `ComboNoteEntries` (kind: jot/status/plan/duplicate, optional `videoPath`),
  `MoveNoteEntries`, `ComboPlans`. Status changes already log immutable `kind='status'` entries
  (a state timeline). Review card already does watch → state → rate.
- **THE WEAVE (highest leverage, additive, ~1 day):** add a **jot affordance to
  `InstrumentPanel`** → quick-capture sheet writes `ComboNoteEntries(kind:'jot', comboId,
  videoPath, body)`. `insertJot` currently has **zero callers in any feature** — wiring it
  closes the practice loop. Fast-follow: jot → "plan it" → `ComboPlans(planDate)` → calendar.
- **DEFER:** revision history; "notes-as-files (Obsidian)" vs "notes-in-DB".
- **OPEN Q:** notes browsable as files in Drive, or DB-only with Markdown export later? *(lean: DB now, export later)*

---

## Recommended sequence — ordered by RISK (brownfield)

Lowest-risk / highest-live-value first. Risk tag = blast radius on existing users' data.

```
Phase 1  Never-stuck loading     → decouple video access from cloud; wire watchdog  (#5)  [ADDITIVE · live bug]
Phase 2  Open the literal video  → wire deep-link bridge (already ~80% built)       (#2)  [ADDITIVE · new path]
Phase 3  Combos: calendar-first  → fold Planned in, week/day zoom, unified CTA      (#4)  [UI-ONLY · safe]
─── feature-flagged from here; migration-sensitive ───
Phase 4  Own your footage        → semantic Drive names, lazy + back-compat         (#1)  [MIGRATION-RISK]
Phase 5  Multi-device + web      → Firestore graph sync → thin view-only viewer     (#1,#3)[NEW INFRA · staged]
opportunistic  Kernel cleanup    → fix P0 leaks only when already in the file,      (#6)  [TEST-GUARDED]
               + delete true zombies (S3Provider, DeleteStateMachine)                     [safe deletes]
```

**Defer (write down, don't build):** CRDT, "massive scale", journal revision history,
notes-as-files, Drive-as-canonical inversion, big-bang kernel refactor.

**Brownfield guardrails per phase:** P1 touches no data (pure decoupling + watchdog).
P2 adds a path, changes none. P3 is UI-layer only. P4 must resolve *both* old hash-names
and new semantic names + never delete Drive blobs. P5 is a new backup channel behind a flag.

---

## Open questions still to resolve (the parked grill)

- **Storage Q2 — Auth:** what identity backs the web login + multi-device? (Firebase Auth w/ Google sign-in is the natural fit — already have GIDClientID config.)
- **Storage Q3 — Sync mechanics:** what exactly syncs, and how do the super-user's two devices reconcile? (last-writer-wins + version log)
- **Storage Q4 — Web shape:** Flutter-web build vs a genuinely separate thin web app reading Firestore+Drive directly.
- **Storage Q5 — Deep-link details:** custom `breakdex://` scheme + share-intent, or file-open only.
- **Combos:** 2 modes vs 3.
- **Loading:** which stage stalls.
- **Journaling:** notes-as-files vs DB-only.
