# code-ownership

## ADDED Requirements

### Requirement: Everything tracked is justified

Every tracked file, config key, and declared dependency SHALL be traceable to a business need,
a platform requirement, or a stated constraint (e.g. rendering performance). Scaffold defaults,
unused dependencies, dead code paths, and orphaned configuration SHALL be removed rather than
carried.

#### Scenario: Unused dependency
- **WHEN** a declared dependency has no import or build-time role
- **THEN** it is removed from the manifest in a sweep commit that states the removal

#### Scenario: Surviving non-obvious config key
- **WHEN** a config key's purpose is not evident from its name and context
- **THEN** it carries a one-line reason or is removed

### Requirement: Purges are pure, recoverable deletions

Ownership sweeps SHALL delete via normal commits only — never history rewrites — so any purged
file is recoverable from git history. Each sweep commit SHALL name what it purged and carry
build + test evidence of zero behavior change.

#### Scenario: Recovering a purged file
- **WHEN** a purged config turns out to be needed
- **THEN** it is restorable from git history with its full prior content

#### Scenario: Sweep commit gate
- **WHEN** a directory sweep is committed
- **THEN** the relevant builds and test suites pass in that commit, and no user-facing behavior differs

### Requirement: User data is untouchable by hygiene work

Ownership sweeps SHALL NOT rename, migrate, or delete anything that stores or names user data
(schemas, storage paths, migration files), regardless of how unowned it looks.

#### Scenario: Suspicious-looking migration file
- **WHEN** a sweep encounters an old migration or data-path constant with no obvious references
- **THEN** it is left in place and flagged for owner review instead of purged
