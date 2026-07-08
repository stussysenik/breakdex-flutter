# Redesign Visual-First Experience

## Why

The product still explains itself with secondary text instead of visual anchors. The Add tab
(`lib/features/add/add_screen.dart`, 428 LOC) leans on helper copy; the media picker
(`lib/shared/widgets/metadata_video_picker_sheet.dart`, 762 LOC) shows "0:12 · 48 MB · Jun 8"
but gives no membership state — a user cannot tell a device-only video from one already in
Breakdex, which is the single biggest source of ambiguity in the current media experience.
The review card scrolls and uses rounded (8px) radii where the owner wants square-leaning,
one-screen WYSIWYG. The library has only 2 view modes (`ViewMode { list, grid }` in
`move_list_screen.dart:43`) where the product needs 3, ordered easiest → hardest way of seeing.
Motion is token-based (`AppMotion` in `lib/core/design/spacing.dart`) but undoctrined — any
curve/duration combination is currently legal.

Owner ruling (2026-07-08): text is for input and settings; the interface itself communicates
through visual design elements and anchors. This change is release-blocking for wave-1 invites
(`add-web-first-release-and-monetization` Phase 4 gate).

## What Changes

- **Add flow de-texted**: create choices (Move / Combo) become visual anchors — iconography,
  thumbnail, shape/color — with at most one short label each; paragraph-style helper text is
  removed. Input fields keep their text role.
- **Media grid disambiguated**: one grid covers the whole device library; every tile carries
  exactly four information slots (thumbnail+duration, display name, one secondary fact,
  membership state); videos already in Breakdex are visibly marked via `contentHash` match and
  selecting one offers the existing move instead of silently duplicating.
- **Review WYSIWYG**: the active card fits one viewport with no default scroll; surfaces move
  to the `AppRadius.xxs` (4) token; fill color becomes user-customizable by riding the
  arbitrary-color mechanism specced in `clarify-review-loop-and-media-cleanup` (not duplicated
  here).
- **Three view modes**: Glance (large media-first gallery), Scan (dense list), Study (rich
  cards with inline playback + full metadata), cycling in that order, persisted under the
  existing `arsenal_view_mode` key with legacy value migration (grid→glance, list→scan).
- **Motion doctrine**: exactly two families — **Fluid** (opacity/translation on `productive`
  curves, `fast01`–`moderate02`) and **Morph** (shape/layout continuity on `springGentle`).
  All motion composes from `AppMotion` tokens; raw curves/durations are review violations.
  Every animation controller is lifecycle-disposed (8-hour leak budget lives in
  `harden-marathon-reliability`).

## Capabilities

### New

- `visual-first-surfaces`: Add flow and media grid communicate through visual anchors with a
  hard cap on tile information and explicit membership state.
- `library-view-modes`: three ordered view modes, easiest → hardest seeing, persisted.
- `review-wysiwyg`: one-screen, square-leaning, fill-customizable review card.
- `motion-doctrine`: two motion families, token-composed, lifecycle-safe.

### Related (extended elsewhere, referenced not duplicated)

- Arbitrary color editing → `clarify-review-loop-and-media-cleanup`.
- Beat grid / count metadata → `redesign-add-tab-with-move-combo-choice` (19/27 shipped).
- Long-name-resilient rows → `tighten-athlete-controls-and-stats-clarity`.

## Footprint estimate (quantized against 2026-07-08 survey)

| Surface | Today | After | Delta |
| --- | --- | --- | --- |
| `add_screen.dart` | 428 | ~380 | −50 (copy out, anchors composed from existing widgets) |
| `metadata_video_picker_sheet.dart` | 762 | ~870 | +110 (membership lookup + 4-slot tile) |
| `move_list_screen.dart` | 1157 | ~1360 | +200 (third sliver family + 3-way toggle + migration) |
| `flashcard_review_screen.dart` + `review_card.dart` | ~1300 | ~1250 | −50 (layout compaction, radius tokens) |
| `spacing.dart` (`AppMotion`) | 78 | ~100 | +22 (family aliases) |
| Motion sweep (~15 shared widgets w/ raw controllers) | — | — | ~±0 net (token substitution) |
| Tests (goldens, mode cycling, membership, no-scroll) | — | — | +~400 |

Net: ~+250 product LOC, ~+400 test LOC. No new dependencies.

## Non-goals

- No nav restructure (5-tab shell stays), no rebrand, no new packages.
- No color-mechanism duplication (rides `clarify-review-loop-and-media-cleanup`).
