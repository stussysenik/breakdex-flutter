# Add Engineering Manual & Docs Ledger

## Why

The repo's technical truth is scattered: `docs/architecture.md` (ERD), `docs/TECHSTACK.MD`,
`docs/hyperdata-ledger.md`, `docs/design/TOKENS.md`, root `CLAUDE.md`, `openspec/AGENTS.md`,
plus per-change designs. The teacher/student split (`openspec/AGENTS.md`) only works if a
**student executor in a fresh session** can locate every load-bearing seam and standard
without re-deriving intent — today that requires archaeology across a dozen files.

This change authors **the Breakdex book**: a canonical MDX engineering manual — the
codebase's reference and codified IP (the atom-model moat, `Machine<S,E>`, sync doctrine,
staff-level mobile standards) — written like a language reference (think *The Swift
Programming Language*), and makes it part of the code-building loop: chapters carry a
**docs↔code ledger** (watched paths + last-verified commit) so drift is mechanically
detectable, and a deterministic **priming bundle** exports the manual (whole or subset,
with token weights) so any student model — the Claude executor, or cheap hosted inference
(NVIDIA NIM, Cerebras) — can be loaded with it before touching the codebase.

## What Changes

- New `docs/manual/` MDX manual: ~14 chapters covering product doctrine (atoms), state
  architecture, data layer, sync, design system, l10n, platform seams, testing, release —
  plus normative staff-level standards chapters that reviews cite. Absorb-or-index rule:
  existing canonical docs (e.g. `TOKENS.md`) are indexed, never duplicated.
- Chapter frontmatter ledger (`watches:` path globs + `verified:` commit) and a drift-check
  script that flags stale chapters and emits machine-readable work orders; wired into CI.
- A bundle script that concatenates selected chapters into one context artifact with a TOC
  and per-chapter token estimates — the student-priming input.

## Capabilities

- `developer-docs` (extends the capability introduced by
  `add-web-authoring-and-lifecycle-studio`): the manual content and its source location.
  That change keeps rendering/hosting (studio `next build` gate); this change owns the
  words. Cross-change overlap: `docs/manual/` is the source the studio mounts.
- `docs-ledger` (new): frontmatter watch-list + drift detection + work orders.
- `student-priming` (new): deterministic context-bundle export with token accounting.

## Assumptions (correct at review if wrong)

1. Manual source lives in `docs/manual/` (repo-canonical, greppable without web tooling);
   the studio renders it but does not own it.
2. "Ledger of the sync" = a docs↔code freshness ledger (which chapter was verified against
   which commit), consistent with the repo's same-commit ledger culture.
3. NIM/Cerebras integration is a *consumer* of the bundle + work orders, not built here —
   whether a drift repair is "function-calling cheap" or "needs intellect" is a per-work-
   order teacher decision; the artifacts are model-agnostic.

## Footprint estimate

| Surface | Current | Target |
| --- | --- | --- |
| `docs/manual/*.mdx` | 0 | ~14 chapters, ~2,500–4,000 lines of content |
| `scripts/` | — | +2 scripts (~250 LOC total: ledger check ~150, bundle ~100) |
| CI workflow | existing | +1 ledger-check step (~10 lines) |
| Existing `docs/*` | as-is | pointer headers only (~5 lines each; nothing moved/deleted) |
| `web-mirror/` | as-is | 0 lines (hosting stays in the studio change) |

## Non-goals

- Live API integration with NVIDIA NIM / Cerebras (or any auto-repair pipeline that calls
  a model). Drift produces a work order; executing it stays a session-level choice.
- Rendering/hosting the docs (owned by `add-web-authoring-and-lifecycle-studio`).
- User-facing documentation — `GUIDE.md` (release-hygiene spec) is disjoint from this
  engineering manual.
- Rewriting or relocating existing docs; brownfield-additive only.
