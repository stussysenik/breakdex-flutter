# Breakdex Domain Context

This is the glossary for the product/domain model. It is not an implementation spec and
does not decide file paths, tables, or UI layout.

## Terms

### Action

A user, sync, or system intent that attempts to change product state or advance an
important state machine.

An action is observable. It may succeed, fail, or be ignored by a state machine, but it
still exists as part of the support/debug story once action auditing is enabled.

### Action Log

An append-only history of actions and important `Machine<S,E>` transitions.

The action log is explanatory and queryable, not authoritative. Product screens read
current state from Drift rows. The log answers "what happened?" and can feed projections;
it does not replace the current-state tables.

### Current State

The latest product truth used by the app to render normal screens.

In Breakdex, current state is local Drift/SQLite. Sync backends, exports, and audit logs
are shadows, projections, or explanations unless a future spec explicitly changes that
ruling.

### Projection

A derived view computed from current state, action history, or both.

Examples include "recent failed imports", "entities touched during this session", and
"items that should show a restoring ghost." Projections are rebuildable and may be
discarded without data loss.

### Ghost

A visible placeholder for a resource or state that is referenced but not currently fully
materialized.

A ghost is honest UI: it says "the record exists, but the bytes/result/view are pending,
missing, or recoverable." A ghost is never a fake success state.

### Schema Update

A forward-only change to persisted local or backend data shape.

Schema updates must preserve existing user data, be testable from an old shape to the new
shape, and produce observable evidence that the app can still render and sync afterward.

### Tombstone

A soft-delete marker saying an entity was deleted at a time, without immediately destroying
all traces or bytes.

Tombstones support sync, recovery, history, and delayed cleanup. They are distinct from a
hard delete.
