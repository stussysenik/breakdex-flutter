# Tasks — first-user production provisioning & sync activation

> Ledger audited 2026-07-27: **0/15 is accurate — nothing here has shipped.** Greps for
> `syncActivationEnabled`, `setDualWriteAll`, `activateSync`, `firstLoginProvisioningTrigger`,
> and `sync.provisioned` return zero hits in `lib/`+`test/`, and
> `appwrite_functions_transport.dart` has no `Query.equal('userId', …)` (5.1 open too).
> The remote-config files that exist (`remote_config_service.dart`,
> `appwrite_remote_config_source.dart`, `update_gate.dart`) belong to
> `migrate-canonical-backend-to-appwrite` Phase 1R, not to this change's tasks.

**Dependencies:** Phase 1 (remote-config field) and Phase 2 (SyncService activation API)
are independent; Phase 3 (trigger) consumes both; Phase 4 (tests) consumes 1–3; Phase 5
is optional hardening (independent); Phase 6 is owner-driven device proof (after 1–4).

**Verification = tests + grep + runtime MCP** (no agent-driven UI). Ledger rule: tick in
the same commit that lands the work. Binary truth: no tick without `flutter test` /
`flutter analyze` output.

## Phase 1 — Remote-config gate
- [ ] 1.1 Add `syncActivationEnabled: bool` (default false) to the `appConfig` model +
      `AppwriteRemoteConfigSource` parse, mirroring `kEntitlementGateEnabled` posture.
- [ ] 1.2 Expose it through the config provider the shell can read; default resolves OFF
      when session-less / cache-miss (byte-identical to today).

## Phase 2 — SyncService production activation API
- [ ] 2.1 Add `SyncService.setDualWriteAll(bool)` / `setDualReadAll(bool)` (and per-entity
      variants if not already public) — the same prefs `SyncCutoverPanel` writes
      (`sync_service.dart:56`), now callable outside the dev flag.
- [ ] 2.2 Add `activateSync()` = run `fullBackfillService` backfill for all 8 entities →
      on success flip dual-write+dual-read all ON → return the per-entity reports. Throw
      (leaving prefs untouched) on any backfill failure (all-or-nothing).

## Phase 3 — First-login provisioning trigger
- [ ] 3.1 New `firstLoginProvisioningTrigger` provider next to
      `legacy_identity_providers.dart`; watch it once at `bottom_nav_shell.dart:62`
      (alongside the legacy-claim trigger).
- [ ] 3.2 Logic: session established + `!prefs['sync.provisioned.$userId']` +
      `remoteConfig.syncActivationEnabled` → `await syncService.activateSync()` → set the
      per-user one-shot flag. On throw: do NOT set one-shot (safe retry next launch).
- [ ] 3.3 Confirm no behavior change when the gate is OFF (grep: no other pref writer;
      trigger returns early).

## Phase 4 — Tests (the proof)
- [ ] 4.1 Trigger: gate ON + unprovisioned → calls `activateSync` once, sets one-shot;
      second build → no-op. Gate OFF → never calls. Backfill throw → one-shot stays unset,
      prefs stay OFF.
- [ ] 4.2 `activateSync` idempotency: replay backfill against a seeded fake backend → no
      duplicate rows (logical `(userId,id)` dedup).
- [ ] 4.3 Isolation regression: sync-pull path filters to `userId` (guard against a future
      unfiltered read). `flutter analyze` 0 errors; `flutter test` green.

## Phase 5 — Optional defense-in-depth (independent)
- [ ] 5.1 Add explicit `Query.equal('userId', userId)` to client direct-reads of
      `reviewEvents`/`fsrsCards` in `appwrite_functions_transport.dart:70` (belt-and-suspenders
      over row permissions).

## Phase 6 — Owner-driven device proof (dedicated session — NOT auto-driven)
- [ ] 6.1 Owner: Google-sign-in as `senik456@gmail.com` on the phone (canonical identity).
- [ ] 6.2 Provision (auto once flag flipped, or dev-panel Backfill now) → verify per-entity
      row counts match local library via server-side `curl` / `get_app_logs`.
- [ ] 6.3 Second surface (web / other device) signs in same identity → same data appears.
- [ ] 6.4 CRUD on either surface propagates within a pull cycle (argent acceptance:
      all devices up, one truth, CRUD works). Flip `appConfig.syncActivationEnabled` live
      when satisfied.
