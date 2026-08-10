# Tasks — Add Design-System Showcase Page

> **Language: Dart (Flutter Web, the #1 product surface).** Depends on:
> `enforce-face-law-conformance`, `add-color-packs`, `add-icon-system-and-packs`.
> Implementation in a fresh student session — never this one.

Ledger rule: tick in the same commit that lands the work. Binary truth: no tick
without terminal-verified evidence (analyze/test/build output). This page reads
existing tokens — it must not introduce a single raw literal.

## Phase 1: Scaffold + variant rail
- [ ] 1.1 Add the showcase `AppScreen` (column form) with a sticky variant rail
      (brightness × accessibility palette) that re-renders the color region in place
- [ ] 1.2 Wire the rail to the existing pack/brightness/overlay providers so the page
      resolves real token values under every variant

## Phase 2: Live token regions (parallelizable)
- [ ] 2.1 Color region — all 17 roles × 3 palettes × both brightnesses as inline
      `[role | hex | swatch]` tiles; learning states + review actions as pill triples
- [ ] 2.2 Typography region — full scale + 5 font families as `[style | size/weight | sample]` rows
- [ ] 2.3 Spacing + radius region — adjacent `[name | value | visualized]` rows
- [ ] 2.4 Depth + shadows region — `[level | params | raised-card]` triples
- [ ] 2.5 Layout region — four-band frame diagram + `AppLayout` constant table
- [ ] 2.6 Motion region — Fluid + Morph families, durations + curves with a replay
      affordance

## Phase 3: Conformance + validation
- [ ] 3.1 Confirm zero raw color/spacing/radius/duration/curve literals in the feature
      (the page showcasing itself incorrectly is the defect it exists to prevent)
- [ ] 3.2 Add render + variant tests: the page mounts under every brightness × palette
      combo; samples resolve from real constants
- [ ] 3.3 Run focused Flutter tests + analyzer; web build green
