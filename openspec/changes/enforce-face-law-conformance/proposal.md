# Enforce Face Law Conformance

## Why

Owner ruling (2026-07-30): one loss-function pass over the UI before launch — consistent,
essentialist, mobile-first, native-feeling per platform. The doctrine already exists; the
enforcement does not. The measurement: **26 files under `lib/features/` build a raw
`Scaffold`; 1 uses `AppScreen`** — the stacked-viewport doctrine (locked 2026-07-29,
CLAUDE.md → Layout doctrine) is written but unenforced. Icons and colors have machine gates
(`icon_conformance_test.dart`, `color_conformance_test.dart`); layout, density, and chrome
essentialism are still an honor-system review checklist.

Valoric's factory closed this same gap and Breakdex inherits the pattern (parity audit
2026-07-30): valoric names a **Face Law** standing bar and gates its token scale by script
(`ds/verify_ds.sh`); it groups owner-gated items by **sitting** (DEVICE / REVIEW / DECIDE /
SCHOLAR) so the owner clears a column once instead of context-switching per change; it
carries the **"professional tool, not a hobbyist toy"** bar. Breakdex's FACTORY.md
(2026-07-27 port) predates all three.

The reference aesthetic is the Light Phone: an interface that earns trust by subtraction —
monochrome carries, type is the interface, every control visibly justifies its slot. That
bar must live in the repo as checkable rules, not as taste in a transcript, so any executor
session (Opus, Gemini) applies it identically without this conversation.

## What Changes

- **Face Law codified**: a named standing bar in `docs/manual/FACTORY.md` and a doctrine
  row in `CLAUDE.md` — the essentialist rules stated as checkable claims (one frame, one
  primary action per content band, monochrome carries / color marks state, a control shows
  its value, a new chrome control displaces one or the diff says why).
- **Frame conformance gated**: new `test/core/design/layout_conformance_test.dart` — a raw
  `Scaffold` / `AppBar` / `SliverAppBar` under `lib/features/` outside a seeded allowlist is
  a failing test, same shape as the color gate. The allowlist starts at today's 26 files and
  only shrinks; the migration ledger stays in `docs/design/TOKENS.md` → Layout & Grid.
- **One-frame migration pass**: the raw-Scaffold feature screens move onto `AppScreen`,
  product surfaces first, each batch shrinking the allowlist in the same commit. Composed
  mobile-first (390pt logical width); ≥720pt gets the existing reading clamp; desktop adds
  space, never new chrome.
- **Platform-native adaptation**: scroll physics, back gesture, and safe-area behavior come
  from platform defaults (Flutter adaptive constructs), never re-implemented; a platform gap
  degrades visibly (the `Scene3DView` shape: name the gap, render the gap). iOS/Android
  releases inherit the same frame with zero per-screen forks.
- **Factory parity with valoric**: FACTORY.md gains the Face Law bar and the
  professional-tool bar; `./status.sh` groups owner-gated items by sitting so an owner
  review session clears a column in one sitting.

## Capabilities

### New

- `face-law`: essentialist chrome rules stated as checkable claims and wired into the
  review checklist and factory manual.
- `frame-conformance`: machine gate holding every feature screen inside the `AppScreen`
  four-band frame, with a shrink-only allowlist.
- `platform-adaptation`: native-feel by platform defaults, visible degradation for gaps,
  one frame across web/iOS/Android.
- `factory-sittings`: owner-gated work grouped by sitting on the derived board.

## Footprint estimate

| Surface | Current | Target |
|---|---|---|
| `lib/features/**` raw `Scaffold` files | 26 | 0 outside allowlist; allowlist → 0 by pass end |
| `test/core/design/layout_conformance_test.dart` | 0 | ~120 LOC (new) |
| `docs/manual/FACTORY.md` | 180 lines | ~205 (Face Law + sittings + professional-tool bar) |
| `CLAUDE.md` | — | +1 doctrine row (Face Law) |
| `status.sh` | — | +~40 lines (sitting grouping, derived only) |
| `docs/design/TOKENS.md` | migration ledger present | updated in place per batch |
| Screen migrations | 1 screen on `AppScreen` | ~20 screens; net-negative LOC per screen expected |

## Non-goals

- No visual redesign of content surfaces — that is `redesign-visual-first-experience`;
  this change moves frames and chrome, not what the content band says.
- No new design tokens, no token codegen, no theming expansion.
- No desktop-specific chrome — wider viewports get the reading clamp and whitespace only.
- No self-certified visual judgment — owner review remains the only visual gate; batches
  route to `owner-verification-passes` per queue doctrine.
- No per-platform UI forks — adaptation is platform defaults plus visible degradation,
  never a second layout.
