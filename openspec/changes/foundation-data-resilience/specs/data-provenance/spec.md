## ADDED Requirements

### Requirement: Provenance events table

The system SHALL persist provenance events in a `provenance_events` table with columns:

- `id` (TEXT, primary key, UUID)
- `entity_type` (TEXT, not null — `move`, `combo`, or `set`)
- `entity_id` (TEXT, not null)
- `event_type` (TEXT, not null — `created`, `reviewed`, `edited`, `tagged`, `milestone_reached`)
- `timestamp` (INTEGER, not null, epoch millis)
- `metadata` (TEXT, nullable — JSON blob for event-specific data)

An index SHALL exist on `(entity_type, entity_id, timestamp)` to support timeline queries.

#### Scenario: Record a review event

- **WHEN** a move "Windmill" is reviewed with rating "Good"
- **THEN** a row SHALL be inserted with `entity_type = 'move'`, `entity_id` = Windmill's UUID, `event_type = 'reviewed'`, `timestamp` = current time, `metadata` = `{"rating": "good", "fsrs_state": "review"}`

#### Scenario: Record a creation event

- **WHEN** a new move is created via the repository
- **THEN** a provenance event with `event_type = 'created'` SHALL be automatically inserted

#### Scenario: Record a milestone event

- **WHEN** a move's `learning_state` transitions to `mastery`
- **THEN** a provenance event with `event_type = 'milestone_reached'` and `metadata = {"milestone": "mastery"}` SHALL be inserted

#### Scenario: Record an edit event

- **WHEN** a move's name or category is changed
- **THEN** a provenance event with `event_type = 'edited'` and `metadata` containing the changed fields SHALL be inserted

### Requirement: Timeline queries

The `ProvenanceEventsDao` SHALL support:
- `getTimeline(entityType, entityId)` → all events for one entity, ordered by timestamp ascending
- `getTimelineRange(entityType, entityId, startTime, endTime)` → events within a time range
- `getRecentActivity(limit)` → most recent N events across all entity types
- `getEntityMilestones(entityType, entityId)` → only `milestone_reached` events

#### Scenario: Timeline for a move

- **WHEN** `getTimeline('move', windmillId)` is called
- **THEN** the result SHALL list all events for that move ordered by timestamp, including creation, reviews, edits, and milestones

#### Scenario: Filtered by month

- **WHEN** `getTimelineRange('move', windmillId, march1Timestamp, march31Timestamp)` is called
- **THEN** the result SHALL contain only events whose timestamps fall within March

#### Scenario: Recent activity feed

- **WHEN** `getRecentActivity(10)` is called
- **THEN** the result SHALL return the 10 most recent events across all entities, ordered by timestamp descending

### Requirement: Append-only immutability

The `provenance_events` table SHALL be append-only. No row SHALL be updated or deleted after insertion.

#### Scenario: Insert succeeds

- **WHEN** a provenance event is inserted
- **THEN** the operation SHALL succeed

#### Scenario: Update is rejected

- **WHEN** an attempt is made to UPDATE a provenance event row
- **THEN** the operation SHALL be rejected at the DAO level

#### Scenario: Delete is not exposed

- **WHEN** a DAO consumer attempts to delete a provenance event
- **THEN** no `deleteEvent` method SHALL exist on the DAO

### Requirement: Purge policy

To manage table growth, events older than a configurable retention period SHALL be candidates for archival. The default retention period SHALL be 365 days.

#### Scenario: Events within retention are kept

- **WHEN** a provenance event is 200 days old and the retention period is 365 days
- **THEN** the event SHALL be retained

#### Scenario: Events beyond retention are purged

- **WHEN** a provenance event is 400 days old and the retention period is 365 days
- **THEN** the event SHALL be eligible for removal during the next purge cycle

### Requirement: Automatic event logging from repositories

Existing `SyncAware` repositories SHALL be extended to emit provenance events automatically for all write operations (create, update, delete, review).

#### Scenario: Move creation logs provenance

- **WHEN** `MoveRepository.create()` is called
- **THEN** a `provenance_events` row with `event_type = 'created'` SHALL be inserted without the caller needing to explicitly log it

#### Scenario: Review logs provenance

- **WHEN** `ReviewRepository.recordReview()` is called
- **THEN** a `provenance_events` row with `event_type = 'reviewed'` and review metadata SHALL be inserted
