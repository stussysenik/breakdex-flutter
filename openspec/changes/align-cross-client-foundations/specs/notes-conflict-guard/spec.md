# notes-conflict-guard

## ADDED Requirements

### Requirement: Dirty edits are never clobbered by inbound sync
Both clients SHALL hold inbound sync or realtime updates for a record whose editing state
machine is in a dirty/editing state (a latest-wins queue of one), with the held update
applied only after the machine transitions to saved or discarded. Record-level LWW plus
tombstones remain the conflict model; field-level merge is out of scope.

#### Scenario: Inbound update during typing
- **WHEN** the user is editing a move's notes (machine dirty) and a realtime update for
  that move arrives
- **THEN** the visible draft is unchanged, and after save or discard the held update is
  reconciled via LWW

#### Scenario: Held update applies after save
- **WHEN** the user saves the draft that was shadowed by a held inbound update
- **THEN** LWW resolves deterministically by `updatedAt`, both devices converge to the same
  record, and no write is silently dropped
