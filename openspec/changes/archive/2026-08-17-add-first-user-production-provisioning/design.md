# Design — first-user production provisioning & sync activation

## The distributed-systems model (restate before touching code)

- **One source of truth = the device's Drift DB.** Appwrite is a shadow replica. A
  surface with an empty local DB (fresh web/OPFS, new install) has *nothing to back up* —
  backfill must run **from the device that holds the library**, then other surfaces
  read it back. This is why provisioning is device-first, web-second.
- **Identity = Appwrite `userId`**, established by OAuth and stamped server-side from the
  trusted `x-appwrite-user-id` header. Email is display/legacy-join only. No owner email
  is hardcoded (verified). Therefore "who owns the data" is decided operationally by
  *which account signs in at backfill time*, not by any code constant.

## Identity ruling (D1)

- **Canonical owner = Google sign-in as `senik456@gmail.com` on the device.** The owner
  must Google-sign-in as senik456 *before* provisioning so the backfilled rows are stamped
  to senik456's `userId`.
- The prior-session `itsmxzou@gmail.com` **email/password** account (id `6a5596818ea8e26e048a`)
  is a rehearsal artifact: a *different email* than the Google identity, so Appwrite will
  **not** merge them, and it holds no data. Leave it (harmless) or delete it — it is not
  canonical.

## Activation trigger (D2)

Hook alongside the existing one-shot login side-effects at the shell root
(`bottom_nav_shell.dart:71-78`), mirroring `hydrateOnLoginTriggerProvider` exactly
(`lib/core/services/hydrate_on_login_providers.dart`). New provider
`firstLoginProvisioningTrigger`:

```
on session established (userId != null):
  if prefs.getBool('sync.provisioned.$userId') == true: return   # one-shot, durable
  deferred past build (Future.microtask, like hydrate):
    reports = await syncService.activateSync()                    # 8 entities, idempotent
    await prefs.setBool('sync.provisioned.$userId', true)        # never auto-reruns
  # on any throw: leave prefs OFF, do NOT set one-shot → safe retry next launch
```

Key differences from the prior design: **no remote-config gate** (Phase M.5 not proven
live), and `activateSync()` composes the eight `SyncBackfillService.backfill*()` calls
and flips prefs atomically (backfill first; only on success are prefs flipped and the
one-shot set) instead of a separate `backfillAll()`. The proven pattern is the hydrate
trigger — same deferral, same swallow-throws posture, same one-shot guard.

- **Safety:** backfill is non-destructive + idempotent (verified —
  `sync_backfill_service.dart:61-174`, `reconcile.dart:271`). Flipping dual-read/write is
  additive: Drift stays canonical, the shadow is populated. Partial-failure leaves the
  user un-activated (prefs OFF, one-shot unset) so the next launch retries cleanly —
  activation is all-or-nothing.
- **One-shot per userId** so switching accounts on a shared device provisions each once.

## SyncService API shape (D3)

Additive methods on `SyncService` (no existing behavior changes):

- `setDualWriteAll(bool)` — write the 5 write keys (moves, combos, reviews, decks,
  noteEntries). Skip fsrsCards (derived server-side).
- `setDualReadAll(bool)` — write the 6 read keys (moves, combos, reviews, fsrsCards,
  decks, noteEntries).
- `activateSync()` — compose the 8 `SyncBackfillService.backfill*()` calls via
  `fullBackfillServiceProvider`; on full success `setDualWriteAll(true)` then
  `setDualReadAll(true)`; on any throw, change no prefs, propagate. Returns
  `List<BackfillReport>`.

## Offering config (D4)

`lib/core/config/offerings_config.dart` — `OfferingsConfig.resolve()` reads
`--dart-define=OFFERINGS_JSON`. Malformed → absent (never throws, never guesses). The
existing purchase UI resolves the configured id per tier; absent tier → that tier's paid
control hidden/disabled, no checkout with a placeholder id. No hardcoded ids.

## Owner's immediate path

Once this change lands, just Google-sign-in on the device — it auto-provisions. The dev
panel (`kDevSyncPanelEnabled`) stays for rehearsal but is byte-disabled by default and is
no longer the only activation path.

## Known limitation (documented, not fixed here)

Sub-second LWW: `sync_service.dart:648` compares whole seconds. Two devices editing one
record within the same wall-clock second each keep their own version (tie → local) until
a later edit advances the second. Data-safe, not guaranteed-convergent in that window.
Follow-up: store `updatedAtMs` in Drift and compare ms (schema migration) — separate change.

## Verification strategy (tests, not device-driving)

Per the cheap-signals-first rule, all logic is proven by tests; device work is handed off:

- **Unit/widget:** trigger runs backfill exactly once + flips prefs + sets one-shot;
  second login is a no-op; no-session → no-op; backfill throw → prefs stay OFF.
- **Integration:** idempotent replay (re-run backfill → no dup rows); per-user isolation
  (sync-pull filters to userId).
- **Offering config:** present resolves id; absent disables; malformed degrades.
- **Device soak (dedicated session, owner-driven — NOT in this change):** Google-sign-in
  senik456 on phone → auto-provision → second device (or web) signs in same identity →
  same data appears → CRUD on either surface propagates (the argent "all devices up, one
  truth, CRUD works" acceptance test). Runtime signals: Dart MCP `get_app_logs` +
  server-side `curl`/row counts.
