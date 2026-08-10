# Tighten Athlete Controls & Stats Clarity - Design

## 1. Move Detail As The Primary Correction Surface

The move detail screen already contains the current video, name, state, and category. It should also be the fastest place to correct those attributes.

### Review state
- The current state pill becomes an explicit quick-edit control
- Tapping it opens the existing manual state picker
- Choosing `New` must act as a real reset path, not a hidden review-only override

### Category
- The current category badge becomes an explicit quick-edit control
- The category sheet must never dead-end
- If the required category does not exist, the sheet offers `Add category`
- Adding a category should return its name so it can be applied immediately in the same flow

This reduces both scrolling and tap count compared with burying these actions deep in lower action lists or settings screens.

## 2. Overlap-Safe Shared Components

Several reusable surfaces assume short labels. They need a stricter layout contract.

### Action tiles
- Reserve trailing chevron space explicitly
- Let the text region flex and ellipsize instead of competing with trailing affordances
- Keep a large touch target regardless of label length

### State pills
- Support optional tap behavior without changing the non-interactive surfaces
- Clamp label rendering to one line with ellipsis

### Move rows and stats rows
- Move metadata should stack or wrap under the title instead of forcing everything into one horizontal lane
- Secondary metadata can wrap; the primary subject should remain stable and readable

## 3. Subject-First Stats

The athlete should see what they are training before reading the aggregate.

### Hierarchy
- In card mode, surface reviewed subjects high in the screen using the existing `TopMovesList`
- Keep the summary cards, but flip them to label-first/value-second styling
- Make the "moves / combos" summary read as review subjects instead of a split ratio widget

### Information density
- Subject lists stay compact and scannable
- Summary copy is shorter and quieter
- Secondary metadata uses wraps to avoid truncation collisions

## 4. Flow Graph Label Hardening

The current graph label placement uses a fixed 80px rectangle. That is too blunt for custom move names and dense maps.

### Change
- Measure each label using the same paragraph style used for drawing
- Build collision rects from actual measured width/height plus small padding
- Clamp placement inside the canvas bounds
- Keep the existing priority rules so mastery and explicitly selected nodes still win

This is an incremental correctness pass, not a new layout engine.

## Validation

- Widget tests for the touched reusable widgets and stats hierarchy
- Focused analyzer run on touched files
- Manual sanity check for move-detail quick edits and graph readability if automated coverage is limited
