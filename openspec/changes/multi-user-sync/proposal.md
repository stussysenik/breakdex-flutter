# Multi-User Sync — Private Per-User Sync Proof Across Devices

> **Language: Dart (Flutter) + shell.** Depends on: `appwrite`, `migrate-canonical-backend-to-appwrite`
> (Phase M live pass), `add-first-user-production-provisioning`. Implementation in a
> fresh student session — never this one.

> **Naming note.** This change is called `multi-user-sync` for historical reasons (it was
> split from the `engineer-workflow-and-multi-user-foundation` umbrella). Its actual scope
> is the **opposite** of multi-user *sharing*: it proves that **one signed-in user's data
> stays isolated to that user across multiple devices** — private per-user sync, the
> locked user model. It does NOT add crews, coaches, cross-user sharing, or any
> collaborative state (all deferred by the non-goal block). Read this change as
> "prove private per-user sync works across devices."

## Why

The sync *services* are built and server-side-complete: identity is Appwrite `userId`
(not email); backfill writes are per-user permissioned and idempotent (`(userId,id)`
dedup + LWW); reads are `userId`-isolationed server-side on the trusted
`x-appwrite-user-id` header. The live Phase-M pass (`migrate-canonical-backend-to-appwrite`)
proved the 9 wired entities move real data to web.

**The gap:** that proof ran on **one surface at a time**. Nothing proves the locked
**private-per-user** model holds when the *same* user signs into a *second* device, or
when *two different users* share one device — the two cases that, if broken, mean one
user reads or overwrites another's data. Specifically:

1. **Second-device hydration is unproven.** A user signs into a clean second device
   after the first has synced moves, combos, reviews, notes, decks, tombstones. Does the
   second device hydrate those records *and* preserve tombstone semantics *without*
   destroying local unsynced Drift state? Unknown.

2. **Cross-user isolation is unproven on a shared device.** User A signs out, user B
   signs in on the same device. Does user B read, overwrite, or upload into user A's
   Appwrite documents or Google Drive files? Server-side isolation is coded; it is not
   *proven* end-to-end on a surface.

3. **The dirty-guard under cross-device edit is unproven.** A record is locally dirty on
   device one while an inbound realtime update arrives from device two. The dirty-guard
   *should* hold/reconcile the inbound update without clobbering the in-progress edit —
   but this is the one behavior that breaks keystrokes, and it is asserted in unit tests,
   not proven across two live surfaces.

This change defines the **proof** for those three cases. It is the verification half of
the locked private-per-user model — the implementation already exists; this proves it.

## What Changes

This change adds **no new sync implementation**. It defines the proof cases, the
owner-gated runbook for running them on real surfaces, and records the result:

1. **Isolation proof matrix.** A `docs/sync-isolation-proof.md` that enumerates the
   cases (second-device hydration; shared-device user switch; dirty-guard under
   cross-device edit), the exact steps, the expected result, and — after the owner runs
   them — the actual result + surface/device that produced it.
2. **Owner-gated runbook.** Proof tasks that need live Appwrite credentials, two
   devices, and real OAuth are tagged `OWNER-GATED` and are never agent-driven — the
   owner runs them in a dedicated session; the agent's deliverable is the *document*, not
   the device run.
3. **NOT PROVEN ledger.** After the proof, an honest record of what still needs a
   physical device / live cloud / real money and was *not* proven by loopback tests.

## Capabilities

- `multi-user-sync` — proof (not implementation) that private per-user sync isolates
  correctly across devices and users, with an honest NOT PROVEN ledger.

## Footprint estimate

| Surface | Current → Target | Notes |
| --- | --- | --- |
| `docs/sync-isolation-proof.md` (new) | — | ~80 LOC, the proof matrix + results |
| `test/core/sync/` | +1 regression test file, ~100 LOC | dirty-guard + isolation *logic* (loopback) |
| Implementation code | **0 LOC** | this change proves; it does not build |

Net: ~180 LOC, +1 doc +1 test file. Zero production code.

## Non-goals

- **No multi-user *sharing*.** Crews, coaches, cross-user sharing, and collaborative
  state are deferred (CLAUDE.md non-goal). This change proves *isolation*, the opposite.
- **No new sync implementation.** Identity, backfill, reads, LWW, tombstones,
  dirty-guard, and server-side `userId` isolation already exist. This change does not
   touch them except to add loopback regression tests for the dirty-guard + isolation
   *logic*.
- **No agent-driven device runs.** All proof tasks needing two devices, live Appwrite,
   or real OAuth are OWNER-GATED. The agent writes the document; the owner runs it.
- **No sub-second LWW rework.** Documented known-limitation of the existing model; a
  follow-up, not this change.
