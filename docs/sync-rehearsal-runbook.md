# Sync-rehearsal runbook — dev user #0 cross-surface ladder

Results ledger for `add-dev-auth-and-sync-rehearsal` (Phase 4). A dedicated dev account
(**user #0**, `dev0`) rehearses the Phase-M sync ladder on two live surfaces — iOS simulator +
web — against the **live** `breakdex` project, blast radius `userId == dev0` only (design D3).
This proves the sync *architecture* (backfill parity, per-entity cutovers, LWW, tombstones,
notes) without the owner's Google account or the OAuth device dance. It is **not** Phase M —
the fence table at the bottom records exactly what it does not prove.

Status legend per rung: **PENDING** (not yet run) · **PASS** · **FAIL** (halt the ladder).
Each rung fills in on its live run and ticks its `tasks.md` box in the same commit (ledger
rule). Nothing here has been run live yet — every rung is PENDING.

---

## Prerequisites (owner-gated — from `docs/phase-m-runbook.md`)

Run **§A–§D of the phase-m-runbook with the owner present** before the ladder. They are
non-destructive infra; never improvise them (and **never `push tables --all`** — targeted
`create-*` only):

- **§A** — CLI auth from `.env.local` (project `6a50f25b…`; `health get` must show `breakdex`).
- **§B** — provision `moveNoteEntries` / `comboNoteEntries` (needed only for **R7**; every
  other rung runs without it). If deferred, note it and skip-with-note R7.
- **§C** — `push functions --activate`.
- **§D** — register `http://localhost:<port>` as a web platform in the console (the web half's
  CORS + session cookie).
- **Mint user #0** — `appwrite users create --user-id dev0 --email <dev addr> --password "$DEV0_PASSWORD"`
  (`DEV0_PASSWORD` lives in `.env.local`, never committed — design D1). Verify with
  `appwrite users get --user-id dev0`.

## Build config (both surfaces)

Both dev flags ON, everything else default:

```bash
# iOS simulator (flowdeck manages the sim):
flutter run --dart-define=DEV_EMAIL_AUTH=true --dart-define=DEV_SYNC_PANEL=true

# Web (serve a locally built bundle from the §D-registered origin/port):
flutter build web --dart-define=DEV_EMAIL_AUTH=true --dart-define=DEV_SYNC_PANEL=true
```

Sign in on each surface with the user #0 email/password (the dev form under the Google button).
Flip cutover prefs from **Settings → Backup & data → Sync cutover (dev)**.

## Driver

Smoke driver is **argent** (`@swmansion/argent`, ruled 2026-07-13). `argent init` config is
committed (task 3.3). If argent cannot drive a rung (e.g. canvas-tree flakiness), the
sanctioned **chrome-devtools** fallback applies on web — the rung's evidence names which driver
ran (binary truth includes naming the instrument, design D6).

---

## The R1–R7 ladder

Flip order **within each entity rung** (per phase-m-runbook): verify OFF (baseline, local-only)
→ flip dual-**write** → soak → flip dual-**read** → soak → cross-surface both directions. Any
loss/duplication ⇒ flip that entity's pref back OFF, record FAIL, **halt the ladder**, surface.

| Rung | Scenario | Surfaces | Driver | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| **R1** | Isolated origin — user #0 signs in, sees an empty space; no row outside `userId == dev0` touched (server-key spot-check after R6) | sim + web | — | — | PENDING |
| **R2** | Backfill parity — seed a handful of moves/combos/reviews/decks on the sim via the real UI, run backfill, per-entity backend row counts == local | sim → backend | — | — | PENDING |
| **R3** | Moves cutover — full flip order on `moves`; edit on web → appears on sim; edit on sim → appears on web | sim ↔ web | — | — | PENDING |
| **R4** | Combos, reviews, decks — repeat R3 per entity, one at a time | sim ↔ web | — | — | PENDING |
| **R5** | LWW conflict — edit the same move on both surfaces in quick succession; later `updatedAt` wins on both; no duplicate rows; loser's edit cleanly gone | sim ↔ web | — | — | PENDING |
| **R6** | Tombstone — delete a move on one surface; it disappears on the other and does **not** resurrect after relaunch + re-sync on either | sim ↔ web | — | — | PENDING |
| **R7** | Notes (requires §B) — note-entry created on sim crosses to web and back; tombstoned note stays gone. Skip-with-note if §B deferred | sim ↔ web | — | — | PENDING |

Per-rung detail (fill on the live run — driver used, exact taps/edits, observed row IDs and
`updatedAt` values, screenshots or server-key `list-rows` output):

- **R1** — _pending_
- **R2** — _pending_
- **R3** — _pending_
- **R4** — _pending_
- **R5** — _pending_
- **R6** — _pending_
- **R7** — _pending_

---

## Fence — what this rehearsal does NOT prove (design D7)

A green ladder above is **not** a green Phase M. The rehearsal is architecture-only against an
isolated dev user; the following stay owner-run and unproven here, and a green rehearsal must
never be read as "Phase M passed":

| Proven by rehearsal (user #0) | Stays Phase M (owner) |
| --- | --- |
| Session persistence across relaunch (mechanism) | Google OAuth callback scheme on iOS (M.2) |
| Backfill row-count parity (M.3 mechanism) | Real-data backfill of the owner library (M.3) |
| Per-entity dual-write→dual-read flips, both directions (M.4 core) | Drive video pointer → playback on web (M.4 video half) |
| LWW conflict, tombstone no-resurrect, notes cross | Legacy-identity claim via Google email (3.4) |
| Web email/password session from registered origin | Remote-config flip on owner cohort (M.5); web OAuth + httpOnly cookie (M.6) |

The remaining live gate after a green rehearsal is **Phase M** in
`migrate-canonical-backend-to-appwrite` (`docs/phase-m-runbook.md`), owner-run on a real device
with a real Google account.
