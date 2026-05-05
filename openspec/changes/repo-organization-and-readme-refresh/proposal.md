## Why

The repository has accumulated auxiliary projects (Next.js web viewer, scientific research workbench, Supabase migrations) and stale root-level artifacts that dilute the focus on this being a pure Flutter application. Additionally, the README lags behind the current feature set — it omits Lab and Sync features, has stale provenance metadata, and lacks a standalone LICENSE file despite declaring ISC.

## What Changes

- Remove `web-viewer/` (Next.js app) — not part of the Flutter application
- Remove `scientific/` (Python/Julia/Lisp research) — separate R&D project
- Remove `supabase/` (database migrations) — infrastructure not needed in-tree
- Remove root-level stale images (`verify-*.png`, `review-launcher-design.png`)
- Clean iOS device UDID directories from disk (`00008130-*`, `senik/`)
- Clean stray `.env.lcoal` typo file from disk
- Update README.md: add Lab and Sync feature descriptions, refresh architecture table, update provenance metadata
- Add standalone `LICENSE` file (ISC)
- Remove `clojuredart/` — ClojureDart reference project mistakenly created in-tree; belongs in separate repo
- Remove `openspec/changes/add-clojuredart-edn-hiccup-design-system/` — stale ClojureDart migration proposal
- Add Flowdeck CLI commands and Flutter release mode commands to README

## Capabilities

### New Capabilities

- `repo-organization`: Clean root directory — remove non-Flutter auxiliary projects, stale images, and device artifacts. Establish clear file layout where only Flutter application code, platform directories, and essential tooling remain at root.
- `readme-refresh`: Update README.md to accurately describe all current features (Lab, Sync), architecture stack, and up-to-date provenance metadata.
- `license-file`: Add standalone ISC LICENSE file matching the declared license in package.json.

### Modified Capabilities

None.

## Impact

- Affected directories: `web-viewer/`, `scientific/`, `supabase/` (removed from git tracking)
- Affected files: `README.md` (rewritten), `LICENSE` (new), root `*.png` images (removed)
- No Dart code, pubspec, or build configuration changes
- No breaking changes to the Flutter application
