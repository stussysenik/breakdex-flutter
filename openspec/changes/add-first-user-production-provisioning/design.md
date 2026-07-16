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
  canonical. `dev0` is likewise rehearsal-only.
- Correction to the prior plan: minting `itsmxzou` email/password did **not** create a
  "both doors, one account" — that only holds if the Google email equals the mint email.

## Activation trigger (D2)

Hook alongside the existing one-shot login side-effect
(`legacy_identity_providers.dart:30`, watched at `bottom_nav_shell.dart:62`). New
provider `firstLoginProvisioningTrigger`:

```
on session established (userId != null):
  if prefs.getBool('sync.provisioned.$userId') == true: return          # one-shot
  if not remoteConfig.syncActivationEnabled: return                     # gate (default OFF)
  reports = await fullBackfillService.backfillAll()                     # 8 entities, idempotent
  await syncService.setDualWriteAll(true)                               # additive
  await syncService.setDualReadAll(true)
  await prefs.setBool('sync.provisioned.$userId', true)                 # never auto-reruns
  # on any throw: leave prefs OFF, do NOT set one-shot → safe retry next launch
```

- **Safety:** backfill is non-destructive + idempotent (verified — `sync_backfill_service.dart:57`,
  `reconcile.dart:271`). Flipping dual-read/write is additive: Drift stays canonical, the
  shadow is populated. Partial-failure leaves the user un-activated (prefs OFF, one-shot
  unset) so the next launch retries cleanly — activation is all-or-nothing.
- **One-shot per userId** so switching accounts on a shared device provisions each once.
- **Rollout ordering (optional):** remote config MAY carry a per-entity activation order
  (moves first, per `docs/sync-rehearsal-runbook.md`) instead of all-at-once; default
  all-at-once is acceptable since backfill+dual-read are independent per entity.

## Remote-config gate (D3)

Add `syncActivationEnabled: bool` (default false) to the `appConfig` model + source
(mirror `kEntitlementGateEnabled`/`kRemoteConfigLiveEnabled` posture). Owner flips it on
the live `appConfig.current` row when ready — no new binary, reversible. Until then every
surface stays byte-identical to today (Firestore-only, no backfill).

## Owner's immediate path vs. general path

- **Us, right now:** either (a) build once with `--dart-define=DEV_SYNC_PANEL=true`,
  Google-sign-in as senik456 on device, tap **Backfill now**, flip dual-read per entity
  (the rehearsal path, already shipped); or (b) once this change lands + the remote-config
  flag is on, just Google-sign-in and it auto-provisions. Both converge on the same
  senik456 shadow space.
- **Other users:** path (b) only — first login auto-provisions.

## Known limitation (documented, not fixed here)

Sub-second LWW: `sync_service.dart:648` compares whole seconds (Drift stores seconds,
backend carries ms). Two devices editing one record within the same wall-clock second each
keep their own version (tie → local) until a later edit advances the second. Data-safe,
not guaranteed-convergent in that window. Follow-up: store `updatedAtMs` in Drift and
compare ms (schema migration) — separate change.

## Verification strategy (tests, not device-driving)

Per the cheap-signals-first rule, all logic is proven by tests; device work is handed off:

- **Unit/widget:** trigger runs backfill exactly once + flips prefs + sets one-shot;
  second login is a no-op; gate-off → no activation; backfill throw → prefs stay OFF.
- **Integration:** idempotent replay (re-run backfill → no dup rows); per-user isolation
  (sync-pull filters to userId).
- **Device soak (dedicated session, owner-driven — NOT in this change):** Google-sign-in
  senik456 on phone → auto-provision → second device (or web) signs in same identity →
  same data appears → CRUD on either surface propagates (the argent "all devices up, one
  truth, CRUD works" acceptance test). Use Maestro/Patrol if a driver is wanted; otherwise
  manual. Runtime signals: Dart MCP `get_app_logs` + server-side `curl`/row counts.
