# Developer Docs

## ADDED Requirements

### Requirement: MDX documentation lives with the studio and builds in CI

The studio (`web-mirror/`) SHALL host an MDX documentation surface covering the system's
load-bearing seams — `SyncBackend` contract, `Machine<S,E>` state architecture, design tokens
(`docs/design/TOKENS.md` as source), and the sync/LWW + dirty-guard model — plus operational
runbooks for release, provisioning, and diagnostics-export triage. The docs SHALL build as
part of the studio's `next build`, so broken docs break the build.

#### Scenario: Docs build with the studio

- **WHEN** `next build` runs for the studio
- **THEN** the MDX docs compile as part of it, and a broken doc fails the build

#### Scenario: A seam change updates its doc

- **GIVEN** a change altering the `SyncBackend` contract
- **WHEN** it is reviewed
- **THEN** the corresponding MDX page is updated in the same change (agent-facing
  documentation rule)

#### Scenario: Runbook answers an operational question

- **WHEN** a technician receives an exported device-diagnostics bundle
- **THEN** the triage runbook documents how to read it and which check maps to which
  subsystem
