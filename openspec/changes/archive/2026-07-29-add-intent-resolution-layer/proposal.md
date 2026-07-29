# Add an intent-resolution layer

## Why

This repo has 420 markdown records (148 outside `openspec/`, 272 inside), a 13-chapter MDX
engineering manual with a machine-checked freshness ledger, and two derived instruments
(`status.sh`, `verify.sh`). It has no root `README.md`, and on 2026-07-29 the owner reported
being unable to find the engineering manual at all. The manual was not missing. It was
unreachable.

That is the surface symptom. The load-bearing problem is one layer down.

**The factory's throughput is bounded by how many decisions an agent must escalate to the
owner.** A session that can resolve "what has already been ruled about this?" decides and
keeps working. A session that cannot, asks — and every ask costs a round trip, re-opens a
settled question, and risks a decision that contradicts a ruling nobody could find. The
Queue doctrine already names this failure ("a decision that lives only in a transcript will
be re-asked every session forever"), and the Supersession rule names its worst form (six
changes, ~57 tasks, dead for 89 days because a locked ruling never retired the work it
killed). Both rules describe the disease. Neither gives an agent an instrument.

The gap is unevenly distributed, and that is the tell:

- **Engineering intents resolve.** "What owns `lib/core/sync/`?" is answerable because every
  manual chapter carries a `watches:` glob list and `docs_ledger_check` keeps it honest.
- **Product, GTM, design-rationale, growth, and ops intents resolve to nothing.** The
  merchant-of-record ruling and the $4.20–$9.99 offering band live in a table row in
  `CLAUDE.md`. Positioning lives in `docs/VISION.MD`, unledgered. Growth lives nowhere. An
  agent asked to touch pricing has no path from intent to ruling, so it asks — correctly,
  but expensively, and only because the record does not exist.

The `watches:` data already exists and nothing reads it backwards. Building the reverse
index is cheap; the expensive half is that half the business has no record to index.

## What Changes

Three parts, one spine: make every standing ruling resolvable from an intent, then make
deciding-from-a-ruling the recorded default.

1. **`scripts/docs_index` + `./status.sh --docs <keyword|path>`** — a derived index, never
   stored, in the same idiom as `status.sh`. It reads frontmatter and headings across
   `docs/manual/*.mdx`, `openspec/specs/*/spec.md`, `openspec/changes/*/proposal.md`, and
   the root records, and answers two directions:
   - **path → rulings**: reverse `watches:` lookup. `--docs lib/core/sync/` returns manual
     ch04 plus the sync specs.
   - **keyword → rulings**: `--docs pricing` returns the GTM chapter plus
     `add-web-first-release-and-monetization`.
2. **A business half of `docs/manual/`** — five chapters (positioning, growth & activation,
   GTM/pricing/packaging, forward-deployed, metrics contract) under the *same* frontmatter
   contract, `watches:` globs, and `docs_ledger_check` coverage as the engineering half. A
   business chapter whose `watches:` list is empty does not ship: a chapter that is truth
   about no code is a blog post, and blog posts rot silently.
3. **The decision-warrant rule** — the behavior this change exists to reward, written down
   and made checkable. An agent that finds a binding ruling decides and cites it; an agent
   that finds none escalates. Plus a `domain:` field on `READINGS.md` entries
   (`eng | product | design | gtm | ops`) so the existing Scholar lane absorbs product and
   market sources with no second pipeline.

A root `README.md` becomes the one signpost: what this repo is, the three instruments, the
two manuals, and `--docs` as the way in. It is a directory, not a document.

## Capabilities

| Capability | Delta | What it covers |
| --- | --- | --- |
| `intent-resolution` | ADDED | The index instrument, its two lookup directions, coverage gate, README signpost |
| `decision-warrant` | ADDED | Decide-don't-ask, ruling citation, the escalation boundary, `domain:` on readings |
| `developer-docs` | MODIFIED | Manual extends to a business half under the same authoring contract |
| `docs-ledger` | MODIFIED | Freshness ledger and drift check cover business chapters |

## Footprint estimate

Current → target, per surface. Node is the existing idiom for docs tooling
(`docs_ledger_check` 124 LOC, `docs_bundle` 130 LOC).

| Surface | Current | Target | Δ |
| --- | --- | --- | --- |
| `scripts/docs_index` | — | ~200 LOC (Node) | +200 |
| `status.sh` | 118 LOC | ~150 LOC | +32 (`--docs` verb delegates) |
| `scripts/docs_ledger_check` | 124 LOC | ~140 LOC | +16 (business chapter set) |
| `verify.sh` | 86 LOC | ~92 LOC | +6 (index coverage gate) |
| `README.md` | — | ~60 lines | +60 |
| `docs/manual/*.mdx` | 13 files / 2,204 lines | 18 files / ~3,100 lines | +5 files / ~900 lines |
| `docs/manual/READINGS.md` | format block | +`domain:` field | +8 lines |
| `CLAUDE.md` | — | +decision-warrant section | +22 lines |

Total ≈ **1,240 lines**, ~75% of it prose chapters. Executable code is ~250 LOC across three
scripts. No `lib/` files change; no Flutter surface is touched.

## Non-goals

- **No new runtime or language.** The register this borrows from (Stripe's memo-and-API-docs
  discipline, Airbnb's `.md`-driven RFC process) is a writing culture, not Ruby. Both
  companies being Ruby shops is correlation. A second toolchain would be invisible to
  `verify.sh`, which is the one thing that must see everything.
- **No documentation site, static-site generator, or MDX rendering pipeline.** Chapters stay
  meaningful as plain text; the index is a terminal instrument. The primary reader is a
  fresh agent session, not a browser.
- **No stored index.** The index is derived on every invocation, like `status.sh`. A cached
  index is a sixth record that can disagree with the other five.
- **No repo-wide retrofit of the 272 change documents.** The index reads what frontmatter
  exists and reports coverage; it does not require every historical change to be
  back-filled. Per Queue doctrine, records are repaired when they become active.
- **No new session lane.** Product and market sources ride the existing Scholar lane via
  `domain:`. Adding a parallel factory for the business half is the failure this avoids.
