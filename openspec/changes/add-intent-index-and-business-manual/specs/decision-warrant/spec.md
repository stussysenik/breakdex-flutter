# decision-warrant Specification

## ADDED Requirements

### Requirement: A session decides when a written ruling binds, and escalates only when none does

An agent session SHALL resolve the applicable rulings before escalating a decision to the
owner. Where a standing ruling determines the answer, the session SHALL decide, state the
call and the ruling it rests on before doing the work, and proceed. Where no ruling binds,
the session SHALL escalate rather than invent one.

Sequencing a delivered scope is a session call. Changing what is in scope is not; that
remains the owner's, per the Capture rule.

#### Scenario: A standing ruling determines sequencing

- **GIVEN** `ROADMAP.md` `## NOW` names a release-blocking active change, and a standing
  owner ruling prioritizes shipping
- **WHEN** a session is handed new non-blocking work with no stated sequence
- **THEN** it queues the new work behind the active change, states that call and both rulings
  it rests on before starting, and does not park the release-blocking change

#### Scenario: No ruling binds, so the session escalates

- **GIVEN** an intent that `--docs` resolves to zero records
- **WHEN** the decision would change what gets built rather than its order
- **THEN** the session escalates to the owner rather than choosing a default

#### Scenario: A decided call is recorded with its warrant

- **WHEN** a session makes a decision under this requirement
- **THEN** its `docs/manual/session.log` line names the decision and the record that
  warranted it, so a later session can find the reasoning without the transcript

### Requirement: The escalation boundary is stated, not silently enforced

The rule SHALL declare which of its clauses are machine-checkable and which rest on review.
Whether an escalation was warranted SHALL NOT be gated by tooling; it is judgment made cheap
by intent resolution. Tooling SHALL NOT scan session logs for citation strings.

#### Scenario: The rule declares its own unenforced clause

- **WHEN** the decision-warrant rule is published in `CLAUDE.md`
- **THEN** it states plainly that the escalate-only-when-unruled clause is unenforced, and
  that intent resolution rather than a gate is what makes it reliable

### Requirement: Product and market sources ride the existing Scholar lane

`docs/manual/READINGS.md` entries SHALL carry a `domain:` field with one of
`eng | product | design | gtm | ops`. The entry format, the Scholar lane, and the Teacher
hand-off SHALL be otherwise unchanged. No parallel lane, log, or record type SHALL be
introduced for non-engineering sources.

#### Scenario: A GTM source is filed as a reading

- **GIVEN** a Scholar session studying a competitor's pricing page
- **WHEN** it records the finding
- **THEN** the entry lands in `READINGS.md` with `domain: gtm`, carrying the same source,
  mechanism-takeaway, and spec-impact lines as an engineering reading

#### Scenario: Readings are resolvable by domain

- **WHEN** an agent queries the index for a pricing intent
- **THEN** `domain: gtm` readings are among the returned records, distinguishable from
  promoted rulings so evidence is never mistaken for a decision
