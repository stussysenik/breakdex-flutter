# Tasks

## 4. Action Audit Log

- [ ] 4.1 Design the Drift audit table and migration: action id, timestamp, actor/session, entity kind/id, operation, result, metadata, and error fields.
- [ ] 4.2 Add repository-level audit writes for create/update/delete/archive/restore/import/sync-apply mutations.
- [ ] 4.3 Add Machine<S,E> transition logging middleware for important state machines without changing transition behavior.
- [ ] 4.4 Add developer/support queries by entity, time range, operation, and failure status.
- [ ] 4.5 Add tests proving audit rows are append-only, compact, and non-authoritative.
