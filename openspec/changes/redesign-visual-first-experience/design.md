# Design — Visual-First Experience

## View-mode architecture

One datasource, three presentations. `ViewMode { glance, scan, study }` replaces
`{ list, grid }`; each mode is its own sliver family fed by the same provider chain
(no per-mode queries). Ordering in the toggle is fixed easiest → hardest seeing:

| Mode | Successor of | What it optimizes | Density |
| --- | --- | --- | --- |
| Glance | `grid` ("Gallery") | recognizing by footage — big thumbnails, duration badge, nothing else | lowest cognitive load |
| Scan | `list` ("List") | finding by name — dense rows, name + state pill | mid |
| Study | new | understanding — card w/ inline playback, counts, category, notes preview | highest |

Persistence stays on the existing `arsenal_view_mode` SharedPreferences key; legacy values
migrate on first read (`grid`→`glance`, `list`→`scan`) so no user loses their choice.
`_ViewModeToggle` becomes a 3-segment control cycling in fixed order.

## Membership resolution in the picker

The picker already walks device assets; membership is a single indexed lookup of the asset's
`contentHash` against moves (hash already stored per move). Compute lazily per visible tile
(the grid is virtualized) and cache per sheet-open. Tile = exactly 4 slots; a missing fact is
omitted, never substituted with more text.

## Motion doctrine

Two families, both already expressible with existing `AppMotion` tokens — the doctrine names
and enforces them rather than adding a system:

- **Fluid** — entrance/exit/attention: opacity + translation only, `productive`/`entrance`
  curves, durations `fast01`–`moderate02`. Default for everything.
- **Morph** — continuity of identity: shape/size/position morphs (container transforms,
  shared-element feel), `springGentle`. Reserved for state changes of one persistent element.

`flutter_animate` stays, constrained to family recipes. `springBouncy`/`expressive` remain
tokens but require a justified call-site comment (delight budget, see `delight` passes).
Review checklist gains: "motion composes from AppMotion family tokens; controllers disposed."

## WYSIWYG review layout

The card lays out as a fixed vertical budget (media, prompt, rating row) computed from the
viewport — not a scroll view. Overflow (long notes) collapses behind an explicit expand
affordance; scrolling appears only when a real content-overflow problem is being solved,
never as the default. Radius: `AppRadius.xxs` (4) for card surfaces; thin bars keep raw 2.
