# Platform Adaptation

## ADDED Requirements

### Requirement: Native feel comes from platform defaults

Scroll physics, back gestures, safe areas, and text scaling SHALL come from platform
defaults as Flutter surfaces them, applied once at the frame level. Per-screen platform
forks and custom re-implementations of platform behaviors SHALL NOT be added.

#### Scenario: Custom scroll physics found on a product surface

- **WHEN** a feature screen overrides scroll physics to imitate a platform
- **THEN** the override is deleted and the platform default is restored

### Requirement: A platform gap degrades visibly

A capability missing on a platform SHALL name itself on the surface (the `Scene3DView`
shape: name the gap, render the gap) and SHALL be enumerated in
`docs/manual/07-platform-seams.mdx`. Silent degradation is a defect regardless of gates.

#### Scenario: Feature unavailable on web

- **WHEN** a surface renders on a platform missing one of its capabilities
- **THEN** the surface states the gap in place, in neutral chrome voice
