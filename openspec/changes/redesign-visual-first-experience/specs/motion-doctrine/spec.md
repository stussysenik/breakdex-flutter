# Motion Doctrine

## ADDED Requirements

### Requirement: Exactly two motion families

All product motion SHALL belong to one of two families composed from `AppMotion` tokens:
**Fluid** (opacity/translation on `productive`/`entrance` curves, durations
`fast01`–`moderate02`) as the default, and **Morph** (shape/layout continuity of a persistent
element on `springGentle`) reserved for state changes of one identity. Raw curve or duration
literals outside the token set SHALL be treated as review violations.

#### Scenario: New animation composes from family tokens

- **WHEN** a new animated transition is added to a product surface
- **THEN** its curve and duration resolve from `AppMotion` tokens within one family

#### Scenario: Non-conforming motion found in review

- **GIVEN** a diff introducing a raw `Duration`/`Curve` literal driving visible motion
- **WHEN** the change is reviewed against the checklist
- **THEN** it is flagged and rewritten onto family tokens before merge

### Requirement: Motion resources are lifecycle-safe

Every `AnimationController` (and any ticker-backed resource driving motion) SHALL be disposed
with its owning widget. Motion SHALL remain deterministic: the same state transition always
produces the same animation (step-based, no wall-clock dependence beyond token durations).

#### Scenario: Controller disposal on unmount

- **GIVEN** a widget owning an animation controller
- **WHEN** the widget unmounts
- **THEN** the controller is disposed and no ticker leaks (verifiable in the marathon soak of
  `harden-marathon-reliability`)

#### Scenario: Deterministic replay

- **GIVEN** the same state transition fired twice
- **WHEN** its animation runs
- **THEN** the same family recipe (curve, duration, direction) plays both times
