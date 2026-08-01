# Factory Sittings

## ADDED Requirements

### Requirement: Owner-gated work is grouped by sitting

Every owner-gated task SHALL carry exactly one sitting tag — `DEVICE` (built binary on the
owner's machine), `REVIEW` (eyes on a served surface), `DECIDE` (a decision promotion), or
`SCHOLAR` (sources a human must consume) — and `./status.sh` SHALL group open owner-gated
items by sitting at read time. The grouping is derived from ledgers, never stored; the
sitting registry is closed and grows only by owner decision.

#### Scenario: Owner sits down to review

- **WHEN** the owner runs `./status.sh`
- **THEN** open owner-gated items appear grouped by sitting, so one sitting clears one
  column

#### Scenario: Owner-gated task filed without a sitting

- **WHEN** a task is routed to `owner-verification-passes` with no sitting tag
- **THEN** the board names it as misfiled rather than leaving it to be read as work
