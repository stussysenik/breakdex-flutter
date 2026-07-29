# Owner Verification

## ADDED Requirements

### Requirement: Agent-unclosable tasks are routed, not parked

Agent-unclosable tasks SHALL be recorded in the `owner-verification-passes` change rather
than left unticked in their originating change. A task is agent-unclosable when it requires
a physical device, owner credentials, or a hosting console. The originating change SHALL
record where its verification went, and MAY then archive as implementation-complete.

#### Scenario: A gated task is written

- **WHEN** a task is authored that needs a device, owner credentials, or a console
- **THEN** it is placed in `owner-verification-passes` at authoring time, grouped by the
  sitting it requires, and the originating change references it instead of carrying it

#### Scenario: A change is otherwise complete

- **WHEN** every remaining task in a change is agent-unclosable
- **THEN** that change archives as implementation-complete, naming
  `owner-verification-passes` as the home of its outstanding proof

### Requirement: Only the owner ticks owner-verification boxes

No agent SHALL tick a checkbox in `owner-verification-passes`. A green gate, a passing
suite, and a successful build are not substitutes for the proof these tasks demand.

#### Scenario: An agent is tempted to infer verification

- **WHEN** an agent observes that tests and builds pass for a gated behavior
- **THEN** the corresponding owner-verification box remains unticked, because the gate
  explicitly does not prove device behavior

### Requirement: The change is exempt from staleness

`owner-verification-passes` SHALL NOT be reported as STALE by queue triage regardless of age.
It is a durable checklist bound to the owner's session cadence, not an in-flight change.

#### Scenario: Triage encounters a long-idle checklist

- **WHEN** queue triage evaluates `owner-verification-passes` after a long idle period
- **THEN** it reports the change as owner-gated rather than prompting a keep-or-kill decision
