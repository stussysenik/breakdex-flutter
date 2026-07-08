# Startup Performance

## ADDED Requirements

### Requirement: Measured cold-start budgets

Cold start SHALL reach an interactive library within 2.5 seconds on a mid-tier reference
phone, and Flutter Web SHALL reach interactive within 5 seconds on broadband. Budgets are
enforced by measurement (startup trace marks recorded per release build), not by assertion.

#### Scenario: Mobile cold start within budget

- **WHEN** the app cold-starts on the reference device in release mode
- **THEN** the library is interactive within 2.5s and the measured value is recorded

#### Scenario: Web cold start within budget

- **WHEN** the Flutter Web release build loads on broadband
- **THEN** the app is interactive within 5s and the measured value is recorded

### Requirement: Heavy initialization is deferred off the first frame

Sync engines, cloud providers, and non-critical services SHALL initialize after first frame /
first interaction rather than blocking startup; the library renders from local Drift data
before any network work begins.

#### Scenario: Offline cold start

- **GIVEN** the device is offline
- **WHEN** the app cold-starts
- **THEN** the library renders from local data within budget and sync initialization defers
  silently
