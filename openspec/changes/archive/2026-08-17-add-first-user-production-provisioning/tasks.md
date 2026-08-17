# Tasks — first-user production provisioning & sync activation

> **Ledger audited 2026-08-17: 0/15 was accurate — nothing has shipped.** Greps for
> `setDualWriteAll`, `activateSync`, `firstLoginProvisioningTrigger`, and
> `sync.provisioned` return zero hits in `lib/`+`test/`. This rewrite drops the
> remote-config dependency (Phase M.5 not proven live) and follows the proven
> `hydrateOnLoginTriggerProvider` pattern instead. The trigger fires on first
> Appwrite login, guarded only by a per-user one-shot pref.

**Dependencies:** Phase 1 (SyncService API) and Phase 2 (trigger) are independent; Phase
3 (offering config) is independent; Phase 4 (tests) consumes 1–3.

**Verification = tests + grep + runtime MCP** (no agent-driven UI). Ledger rule: tick in
the same commit that lands the work. Binary truth: no tick without `flutter test` /
`flutter analyze` output.

**Code shapes the executor MUST match (read these first):**
- `lib/core/services/hydrate_on_login_providers.dart` — the trigger pattern to copy
  (watch `currentAppwriteUserProvider`, defer via `Future.microtask`, `unawaited`,
  swallow throws).
- `lib/shared/widgets/bottom_nav_shell.dart:71-78` — where triggers are watched at the
  shell root (alongside `legacyIdentityClaimTriggerProvider` and `hydrateOnLoginTriggerProvider`).
- `lib/core/services/sync_service.dart:57-137` — the per-entity dual-write/dual-read
  pref key constants (`movesDualWritePrefKey`, etc.) that the batch setters write.
- `lib/core/sync/backfill/sync_backfill_service.dart:61-174` — the eight `backfill*()`
  methods `activateSync()` composes.
- `lib/core/providers.dart:473` — `fullBackfillServiceProvider` (provides a
  `SyncBackfillService` with all DAOs).

## Phase 1 — SyncService production activation API
- [x] 1.1 Add `setDualWriteAll(bool)` / `setDualReadAll(bool)` to `SyncService`: write the
      per-entity pref keys (write: moves, combos, reviews, decks, noteEntries — skip
      fsrsCards, it's derived; read: moves, combos, reviews, fsrsCards, decks, noteEntries).
      `SharedPreferences.setBool` per key; no other behavior.
- [x] 1.2 Add `activateSync()` to `SyncService`: compose the eight `SyncBackfillService`
      calls (`backfillMoves`, `backfillCombos`, `backfillComboMoves`, `backfillReviews`,
      `backfillDecks`, `backfillDeckMoves`, `backfillMoveNoteEntries`,
      `backfillComboNoteEntries`) via `fullBackfillServiceProvider`; on full success call
      `setDualWriteAll(true)` then `setDualReadAll(true)`; on any throw, change no prefs
      and let it propagate. Return the list of `BackfillReport`.

## Phase 2 — First-login provisioning trigger
- [x] 2.1 New `firstLoginProvisioningTrigger` provider (file
      `lib/core/services/sync_activation_providers.dart`), mirroring
      `hydrateOnLoginTriggerProvider` exactly: watch `currentAppwriteUserProvider`, defer
      via microtask, guard on a per-user one-shot pref `sync.provisioned.$userId`
      (persisted in SharedPreferences, survives restart). On eligible first login call
      `syncService.activateSync()` then set the one-shot flag. On throw: log + swallow,
      leave flag unset (retry next launch). No behavior change when no session.
- [x] 2.2 Watch the trigger at the shell root (`bottom_nav_shell.dart`, alongside the
      existing `legacyIdentityClaimTriggerProvider` / `hydrateOnLoginTriggerProvider` watches).

## Phase 3 — Owner-provisioned offering config (independent)
- [x] 3.1 Add `lib/core/config/offerings_config.dart`: `OfferingsConfig` (per-tier id +
      variant), `OfferingsConfig.resolve()` reading `--dart-define=OFFERINGS_JSON`. Malformed
      input degrades to absent, never throws. No hardcoded ids.
- [x] 3.2 Wire the existing purchase UI to `OfferingsConfig.resolve()`; when a tier is
      absent, that tier's paid control is hidden/disabled and no checkout can start.

## Phase 4 — Tests (the proof)
- [x] 4.1 Trigger: first login (no flag) → calls `activateSync` once, sets one-shot;
      second build → no-op. No session → no-op. Throw → one-shot stays unset, logged.
- [x] 4.2 `activateSync`: composes all 8 backfill calls; success flips every pref ON;
      backfill throw → no pref changed. `setDualWriteAll`/`setDualReadAll` flip exactly the
      expected key sets.
- [x] 4.3 One-shot flag persists across restart (mock SharedPreferences re-instantiated);
      distinct userIds are independent.
- [x] 4.4 Offering config: present resolves the id; absent disables; malformed degrades.
      `flutter analyze` 0 errors; `flutter test` green.

## Phase 5 — Owner-driven device proof → MOVED to `owner-verification-passes` §7

> Moved 2026-08-17 (NOT completed here): these tasks require a physical device and live
> Appwrite credentials. The parent change is implementation-complete; only proof is
> outstanding. See `ARCHIVE-NOTE.md` and
> `openspec/changes/owner-verification-passes/tasks.md` §7. Boxes stay unticked — the
> work lives in the destination change now, where only the owner may tick it.

- [ ] 5.1 Google-sign-in on the phone (canonical identity) → `owner-verification-passes` 7.1
- [ ] 5.2 Provision → verify row counts match local → `owner-verification-passes` 7.2
- [ ] 5.3 Second surface, same data appears → `owner-verification-passes` 7.3
- [ ] 5.4 CRUD propagates within a pull cycle → `owner-verification-passes` 7.4
