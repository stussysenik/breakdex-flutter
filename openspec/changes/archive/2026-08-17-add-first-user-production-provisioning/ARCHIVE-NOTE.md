# Archive note — 2026-08-17 · `add-first-user-production-provisioning`

Archived **implementation-complete**: 14/15 tasks ticked (Phases 1–4), `openspec
validate --strict` clean, gate green at the last task (analyzer 0 errors / 0 warnings,
14/14 tests pass). Phase 5 (tasks 5.1–5.4) moved to `owner-verification-passes` §7 —
it requires a physical device and live Appwrite credentials, which an agent structurally
cannot close. No task was dropped, deferred beyond the move, or reassigned.

## What it locked

- **SyncService production activation API.** `setDualWriteAll(bool)` / `setDualReadAll(bool)`
  write the per-entity dual-write/dual-read pref keys (moves, combos, reviews, decks,
  noteEntries — fsrsCards skipped on write as derived; included on read). `activateSync()`
  composes all eight `SyncBackfillService` calls (`backfillMoves`, `backfillCombos`,
  `backfillComboMoves`, `backfillReviews`, `backfillDecks`, `backfillDeckMoves`,
  `backfillMoveNoteEntries`, `backfillComboNoteEntries`) via `fullBackfillServiceProvider`;
  on full success flips both batch flags ON; on any throw changes no prefs and propagates.
- **First-login provisioning trigger.** `firstLoginProvisioningTrigger` provider mirrors
  the proven `hydrateOnLoginTriggerProvider` pattern: watches `currentAppwriteUserProvider`,
  defers via microtask, guards on per-user one-shot pref `sync.provisioned.$userId`.
  On eligible first login calls `syncService.activateSync()`, then sets the flag. On throw:
  logs + swallows, leaves flag unset (retry next launch). Watched at the shell root
  (`bottom_nav_shell.dart`) alongside the existing trigger watches.
- **Owner-provisioned offering config.** `OfferingsConfig.resolve()` reads
  `--dart-define=OFFERINGS_JSON`; malformed input degrades to absent, never throws. Purchase
  UI gated by resolved tiers — absent tier hides/disables its paid control, no checkout
  can start. No hardcoded ids.
- **Safe-default posture (no remote-config dependency).** Spec rewritten to drop the
  remote-config dependency (Phase M.5 not proven live) — trigger is guarded only by the
  per-user one-shot pref, so no session → byte-identical behavior. Required named bool
  params on the batch setters satisfy `avoid_positional_boolean_parameters`.

## NOT PROVEN at archive — owner-gated, not lost

All five Phase 5 tasks are structurally agent-impossible — they need a physical device,
a live Appwrite session, and a second surface. Moved to `owner-verification-passes` §7:

- 7.1 Google-sign-in on the phone (canonical identity).
- 7.2 Provision (auto on first login) → verify per-entity row counts match local library
  via server-side `curl` / `get_app_logs`.
- 7.3 Second surface (web / other device) signs in same identity → same data appears.
- 7.4 CRUD on either surface propagates within a pull cycle (argent acceptance).

## Standing suspect

None. The 14-test suite covers one-shot/retry/no-op trigger behavior, activateSync
compose+prefs+throw, and offering parser+gating. Device proof is the only gap, and it is
addressed to the owner.
