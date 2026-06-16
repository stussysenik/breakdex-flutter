# web-app-shell-navigation

## ADDED Requirements

### Requirement: Persistent toolbar and sectioned navigation

The web app SHALL present a persistent top toolbar (account, sync status, and global actions) and
explicit section navigation for the major areas (Library, Combos, Journal, Plans, Stats, and
governance/export). Navigation SHALL be available from every view.

#### Scenario: Toolbar persists across sections
- **WHEN** the owner navigates between sections
- **THEN** the toolbar remains present and reflects the current account and sync status

#### Scenario: Sync status is visible
- **WHEN** edits are pending or syncing
- **THEN** the toolbar surfaces the current sync state

### Requirement: Breadcrumb navigation

The web app SHALL display breadcrumbs reflecting the current location as
`Section ▸ Subsection ▸ Item`, and each breadcrumb segment SHALL be a navigable link back to that
level.

#### Scenario: Breadcrumb reflects a deep view
- **WHEN** the owner opens a specific move inside a category
- **THEN** the breadcrumb shows the section, the category, and the item, in order

#### Scenario: Breadcrumb segment navigates up
- **WHEN** the owner clicks a parent breadcrumb segment
- **THEN** the app navigates to that level without losing session or unsaved-edit state

### Requirement: Purposeful, non-blocking animations

The web app SHALL use animations for section/route transitions, optimistic-write feedback, and
media playback affordances. Animations SHALL be purposeful and SHALL NOT block interaction or
delay data display.

#### Scenario: Transition does not block content
- **WHEN** the owner switches sections
- **THEN** the transition animates while content remains interactive and data is not delayed by the animation
