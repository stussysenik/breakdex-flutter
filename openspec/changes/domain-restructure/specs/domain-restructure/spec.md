## ADDED Requirements

### Requirement: Domain-oriented source map
The Flutter source tree SHALL define a documented domain-oriented map for product areas:
moves, combos, sets, backup/media, sync, auth, kernel, and shared UI.

#### Scenario: Fresh developer locates product code
- **WHEN** a developer needs to change a product behavior such as move creation, combo
  planning, backup health, sync status, or authentication
- **THEN** the documented source map names the owning domain folder and the legacy paths
  that still exist during migration

### Requirement: Behavior-preserving file moves
Domain restructuring MUST preserve runtime behavior and public API semantics.

#### Scenario: Mechanical move batch
- **WHEN** a batch moves files into the domain-oriented structure
- **THEN** imports are updated mechanically and `flutter analyze` exits with zero errors

### Requirement: Compatibility during migration
The system SHALL keep temporary compatibility exports or adapter files when removing them
in the same batch would create excessive review risk.

#### Scenario: Hot import remains reachable
- **WHEN** a frequently imported legacy path is moved
- **THEN** either all imports are updated in the same batch or a deprecation export keeps
  the old import reachable until a later cleanup task removes it
