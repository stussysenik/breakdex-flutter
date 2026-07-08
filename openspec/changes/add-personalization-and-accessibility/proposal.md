# Add Personalization & Accessibility Foundations

## Why

The product should let a user see themselves in it: rename the core nouns ("Moves",
"Combos"), pick typography, choose the order their flow happens in, and use the app with
color-blindness or a need for a non-stimulating interface. Today: typography customization
already exists (`AppFontFamily` in `lib/core/design/typography.dart:7`, 6 fonts, wired via
`fontFamilyProvider`), a partial naming control exists (Settings → "Global Labels" renames
the Arsenal title only), the add flow has one fixed step order, party mode defaults OFF
(`AppMode.fromString` falls back to `anki`), there is **zero i18n infrastructure** (no
`flutter_localizations`, no `.arb`, all text hardcoded English), and no color-blind or
monochrome theme exists. Settings (`settings_screen.dart`, 1771 LOC) mixes concerns inside
its three sections and the rescoped `add-quiet-playback-and-senior-drill-ui` already owes it
a dedup pass.

Owner rulings (2026-07-08): party mode is the default experience for fresh installs;
customization must be visually self-confirming (change it, leave, see it — no save
ceremony); accessibility takes Carbon Design System / React Aria as quality references,
expressed in Flutter idioms.

## What Changes

- **Parametric entity naming**: extend the existing Global Labels control so the user can
  rename the "Moves" and "Combos" data-banks; the chosen nouns render everywhere the defaults
  appear (tabs, titles, empty states, dialogs). Long-name resilience rides
  `tighten-athlete-controls-and-stats-clarity`.
- **Flow-order preference**: a toggle choosing where the video editor sits in the add flow —
  edit-after-metadata (today) or edit-while-adding (straight into the editor from the picker).
  Same logic, reordered steps.
- **Party default ON**: fresh installs default to `AppMode.party`; existing users keep their
  persisted choice untouched (data-safety: never override a stored preference).
- **Settings IA reorder + live feedback**: regroup Settings so each section carries one
  concern (Practice, Appearance, Library & Data, System/Sync); consolidate the quiet-mode /
  review-composer panels (absorbing the rescoped `add-quiet-playback-and-senior-drill-ui`
  Phase 4); every customization applies live and is visible on the settings row itself
  (preview swatch/specimen), no save button.
- **Accessible themes**: a color-blind-safe palette mode (deuteranopia-safe ramp; meaning
  never carried by color alone — states pair icon/shape) and a monochrome non-stimulating
  mode (grayscale surface ramp). Both are theme-level variants in `lib/core/design/`,
  distinct from the existing `ViewingMode.monoOutline` render style.
- **i18n foundation**: `flutter_localizations` + `gen-l10n` + English ARB as the base;
  extraction sweeps the shell + the top five screens first; all NEW strings must go through
  l10n from the moment the foundation lands. Full extraction of ~376 files is phased, not
  big-banged.

## Capabilities

### New

- `personalization-controls`: parametric naming, flow-order preference, party default,
  settings IA with live-applying, self-confirming customization.
- `accessible-themes`: color-blind-safe and monochrome theme variants; color never the sole
  carrier of meaning.
- `i18n-foundation`: localization infrastructure with phased string extraction.

## Footprint estimate (quantized against 2026-07-08 survey)

| Surface | Today | After | Delta |
| --- | --- | --- | --- |
| `settings_screen.dart` | 1771 | ~1500 + 2 section files (~500) | +230 net, split for ownership |
| Naming plumbing (label provider + render sites) | partial | ~25 call sites | +150 |
| Add-flow order toggle | — | routing + 1 pref | +80 |
| `colors.dart`/`theme.dart` (2 variants) | 45/521 | ~90/~640 | +165 |
| l10n infra + ARB (shell + top 5 screens ≈ 250 strings) | 0 | l10n.yaml, app_en.arb, gen wiring | +~900 (mostly ARB/generated) |
| Tests | — | — | +~350 |

Net: ~+1,600 LOC (≈60% ARB/generated), no new runtime dependencies beyond
`flutter_localizations` (SDK).

## Non-goals

- No second language shipped (foundation + English base only; translations are content work).
- No re-theming of the studio (`web-mirror/` follows separately via tokens.css conformance).
- No new fonts (the 6 in `AppFontFamily` stand).
