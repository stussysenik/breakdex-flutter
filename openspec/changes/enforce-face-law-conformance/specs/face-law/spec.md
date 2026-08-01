# Face Law

## ADDED Requirements

### Requirement: Chrome essentialism is stated as checkable claims

The Face Law SHALL consist of rules a reviewer or a test answers yes/no on a diff: every
screen is the one `AppScreen` frame; each content band carries at most one primary action;
monochrome carries the interface and color marks state only; a control shows the value it
holds, not only its name; chrome dimensions resolve from `AppLayout`/TOKENS.md tokens.
Adjectival design guidance ("clean", "minimal") SHALL NOT be added to the doctrine.

#### Scenario: Diff adds a second primary action to a band

- **GIVEN** a screen whose content band already carries a primary action
- **WHEN** a diff adds another primary-emphasis control to the same band
- **THEN** review flags it and the diff demotes one action or splits the surface

#### Scenario: Control named without its value

- **WHEN** a chrome control renders only its noun where a current value exists
- **THEN** review flags it and the control is rewritten to show the value it holds

### Requirement: A new chrome control displaces one

A diff that grows a screen's chrome control count SHALL name the control it displaced, or
state in the change ledger why the count grew. Control count per screen SHALL be countable
from the diff.

#### Scenario: Control added with displacement stated

- **WHEN** a diff adds a chrome control and names the control it removed
- **THEN** the diff passes this check with no further argument

#### Scenario: Control added silently

- **WHEN** a diff grows chrome control count with no displacement and no stated reason
- **THEN** review rejects the diff until the reason is on the record
