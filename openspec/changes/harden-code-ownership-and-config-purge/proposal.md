# Total Code Ownership & Config Purge

## Summary

A systematic, per-directory **purge + justify sweep** so the whole repo reads as owned: every
surviving file, config key, and dependency exists for a stated business or performance reason;
everything unowned (scaffold boilerplate, dead code, unused deps, orphaned configs) is **deleted,
with git history as the undo**. Zero behavior change — this pass earns trust for the outside eyes
the release invites in (`add-web-first-release-and-monetization`).

Owner intent (2026-07-08): "it should look like we own every character and keystroke in the
application — reasoned about, fitting a specific business need and constraints like rendering
speed." Deliverable shape delegated to the executor and ruled: **purge + justify, per-directory,
audit-as-you-sweep** (not a separate audit document, not a rewrite-to-idiom pass).

## Why

The app is going from private production to invited users and (later) store review. Scaffold
remnants, dead flags, and unjustified config are where bugs hide, review friction lives, and
maintenance cost compounds. LOC is a liability (core axiom); this change pays it down without
touching behavior.

## Non-negotiables

- **Zero behavior change.** Every sweep commit carries build + test evidence.
- **Pure deletions, never history rewrites.** `git rm` only; recovery is `git log --follow`.
- **Brownfield rule.** Nothing that stores, migrates, or names user data is purged or renamed.
- **No drive-by refactors.** Renames/rewrites of live logic are out of scope; only deletion and
  config-key ownership are in scope.
- **Sequencing guard.** A directory under active migration (e.g. sync internals during Appwrite
  Phases 2–4) is swept only after its migration lands; the Convex deletion (Appwrite task 2.4)
  is owned there, not here.

## Scope

### In scope
- Root configs: `pubspec.yaml` (unused deps out), `analysis_options.yaml` (every rule deliberate),
  dotfiles, `.gitignore`, CI configs.
- Platform dirs: `ios/` (project settings, Info.plists — respecting the dual-plist gotcha),
  `android/`, and the new `web/` target the release change creates.
- `web-mirror/`: `package.json` dep prune, config files, oxlint posture per repo standard.
- `lib/` + `test/`: dead files, unreferenced assets, commented-out blocks, orphaned feature flags.
- `docs/` + `openspec/`: stale docs that contradict shipped reality (folded or deleted per the
  one-roadmap precedent).

### Out of scope
- Any behavioral refactor, performance rewrite, or style migration of live code.
- User data schemas, migrations, and storage paths.

## Impact
- **New capability:** `code-ownership` (repo hygiene contract future changes must keep).
- **Leaner repo**, smaller dependency surface, configs that answer "why is this here" by
  inspection.
