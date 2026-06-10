# practice-planner

## ADDED Requirements

### Requirement: Three planning entry points
The system SHALL allow creating a plan from: (1) an existing combo's ⋯ sheet ("Plan for a day…"), (2) the Planned tab's "Plan a combo" action (choose existing, or create a new combo then plan it), (3) a future day on the Calendar tab ("+ Plan"). All three write the same `combo_plans` row.

#### Scenario: Plan a brand-new combo at creation
- **WHEN** a user creates a new combo
- **THEN** the success flow offers "Plan it?" and accepting schedules it for a chosen day as `status='idea'`

### Requirement: Ordered practice queue
The Planned tab SHALL show pending plans as a numbered sequence ordered by (planDate, position). The user SHALL be able to reorder within the queue, persisting `position`. Each queue row SHALL show the combo name and a one-line *why* derived from its latest journal/status evidence (e.g. "0/6 takes Monday — entry drill first").

#### Scenario: Reorder persists
- **WHEN** the user moves queue item 3 to position 1 and relaunches the app
- **THEN** the queue order is preserved

### Requirement: Calendar planning view
The Calendar tab SHALL render past days with activity heat (derived from the journal ledger) and future days with planned-combo indicators (dashed ring + count dots). Tapping a past day shows that day's practiced combos and facts; tapping a future day shows its plans and the "+ Plan" action. Today SHALL be visually marked.

#### Scenario: Past and future are distinguishable
- **WHEN** the calendar renders June with practice on the 10th and plans on the 14th
- **THEN** the 10th shows heat fill and the 14th shows a dashed ring with plan dots

### Requirement: Evidence-based completion
A plan SHALL be marked complete (`completedAt`) when journal evidence exists for its combo on its planned date. Completion SHALL never be inferred without evidence and SHALL never delete the plan row. A progress strip on the Planned tab SHALL show only ledger-derived numbers (last session results, sessions this week, landed count).

#### Scenario: Practicing completes the plan
- **WHEN** "Saturday Run" is planned for Jun 14 and the user jots on it on Jun 14
- **THEN** the plan shows complete and remains in history

#### Scenario: No invented stats
- **WHEN** the progress strip renders
- **THEN** every number is reproducible by a documented query over `combo_note_entries`/`combo_plans`
