## ADDED Requirements

### Requirement: Append-only action log
The app SHALL persist an append-only local audit record for user-triggered mutations,
sync-triggered mutations, and important Machine<S,E> transitions.

#### Scenario: Mutation is recorded
- **WHEN** a repository write creates, updates, deletes, archives, restores, imports, or
  sync-applies an entity
- **THEN** the app writes an audit row containing action type, entity kind, entity id,
  timestamp, actor/session context, result, and compact metadata

### Requirement: Audit log is non-authoritative
The audit log MUST NOT become the source of truth for product state.

#### Scenario: Audit rows are missing or unreadable
- **WHEN** audit rows are unavailable because logging was disabled, pruned, or failed
- **THEN** the app continues reading product state from Drift tables and reports the audit
  gap separately

### Requirement: Queryable developer blackbox
The app SHALL expose developer/support queries for recent actions by time range, entity,
action type, and failure status.

#### Scenario: Support investigates a failed backup
- **WHEN** a developer filters the audit log for a video or move id
- **THEN** the log shows the ordered mutation/sync/backup events relevant to that entity
