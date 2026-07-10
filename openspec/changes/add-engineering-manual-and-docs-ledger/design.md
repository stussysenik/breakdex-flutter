# Design — Engineering Manual & Docs Ledger

## D1 — Manual source location: `docs/manual/`, not the studio

The studio change (`add-web-authoring-and-lifecycle-studio`, `developer-docs` capability)
says MDX docs "live with the studio and build in CI". Ruling here: **content source is
`docs/manual/` at repo root; the studio mounts it**. Rationale: the primary reader is an
agent grepping the repo in a fresh session — the manual must be reachable with zero web
tooling. The studio's build-gate scenario still holds (broken MDX fails `next build`); it
gains a content directory outside `web-mirror/` rather than owning the words. The overlap
is named in both directions per `openspec/AGENTS.md` (cross-change ledger rule).

## D2 — MDX, constrained to a plain-text-safe subset

MDX is chosen for studio rendering (later: embedded ERD/state-diagram components). But
chapters MUST remain meaningful as plain text: CommonMark + YAML frontmatter; JSX only as
progressive enhancement (a diagram embed degrades to a link). This keeps the bundle
(D4) and cheap-model consumers free of any JSX evaluation.

## D3 — Ledger mechanism: co-located frontmatter, not a central registry

Each chapter declares:

```yaml
watches:            # code this chapter is truth about
  - lib/core/state_machines/**
  - lib/core/sync/SyncBackend*   # contracts by glob
verified: 98c195f   # commit the chapter was last checked against
status: verified    # stub | draft | verified
```

Alternatives rejected: central YAML registry (drifts from the files it describes;
frontmatter travels with the chapter on rename) and git-notes (invisible to grep and to
the studio). The drift check is pure git plumbing: for each chapter,
`git diff --name-only <verified>..HEAD -- <watches>`; any hit = stale chapter. No model,
no network — deterministic and CI-cheap.

## D4 — Drift repair is staged: detect → work order → any executor

- **Detect** (this change): script exits non-zero on drift, prints offenders.
- **Work order** (this change): `--json` mode emits `{chapter, watches, verified,
  changed_files, diff_stat}` per stale chapter — everything an executor needs to update
  the chapter and bump `verified`.
- **Execute** (out of scope): a work order is model-agnostic. Mechanical drift (renamed
  file, new enum case) can go to cheap inference (NIM/Cerebras) primed with the bundle;
  conceptual drift (a seam changed meaning) goes to the teacher/executor pipeline. That
  routing decision is per-order and human/teacher-made; automating it is deferred until
  the ledger has produced real work orders to calibrate against.

## D5 — Priming bundle: concatenation with token accounting, nothing smarter

`scripts/docs_bundle` concatenates `index.mdx` + selected chapters (by name or `--all`)
into one artifact, prefixed with a generated TOC and per-chapter token estimates
(chars/4 heuristic — an estimate for budgeting, not billing). Subsetting exists because
cheap-model contexts are small: `--chapters sync,standards` must produce a self-standing
bundle (standards preamble always included). No embeddings, no RAG, no server — if that
is ever needed, it is a new change.

## D6 — Chapter verification is binary truth

A chapter reaches `status: verified` only after its claims are checked against the code
at `verified`'s tree (names, schema versions, file paths resolve). The ledger check is
the enforcement loop thereafter. This mirrors the tasks.md ledger rule: manual updates
ride the same commit as the seam change they document.
