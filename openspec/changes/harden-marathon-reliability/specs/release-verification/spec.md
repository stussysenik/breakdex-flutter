# Release Verification

## ADDED Requirements

### Requirement: Three-platform E2E matrix

The release SHALL be verified by an E2E matrix runnable with one command per platform:
Patrol journey suites (add, review, sync, library, party) on iOS and Android, Maestro smoke
flows retained as the fast black-box layer, and a Playwright smoke for Flutter Web. The
matrix result SHALL be the wave-1 invite gate for
`add-web-first-release-and-monetization` Phase 4.

#### Scenario: Matrix green gates the invite wave

- **WHEN** all three platform suites pass on release candidates
- **THEN** the wave-1 gate is satisfied and the result (versions, platforms, timestamps) is
  recorded in the release notes

#### Scenario: Journey failure blocks release

- **GIVEN** a failing Patrol journey on any platform
- **WHEN** the matrix runs
- **THEN** the release does not proceed and the failing journey identifies the broken flow

#### Scenario: One command per platform

- **WHEN** a developer runs the documented platform command
- **THEN** the full suite for that platform executes without manual orchestration
