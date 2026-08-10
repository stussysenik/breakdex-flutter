# Design: Multi-User Sync — Private Per-User Sync Proof Across Devices

This change is self-contained (it was previously split from the archived
`engineer-workflow-and-multi-user-foundation`; that parent's design is gone, so the
decisions live here).

## Core decision: this change proves, it does not build

The locked user model is **private per-user sync**: any Google sign-in gets an isolated
space; the owner is just user #1; no cross-user sharing. The *implementation* of that
model (identity via Appwrite `userId`, per-user permissions, LWW + tombstones,
dirty-guard, server-side `userId` reads) is already built and server-side-complete.

So this change's job is **proof, not production code.** Its deliverable is a document
(`docs/sync-isolation-proof.md`) that enumerates the isolation cases, the exact steps to
prove each, the expected result, and — after the owner runs them — the actual result and
which surface/device produced it. Loopback regression tests back the *logic* (dirty-guard
decision, isolation filter); the *end-to-end* proof across two live surfaces is
owner-gated.

## The three proof cases

1. **Second-device hydration.** Same user, clean second device, signs in after device
   one synced. Expect: hydrate all record types + preserve tombstones + do not destroy
   local unsynced Drift state. Risk: a naive "replace local with remote" would silently
   drop unsynced edits — this case guards against that.

2. **Shared-device user switch.** User A out, user B in, same device. Expect: B cannot
   read/overwrite/upload into A's Appwrite docs or Drive files. Risk: a stale-session or
   cached-credential bug leaks A's data to B.

3. **Dirty-guard under cross-device edit.** Record dirty on device one, inbound realtime
   update from device two. Expect: inbound held/reconciled per dirty-guard rules, in-edit
   keystrokes never clobbered. Risk: mid-edit clobber is the highest-severity sync defect
   (silent data loss the user cannot see).

## Owner-gated vs agent-delivered

Per the factory's "no agent-driven device runs" bar, the two-device / live-OAuth /
live-Appwrite proof runs are **OWNER-GATED** — the owner executes them in a dedicated
session. The agent delivers the *document + loopback tests*; the owner fills in the
actual results. The NOT PROVEN ledger is honest about this split.

## Why not add implementation

Adding sync *code* to prove sync *correctness* is circular — you'd be testing new code
with new code. The existing services are the subject; this change observes them. The only
new regression tests are for logic already unit-testable in isolation (dirty-guard
decision, isolation query filter), hardening the floor the live proof stands on.
