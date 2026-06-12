# practice-planner

## MODIFIED Requirements

### Requirement: Plan writes happen on live state
Every plan-creation entry point SHALL perform its database write from a long-lived widget's `ref` — never from inside (or after popping) a modal sheet. Picker sheets SHALL only return the user's selection via `Navigator.pop(context, result)`. A plan write SHALL be confirmed to the user (snackbar) and SHALL appear in the queue and calendar streams without manual refresh.

#### Scenario: Plan from the Planned tab persists
- **WHEN** the user taps "Plan a combo", picks a combo from the sheet, and picks a date
- **THEN** a `combo_plans` row exists with that combo/date, the queue shows it immediately, and a confirmation snackbar appears

#### Scenario: Sheet dismissal cannot orphan the write
- **WHEN** the picker sheet has been popped and the date dialog is still open
- **THEN** completing the dialog still persists the plan (the write executes on the screen's ref, not the sheet's)

### Requirement: Calendar planning view
The Calendar tab SHALL render past days with activity heat (derived from the journal ledger) and days with pending plans — today or future — with a clearly visible ring plus up to three count dots beneath the day number. Tapping a past day shows that day's combos and facts; tapping today or a future day shows its plans and a "Plan a combo" action **pre-filled with that day's date** (no second date prompt). Today SHALL be visually marked. A legend SHALL explain heat, plan ring, and today marker.

#### Scenario: Planned day is visible at a glance
- **WHEN** a combo is planned for Jun 14 and the calendar renders June
- **THEN** the 14th shows a visible ring and one plan dot — distinguishable from empty days at arm's length

#### Scenario: Day tap pre-fills the date
- **WHEN** the user taps Jun 14 and then "Plan a combo" and picks a combo
- **THEN** the plan is created for Jun 14 without showing a date picker
