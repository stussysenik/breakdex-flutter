# release-hygiene

## ADDED Requirements

### Requirement: User-facing GUIDE.md ships and stays current

The repo SHALL maintain a user-facing `GUIDE.md` covering, per platform: how to get the app, how
updates arrive, when a reinstall or migration is needed, how to back up/export data, and how to
leave with your data. Any release that changes one of those answers SHALL update GUIDE.md in the
same release.

#### Scenario: Release changes update behavior
- **WHEN** a release changes how users install or update on a platform
- **THEN** that release's GUIDE.md reflects the new procedure

### Requirement: Monotonic versioning and per-release notes

Every release across all platforms SHALL carry a single monotonic build number and a
human-readable `MAJOR.MINOR.PATCH` version, with a `CHANGELOG.md` entry describing user-visible
changes. The remote-config `minSupportedBuild` SHALL reference these build numbers as the
retirement lever for old builds.

#### Scenario: Two platforms, one ordering
- **WHEN** a web release and a later iOS release ship
- **THEN** the iOS build number is strictly greater and both appear in CHANGELOG.md

### Requirement: Staged platform rollout

Releases SHALL roll out web first; iOS and then Android follow only after the web release meets a
defined stabilization bar. Each platform's rollout reuses the same backend, entitlements, and
config — one product, staged by platform risk.

#### Scenario: Mobile waits for web soak
- **WHEN** the web release has not yet met the stabilization bar
- **THEN** no store build is distributed beyond internal testing
