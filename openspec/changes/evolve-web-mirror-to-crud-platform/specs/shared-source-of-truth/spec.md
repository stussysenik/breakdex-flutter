# shared-source-of-truth

## ADDED Requirements

### Requirement: Canonical backend holds truth; clients hold caches

The system SHALL designate a single canonical backend as the source of truth for library
metadata (moves, combos, journal, plans, FSRS state, review log, and the media index). The
Flutter app's local Drift database and the web app's local store SHALL function as caches of that
truth, not as independent authorities. The concrete backend provider is selected per `design.md`
Open Decision 1 and SHALL sit behind a provider-agnostic sync contract.

#### Scenario: Web reads truth through its cache
- **WHEN** the web app loads after sign-in
- **THEN** it renders from its local cache immediately and reconciles against the canonical backend, updating the view when newer truth arrives

#### Scenario: Phone reads truth offline
- **WHEN** the phone is offline
- **THEN** it serves library data from its local Drift cache and queues reconciliation for when connectivity returns

### Requirement: Non-destructive backfill and reversible cutover

Promoting the backend to source of truth SHALL be performed by a one-time backfill that reads the
existing local data and writes it to the backend, and SHALL NOT delete or overwrite local data in
the process. Until a two-way reconcile is verified, the local database SHALL remain authoritative
and the backend SHALL be treated as a shadow copy. The cutover SHALL be reversible to
local-authoritative.

#### Scenario: Backfill preserves local state
- **WHEN** the backfill runs against a populated local database
- **THEN** every local record is written to the backend and no local record is deleted or mutated

#### Scenario: Cutover gated on verified reconcile
- **WHEN** the two-way reconcile has not yet been verified
- **THEN** the system keeps the local database authoritative and does not promote the backend

#### Scenario: Cutover can be rolled back
- **WHEN** an issue is detected after cutover
- **THEN** the system can revert to local-authoritative without data loss

### Requirement: Write-through with single-writer reconciliation

Edits SHALL be applied optimistically to the local cache and written through to the canonical
backend, reconciling on acknowledgement. Conflicts SHALL resolve by last-writer-wins per field
using a monotonic `updatedAt`, under a single-writer-at-a-time assumption. Deletes SHALL be soft
(archive with recovery) and SHALL NOT hard-delete user state.

#### Scenario: Optimistic edit reconciles
- **WHEN** the owner edits a field on one client
- **THEN** the edit appears immediately locally, is written to the backend, and propagates to the other client on its next reconcile

#### Scenario: Conflicting edits resolve deterministically
- **WHEN** the same field is edited on two clients before reconcile
- **THEN** the edit with the later `updatedAt` wins and the superseded value is retained in history, not destroyed
