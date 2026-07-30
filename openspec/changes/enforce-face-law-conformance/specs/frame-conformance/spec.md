# Frame Conformance

## ADDED Requirements

### Requirement: Every feature screen lives inside the AppScreen frame

Feature screens SHALL render inside the `AppScreen` four-band frame. A `Scaffold`,
`AppBar`, or `SliverAppBar` constructed under `lib/features/` outside the conformance
allowlist SHALL fail `test/core/design/layout_conformance_test.dart`. The allowlist SHALL
only shrink: a listed file that no longer violates fails a second assertion until removed.
The migration order lives in `docs/design/TOKENS.md` (Layout & Grid).

#### Scenario: New screen built with a raw Scaffold

- **WHEN** a new feature screen constructs its own `Scaffold`
- **THEN** the conformance test fails and the screen is rebuilt on `AppScreen`

#### Scenario: Migrated screen left on the allowlist

- **GIVEN** a screen migrated to `AppScreen`
- **WHEN** its file remains in the allowlist
- **THEN** the stale-exemption assertion fails until the entry is deleted

### Requirement: Screens compose mobile-first

Every screen SHALL be composed and reviewed at 390pt logical width first. Viewports at or
above 720pt SHALL receive the existing reading clamp and whitespace only — no
wide-viewport-only chrome, controls, or second layouts.

#### Scenario: Wide viewport adds chrome

- **WHEN** a diff introduces a control that renders only above the reading clamp
- **THEN** review rejects it; the control ships at 390pt or not at all
