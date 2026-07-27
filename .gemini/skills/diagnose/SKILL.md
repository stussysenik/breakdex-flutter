---
name: diagnose
description: Run the repo's derived board and cumulative gates to answer "is everything well and done?" — use at session start, before any done-claim or handoff, or when the user asks for a health check / diagnosis of project state.
---

# Diagnose — is everything well and done?

The instruments are on disk; this skill is how to read them. Never answer a
health question from memory — run the instruments and report their output.

## Procedure

1. `./status.sh` — the derived board: active change, next unticked task, git
   state, queue size. If it disagrees with what the conversation assumes,
   the board wins (it only reads).
2. `./verify.sh --quick` — ledger, openspec-strict (active change), docs
   ledger, l10n, analyzer. ~1 minute.
3. Full `./verify.sh` (adds `flutter test`, several minutes) ONLY before a
   done-claim, a handoff, or a commit that closes a task. A done-claim on a
   `--quick` run is a §9 violation.

## Interpreting failures — map to the fix, don't restate the log

| Gate | Failure means | Fix path |
| --- | --- | --- |
| Ledger | NOW block ↔ tasks.md drift | Advance/repair ROADMAP `## NOW`; ledger rule = same commit as the work |
| OpenSpec | Active change spec invalid | `openspec validate <change> --strict` output names the file; fix the spec, never patch around it |
| Docs ledger | Manual chapter stale vs watched code | Re-verify the chapter against HEAD, bump `verified:` in the same commit as the seam change |
| L10n | `lib/l10n/gen` stale | `flutter gen-l10n` and commit the result |
| Analyzer | New errors/warnings | Fix before anything else lands (infos are reported, not gated) |
| Tests | Regression or new red | `superpowers:systematic-debugging`; quarantines are ledgered in `docs/stale-tests-post-redesign.md`, never silent |

## Reporting — verified-layer labeling (owner feedback, binding)

Split every report into **proven** (gate output quoted, exit codes) vs
**NOT PROVEN** (device behavior, web runtime, live Appwrite sync, semantic
tick-vs-code match — the verify.sh footer lists them). "Auth works" style
claims from server-side-only evidence burned the owner twice; name the layer
every claim was proven at.
