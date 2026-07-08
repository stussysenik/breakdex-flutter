# Device Diagnostics

## ADDED Requirements

### Requirement: Deterministic per-device status checks

The app SHALL provide a system status page of individually-run, deterministic checks, each
rendering as a pass/fail/degraded bullet with a one-line diagnosis. The check set SHALL cover
at minimum: database open + migration level, storage free space, media library permission,
Drive auth + reachability, backend reachability + remote-config fetch, sync queue depth +
last success time, video pipeline (thumbnail + playback probe), and app identity (build
number, config cohort, device platform). Checks re-run on page entry and on demand.

#### Scenario: All-green device

- **WHEN** a healthy device opens the status page
- **THEN** every check renders as passing with its measured value (e.g. queue depth 0,
  last sync time)

#### Scenario: A failing part is isolated

- **GIVEN** Drive auth has expired
- **WHEN** the status page runs its checks
- **THEN** the Drive check renders failed with a one-line diagnosis while unrelated checks
  still pass — the failing part is identifiable without reading logs

#### Scenario: Deterministic re-run

- **WHEN** the user re-runs checks without changing device state
- **THEN** the same results render (no flaky pass/fail flapping)

### Requirement: Diagnostic report is exportable

The full check report SHALL export as a redacted JSON bundle (check results, measured values,
app/build/cohort identity, platform — no tokens, no user content) shareable through the
platform share sheet so a remote debugger can read the device's state.

#### Scenario: Export and share

- **WHEN** the user exports the diagnostic report
- **THEN** a JSON bundle with all check results and identity fields (secrets and user content
  excluded) is produced and shareable

#### Scenario: Report is honest about staleness

- **WHEN** the report exports
- **THEN** it carries the timestamp of the check run it describes
