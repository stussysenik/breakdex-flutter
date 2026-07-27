# Data Update & Observable History Playbook

This is the operating model for smooth app updates: schema changes, update testing,
action history, and UI projections. It complements the engineering manual; it does not
replace `docs/manual/03-data-layer.mdx` or `docs/manual/04-sync.mdx`.

## Ruling

Breakdex is local-first and observable-first:

- Drift rows are the current product truth.
- Migrations are forward-only and additive by default.
- Deletes propagate as tombstones before anything physical is reclaimed.
- The action log is append-only and non-authoritative.
- `Machine<S,E>` transition tables are the central ruling layer for UI state.
- Projections decide what to show; they are rebuildable from Drift, action history, or both.

That gives us the useful split: current state answers "what is true now?", while action
history answers "how did we get here?"

## Update Contract

Every persisted data update must satisfy this contract before release:

1. **Old data opens.** A database from the previous shipped version migrates to `HEAD`
   without user action.
2. **No orphaning.** Existing moves, combos, sets, reviews, media pointers, sync cursors,
   and tombstones remain reachable or intentionally soft-hidden.
3. **The UI renders from migrated state.** The app boots and key screens can render against
   the migrated database.
4. **Sync remains idempotent.** Replaying queued or remote records after the update is a
   no-op or a newer LWW apply, never a duplicate mutation.
5. **The change is observable.** Failures leave enough audit/provenance information to
   answer which action, entity, and migration step failed.

## Schema Update Pattern

Use this sequence for local Drift changes:

1. Add the new table/column in the hand-written Drift schema.
2. Bump `AppDatabase.schemaVersion` by exactly one.
3. Add an `if (from < N)` migration block.
4. Prefer nullable/additive columns, then backfill with a separate `UPDATE`.
5. Guard legacy drift with `PRAGMA table_info` when a device may already have a column.
6. Re-run triggers/backfills that are declared idempotent.
7. Regenerate Drift code with `dart run build_runner build --delete-conflicting-outputs`.
8. Add migration tests from at least the previous shipped schema shape.
9. Run the app against migrated data before claiming release safety.

Never use a non-constant SQLite default in `ADD COLUMN`; add nullable first and backfill.

## Action History

The action log should record compact facts, not full product snapshots:

- action id
- timestamp
- actor/session
- source: user, sync, migration, background job, support tool
- entity kind/id
- operation
- result: success, failure, ignored, retried
- error class/message when present
- small metadata needed for support queries

The log is append-only. Corrections are new rows. Product state still comes from Drift
tables so the app can keep working if logging is disabled, pruned, or partially failed.

## State Machines As Rulings

For UI and workflow behavior, the machine transition table is the legal graph:

```
intent/event -> pure transition -> new state -> entry action -> result event
```

Important consequences:

- Impossible states are omitted transitions, not runtime checks scattered through widgets.
- Dirty guards are state-machine behavior: an inbound update either applies, waits, or is
  ignored because the graph says so.
- Transition logging observes the graph without changing transition behavior.
- XState web machines mirror the same state/event/guard language where a web surface
  exists.

## Projections And What To Show

Treat visible UI as a projection over sets:

- current entity set: active, archived, deleted/tombstoned
- media materialization set: local, remote, both, missing, restoring
- sync set: clean, dirty, queued, failed, retrying
- permission/capability set: available, unavailable, degraded
- action-history set: recently touched, failed, retried, support-relevant

The screen chooses intersections of those sets. For example:

- active move + local media -> normal playable tile
- active move + remote media only -> downloadable/restorable tile
- active move + missing media + restorable history -> ghost with restore action
- tombstoned move -> hidden from normal library, visible to recovery/support projections
- dirty edit + inbound sync update -> hold or defer remote projection until save/discard

This keeps ghosting honest. A ghost is not decorative loading chrome; it is a visible
projection of "the record exists but the materialized resource or final state is not here."

## Clean Update Test Loop

For release candidates, run the update loop like this:

1. Build or obtain an old-version fixture database.
2. Boot the old version once and create representative data:
   moves, combos, reviews, media pointers, deleted/tombstoned rows, queued sync work.
3. Install or run the new build over that state.
4. Confirm migration completes and startup reaches the normal app shell.
5. Exercise key projections:
   library, move detail, review, sync status, missing-media/ghost state, settings export.
6. Run full gates:
   `./verify.sh`, then platform artifact builds through `scripts/distribute.sh`.
7. Record what was proven and what remains owner/device-gated.

This is the "clean update" promise: the user updates the app and their history is still
there, readable, syncable, and explainable.

## Scriptability Target

The desired ergonomics are one-command, Roblox-like loops:

```sh
./verify.sh
scripts/distribute.sh android-aab
scripts/distribute.sh ios-nosign
scripts/distribute.sh web
```

Future work should add fixture-driven commands for old-db upgrade tests, but the same rule
holds: a script must either exit 0 with a precise proof, or exit non-zero with enough
stderr/log context to decide the next fix.
