# Tighten Combo Journey & Review Polish — Planner Fixes, Beat Grid, Assess-Stage Switching, Gallery Picker

## Summary

A tightening/polish pass that makes the combo journey system (from `add-combo-journey-system`, schema v22 already landed) actually usable end-to-end, and fixes the review + media-import surfaces it connects to. Five fronts:

1. **Practice planner correctness** — planning a combo for a day silently never persisted (disposed-ref bug in the picker sheet); planned future days were painted at 5% alpha (invisible). Fix the write path, make plans visible, pre-fill the date when planning from a calendar day.
2. **Beat grid timeline** — redesign for visual weight and proportion: legible labels, beat ticks that actually align with the proportional blocks, no decorative dead elements, tappable blocks everywhere it renders.
3. **Assess-stage move switching** — in review, entering the assessment stage removed the move switcher entirely (instrument panel hidden, assessment beat grid non-interactive). The learner must be able to switch combo steps freely at any stage.
4. **Create-combo maturity** — picker sheets polished; new combos born `status='idea'`; success affordance offers "Plan it?" (completes spec task 3.7 of the journey change).
5. **Gallery video picker** — videos only (all of them, incl. iCloud), preview tiles show name/date/size+duration in a logical order, paged incremental loading with determinate import progress (no 0→100 jumps), resilient retry/timeout behavior on edge networks, and the multi-select/import-one mismatch fixed.

Plus a verification gate: export/trim video paths proven working, journal wired to review + party surfaces, simulator overflow/spacing sweep.

## Motivation

The journey system's data layer (Phase 1) is committed, and the UI phases are partially in the working tree but stale-feeling: the headline flows (plan → see it on calendar/queue → jot → evidence completes plan) break at the first step. This change retires those breaks and finishes the polish so the app can be used daily as a combo journal/planner connected to review (drill) and party (shaker) modes.

## Relationship to other changes

- **Builds on** `add-combo-journey-system` (schema v22, DAOs, detail page, tabs — Phases 1–3 partially implemented). This change completes and corrects its UI phases; its remaining storage/deep-link phases (4–5) stay in that change.
- Spec deltas here modify `practice-planner` and add `combo-review-session`, `beat-grid-timeline`, `video-gallery-picker`.

## Scope

### In scope
- Plan-a-combo flow restructure (sheet returns selection; caller owns writes)
- Calendar day visibility: heat for past activity, visible ring + count dots for planned days, pre-filled date when planning from a tapped day
- BeatGrid redesign (shared widget used by combo detail + review instrument panel + assessment stage)
- Assessment stage: interactive beat grid + persistent step switching
- Create-combo picker sheet polish + "Plan it?" affordance
- MetadataVideoPickerSheet: videos-only guarantees, metadata overlay (name · date · size/duration), paged loading UX, determinate per-stage import progress, iCloud/edge-network retry, multi-select semantics fixed
- Export/trim verification, journal↔review/party wiring verification, overflow/spacing sweep

### Out of scope
- Schema changes (v22 is sufficient; no migrations)
- Storage hygiene sweeps and Files deep-link (Phases 4–5 of `add-combo-journey-system`)
- New review modes or FSRS changes
