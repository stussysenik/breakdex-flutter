# files-deeplink

## ADDED Requirements

### Requirement: Open-in-Breakdex registration
The app SHALL register as a viewer for `public.movie` documents (both debug and release Info.plists — note the dual-plist gotcha) with documents-in-place disabled, so Breakdex-owned videos opened from the Files app hand off to Breakdex.

#### Scenario: Files hand-off
- **WHEN** the user opens a `.mp4` from Files via "Open in Breakdex"
- **THEN** the app receives the URL through the standard open-URL entry point

### Requirement: Resolve to the owning entity
An incoming video URL SHALL be resolved by content hash (fast-hash first, full hash fallback) against `moves.contentHash` / `asset_manifest`, with filename match as last resort. A move match SHALL navigate directly to that move's detail (`/moves/{id}`); a take linked in a combo journal SHALL navigate to that combo positioned at the relevant step. The user SHALL land on the actual video — not a generic moves or combos list.

#### Scenario: Move video opens its move
- **WHEN** the opened file's hash matches the Windmill move
- **THEN** the app navigates straight to Windmill's detail with its video front and center

#### Scenario: Unmatched file offers import
- **WHEN** the opened file matches nothing in the database
- **THEN** the app offers the existing import flow with that file pre-selected, and never silently drops the intent

### Requirement: Resolution diagnostics
Every deep-link resolution SHALL log URL receipt, hash computation, match result, and navigation target via StageLogger.

#### Scenario: Failed resolution is debuggable
- **WHEN** resolution fails on a physical device
- **THEN** logs show which stage failed (hash, lookup, or navigation) without a debugger
