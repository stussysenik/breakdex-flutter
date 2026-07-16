# sync-registry

## ADDED Requirements

### Requirement: A single entity registry drives all sync dispatch

The system SHALL define each synced entity as one immutable `SyncEntity` descriptor
carrying its `SyncEntityType`, backend/Drift table id, codec (encode/decode), a `pushable`
flag, and pref keys **derived** from the entity name (dual-write, dual-read, cursor). The
dual-write, dual-read/pull, and backfill paths SHALL iterate the registry of descriptors
rather than hand-written per-entity branches, and pref keys SHALL NOT be typed as
standalone literal constants that duplicate the derived keys.

#### Scenario: Dual-write iterates the registry
- **WHEN** a batch of local operations is flushed with dual-write enabled
- **THEN** the service pushes each operation by looking up its entity descriptor in the registry, with no entity-name string branch in the dispatch

#### Scenario: Behaviour is preserved for the original entities
- **WHEN** the 9 originally-wired entities run under the registry
- **THEN** the existing dual-write parity, dual-read, and byte-identical backfill suites pass unchanged

#### Scenario: Adding an entity is one descriptor plus one codec
- **WHEN** a new entity is added to the registry with its codec
- **THEN** dual-write, dual-read, and backfill cover it with no further edits to the dispatch loop

### Requirement: Pull-only and paired entities are descriptor flags, not branches

The registry SHALL represent server-derived pull-only entities via a `pushable: false`
descriptor flag, and SHALL represent paired entities (that share one write/read switch but
keep independent cursors) via a parent link on the descriptor, so the dispatch loop needs
no per-entity special-casing.

#### Scenario: Pull-only entity is never pushed
- **WHEN** the dual-write loop runs
- **THEN** an entity whose descriptor sets `pushable: false` (e.g. the FSRS card) is skipped by the push path and still pulled by the read path

#### Scenario: A pair shares one switch and two cursors
- **WHEN** a paired entity's dual-write switch is enabled
- **THEN** both members write under the shared switch while each advances its own backend cursor
