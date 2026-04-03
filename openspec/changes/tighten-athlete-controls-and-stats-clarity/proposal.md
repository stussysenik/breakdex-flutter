# Tighten Athlete Controls & Stats Clarity

## Summary

Reduce friction on the highest-frequency Breakdex flows by moving review-state and category changes closer to the move itself, eliminating avoidable layout collisions, and reordering stats so the subject of training is visible before abstract numbers. This change also hardens the flow graph label placement so dense graphs remain legible instead of visually fighting themselves.

## Motivation

Breakdex currently makes athletes travel too far to make simple corrections:
- resetting or changing a move's review state is buried inside review-only flows
- category changes dead-end if the needed category does not exist yet
- several shared rows still assume short labels and can collide when names are customized
- stats lead with numbers instead of the training subject
- graph labels use fixed boxes, so dense maps can overlap or discard information too bluntly

The product should behave more like a training instrument: fewer taps, less scrolling, and clearer subject-first feedback.

## Scope

### In scope
- Add top-of-move quick controls for review state and category
- Allow category creation from the move-detail change-category flow without sending the user to Settings
- Make shared row/pill layouts resilient to long names and customized labels
- Promote subject-first stats by surfacing reviewed entities earlier and softening number-first cards
- Improve flow-graph label measurement and collision handling
- Focused tests plus analyzer on touched files

### Out of scope
- Full stats/journal redesign
- New review scheduling rules
- Full graph algorithm replacement
- Global settings IA rewrite

## Capabilities

1. `quick-move-state-reset` - a move can be reset or reassigned from its own detail surface
2. `inline-category-creation` - a missing category can be created and applied in one flow
3. `overlap-safe-shared-rows` - long labels do not collide with chevrons, pills, or metadata
4. `subject-first-stats` - stats highlight what is being trained before emphasizing totals
5. `graph-label-hardening` - flow labels use measured bounds instead of fixed boxes

## Research Notes

- Apple recommends 44x44pt minimum hit targets, placing controls close to the content they modify, and avoiding text overlap.
- Strava's Training Log and Athlete Intelligence both keep the training subject adjacent to the relevant stats rather than hiding it behind abstract totals.
- WHOOP's Journal keeps interaction efficient by reducing unnecessary inputs and surfacing personalized behaviors close to the daily context.
- TrainingPeaks emphasizes at-a-glance trend views with configurable time windows and chart interaction, which is a useful model for subject-first analytics rather than pure count dashboards.
