# sync-totality

## ADDED Requirements

### Requirement: Every Drift table is a registered sync entity or a reasoned local-only table

The system SHALL maintain a `kLocalOnlyTables` set naming every Drift table that is
intentionally not synced, each paired with a written reason. A test SHALL enumerate every
table registered in the Drift database and assert that each table id is either present in
the sync registry or present in `kLocalOnlyTables`. A table that is neither SHALL fail the
test. This makes an un-synced user-data table a red test rather than a silent production
gap.

#### Scenario: An unclassified table fails the gate
- **WHEN** a Drift table exists that is neither in the sync registry nor in `kLocalOnlyTables`
- **THEN** the totality test fails and names the offending table

#### Scenario: A new feature table cannot merge unclassified
- **WHEN** a change adds a new Drift table without registering it or marking it local-only
- **THEN** the totality test fails in CI, blocking merge until the author registers the table or adds it to `kLocalOnlyTables` with a reason

#### Scenario: Local-only bookkeeping tables pass explicitly
- **WHEN** a device-bookkeeping table (e.g. the local operation log) is present
- **THEN** it passes the gate only because it is listed in `kLocalOnlyTables` with a reason, not by default

### Requirement: The coverage ledger is human-readable and authoritative

The system SHALL keep `docs/sync-coverage.md` classifying every Drift table as synced,
local-only (with reason), or must-sync, and this ledger SHALL agree with the registry and
`kLocalOnlyTables` at all times.

#### Scenario: Ledger and code agree
- **WHEN** the totality test passes
- **THEN** `docs/sync-coverage.md` lists the same synced set and the same local-only set as the registry and `kLocalOnlyTables`
