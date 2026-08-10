# Spec: Multi-User Sync — Private Per-User Sync Proof Across Devices

> **Language: Dart (Flutter) + shell.** Depends on: `appwrite`,
> `migrate-canonical-backend-to-appwrite` (Phase M live pass),
> `add-first-user-production-provisioning`. Implementation in a fresh student session —
> never this one.

This spec defines the **proof** (not implementation) that the locked private-per-user
sync model isolates correctly across devices and users. The sync *implementation*
(identity via `userId`, per-user permissions, LWW + tombstones, dirty-guard) already
exists; this spec enumerates the cases that prove it and the honest NOT PROVEN ledger
around what loopback tests cannot reach. Where it is silent on sync semantics, the
`migrate-canonical-backend-to-appwrite` and `make-sync-total-and-registry-driven` specs
are normative.

**Scope guardrail.** This spec proves *isolation* — the opposite of multi-user
*sharing*. It does NOT require or permit crews, coaches, cross-user sharing, or
collaborative state (deferred by the CLAUDE.md non-goal block). Every requirement below
is about keeping one user's data sealed inside that user's own space.

Module layout (additive):
- `docs/sync-isolation-proof.md` — the proof matrix (cases, steps, expected/actual).
- `test/core/sync/sync_isolation_regression_test.dart` — loopback regression tests for
  dirty-guard + isolation-filter *logic*.

## ADDED Requirements

### Requirement: Private per-user cloud space is proven, not assumed

The repo SHALL document a proof that each signed-in user syncs only to their own
Appwrite account space and Google Drive file scope. The proof SHALL cover a shared-device
user switch (user A out, user B in) and SHALL record the actual result and the
surface/device that produced it. The proof SHALL be recorded in
`docs/sync-isolation-proof.md`.

#### Scenario: Two users sign in on the same device (OWNER-GATED)
- **WHEN** user A signs out and user B signs in on the same device
- **THEN** user B does not read, overwrite, or upload into user A's Appwrite documents
  or Google Drive files — and the proof document records the observed result

#### Scenario: Server-side isolation is exercised by a loopback test
- **WHEN** a sync-pull path reads rows for a signed-in `userId`
- **THEN** the read filters to that `userId` (verified by a loopback regression test
  that an unfiltered read would have crossed), so isolation is the server's responsibility
  and is testable without a second device

### Requirement: Second-device hydration preserves local state and tombstones

The repo SHALL document a proof that a user signing into a clean second device hydrates
the synced records without destroying local unsynced Drift state and while preserving
tombstone semantics. The proof SHALL record the actual result and the
surfaces/devices that produced it.

#### Scenario: Second device hydrates (OWNER-GATED)
- **WHEN** a user signs in on a clean second device after device one has synced moves,
  combos, reviews, notes, decks, tombstones, and metadata
- **THEN** the second device hydrates those records, preserves tombstone semantics, and
  does not silently drop any record type — and the proof document records the observed
  result

#### Scenario: Hydration does not destroy unsynced local state (OWNER-GATED)
- **WHEN** the second device holds a locally-unsynced edit at the moment of hydration
- **THEN** hydration reconciles it per LWW without destroying the unsynced edit — and the
  proof document records the observed result

### Requirement: Dirty-guard holds inbound updates against in-progress edits

The repo SHALL document a proof that a record locally dirty on one device is not
clobbered by an inbound realtime update from another device. The dirty-guard *decision*
SHALL be covered by a loopback regression test; the end-to-end cross-device behavior is
OWNER-GATED.

#### Scenario: Dirty local edit receives remote update (loopback-testable)
- **WHEN** a record is locally dirty and an inbound realtime update arrives for that
  record
- **THEN** the inbound update is held or reconciled according to the existing dirty-guard
  rules and does not clobber in-progress edits — verified by a loopback regression test

#### Scenario: Cross-device dirty-guard (OWNER-GATED)
- **WHEN** device one has a record mid-edit and device two pushes an update to that
  record
- **THEN** device one's in-progress edit is held/reconciled, never silently overwritten —
  and the proof document records the observed result

### Requirement: NOT PROVEN ledger is honest

The repo SHALL record, in `docs/sync-isolation-proof.md`, exactly which proof legs were
run on loopback vs. which remain OWNER-GATED (needing two physical devices, live
Appwrite, or real OAuth), so a green document never implies more than it tested.

#### Scenario: Owner-gated legs are named
- **WHEN** the proof document is complete
- **THEN** every case that needs two devices / live cloud / real OAuth is tagged
  OWNER-GATED and appears in the NOT PROVEN section until the owner runs it — it is never
  self-graded by an agent
