# Clarify Review Loop, Media Cleanup & Color Customization — Design

## Review Loop

### Due-only launcher model
State-based review should launch from cards that are due now, not from total counts per state. The prescreen still groups cards into NEW / LEARNING / MASTERY, but those counts represent the due subset for the current moment.

### Missing-card fallback
Moves or combos created during the current app session may not yet have an `fsrs_cards` row. The review launcher treats those entities as `New` and due now so they remain immediately drillable.

### Single-card reveal flow
The active review session presents one centered card at a time. Before reveal, the learner sees the prompt/state summary only. After reveal, the video and assessment controls appear. This removes the `PageView` preview affordance and aligns the interaction model with an Anki-style "reveal, then assess" loop.

### Scheduler behavior
The FSRS learning-step default is shortened to a single reinforcement step so cards do not feel trapped in learning during the first repetitions.

## Sync & Media Cleanup

### FSRS as source of truth
`fsrs_cards` is the authoritative review-state source. After remote sync pull, `moves.learningState` is reconciled from FSRS so Arsenal rows and other legacy UI surfaces stay consistent.

### Pending upload preservation
`sync_log.videoSynced` must not be reset to `true` by later metadata-only writes for the same entity/action row. Sync logging updates preserve an existing pending video upload.

### Delete cleanup
Deleting a move or combo removes:
- local file
- local thumbnail
- remote uploaded object during sync delete push

Native Photos album cleanup is not guaranteed for all historical assets because current app-managed metadata is insufficient to identify every existing copy deterministically.

## Settings Colors

### Reusable editor
Color editing is centralized into one reusable settings control/dialog so accent, rating, and category color paths share the same persistence and UI behavior.
