# Tasks — Intent Index and Business Manual

**Phase dependencies.** Phases 1 and 2 are independent and may be worked in either order
or in parallel. Phase 3 (product manual) depends on Phase 1 landing so the index can
verify coverage. Phase 4 (domain field) is independent. Phase 5 (integration) consumes
Phases 1, 3, and 4. Phase 6 (dogfood) consumes all. V-phase runs last.

**Ledger rule.** Every box ticks in the same commit that lands its work, and the ROADMAP
`## NOW` block advances in that same commit. Binary truth: no tick without terminal output.

**Scope note.** No file under `lib/` changes in this change. If a task appears to require a
Flutter edit, that is a bug in this spec — stop and flag it.

---

## Phase 1 — Intent index tool (`scripts/docs_index` + `status.sh --docs`)

The index is derived on every invocation (design D1). It inverts data that already exists
and works the day it lands.

- [ ] 1.1 Write `scripts/docs_index` (Node.js, sibling idiom to `scripts/docs_ledger_check`).
      Parse YAML frontmatter from `docs/manual/*.mdx`, `openspec/specs/**/spec.md`, and
      `openspec/changes/*/proposal.md`. Build the record set with file path, `title`, `name`,
      `domain`, `status`, `verified`, `watches`. Emit as JSON array to stdout.

      **impl_notes:**
      - Follow `scripts/docs_ledger_check`'s structure exactly: `#!/usr/bin/env node`, strict
        mode, `require('fs')`, `require('path')`. Reference its `parseFrontmatter` function
        for the frontmatter parser pattern.
      - No `npm install` dependencies — use only Node built-ins.
      - Frontmatter fields to extract: `source` (file path), `title`, `name`, `domain`,
        `status`, `watches` (array), `verified` (commit hash), `order` (numeric).
      - For `proposal.md` files, extract `## Capabilities` section headings as keyword entries.
      - Output: `[{ source: "docs/manual/04-sync.mdx", title: "Sync", domain: "engineering",
        status: "verified", watches: ["lib/core/sync/**", ...] }, ...]`

      **Verify:** `node scripts/docs_index` outputs parseable JSON with one entry per existing
      manual chapter (≥13 entries).

- [ ] 1.2 Implement reverse `--match` lookup. If the argument starts with `lib/`, `docs/`,
      `scripts/`, `openspec/`, `test/`, or `web-mirror/`, match against `watches:` globs
      (design D2, path mode). Otherwise match case-insensitive substring against `title`,
      `name`, `domain` fields (keyword mode). Print JSON array of matching records.

      **impl_notes:**
      - Use the same glob-matching logic as `docs_ledger_check`'s `toPathspec` function.
        For simple prefix matching, a path matches a watch glob if the glob (with `**`
        suffix) is a prefix of the argument or vice versa. For example:
        `lib/core/sync/**` matches `lib/core/sync/sync_backend.dart`.
      - Keyword mode: lowercase both the needle and the field, use `String.includes()`.
      - Always output JSON even in match mode. The `--tsv` flag (1.3) handles shell ergonomics.

      **Verify:** `node scripts/docs_index --match lib/core/sync/sync_backend.dart` returns
      chapter 04-sync.mdx. `node scripts/docs_index --match retention` returns zero entries
      initially (no chapters have "retention" in frontmatter).

- [ ] 1.3 Add `--tsv` output flag. Tab-separated columns: source, title, domain, status,
      watch_count, match_reason. Default remains JSON (`--json`).

      **impl_notes:**
      - TSV header line: `source\ttitle\tdomain\tstatus\twatch_count\tmatch_reason`
      - Watch count: length of the `watches` array.
      - Match reason: only populated when `--match` was used, explaining why the record
        matched (e.g., "watches: lib/core/sync/**" or "keyword: pricing in title").

      **Verify:** `node scripts/docs_index --tsv | head -1` prints the tab-delimited
      header. `node scripts/docs_index --json` still outputs valid JSON.

- [ ] 1.4 Add `--help` flag documenting all flags, the path-vs-keyword heuristic (D2),
      and the index scope (which directories and file types it searches).

      **impl_notes:**
      - Print usage to stdout, exit 0.
      - Document: `--match <arg>`, `--json`, `--tsv`, `--help`.
      - Include the path-vs-keyword heuristic table from design D2.

      **Verify:** `node scripts/docs_index --help` prints ≥5 lines of documentation.

- [ ] 1.5 Write `scripts/status.sh` — the derived board instrument. Models `./status.sh`
      output on the format described in `CLAUDE.md` (board table with active change, git
      state, queue size). Add `--docs <arg>` flag that delegates to
      `scripts/docs_index --match <arg> --tsv` and renders in the board's table format.

      **impl_notes:**
      - `cd "$(dirname "$0")/.."` at the top to resolve relative paths from repo root.
      - Board output sections (in order):
        1. `=== Board ===` — active change name, git branch/status, open/ticked task counts
        2. `=== Docs Index ===` section when `--docs <arg>` is passed
      - Read `ROADMAP.md` NOW block to determine active change (same pattern as
        `scripts/verify_ledger.sh` line 18).
      - Read `openspec/changes/$ACTIVE/tasks.md` to count `[ ]` and `[x]` checkboxes.
      - `--docs <arg>`: run `node scripts/docs_index --match <arg> --tsv`, pipe stdout
        through a renderer that formats results as:
        ```
          keyword: <arg>
          <source>  <domain>  <status>  <match_reason>
        ```

      **Verify:** `bash scripts/status.sh` prints a board. `bash scripts/status.sh --docs sync`
      prints board + docs results. Both exit 0.

- [ ] 1.6 Add dead-glob detection and parse-failure gates to the index: exit non-zero when
      a chapter's `watches:` glob matches no file on disk, or when frontmatter cannot be
      parsed. Add `--no-fail` flag to suppress these (for development use).

      **impl_notes:**
      - After building the record set, for each record with `watches`, verify each watch
        glob matches ≥1 real file on disk. Use the same `fs.existsSync` / `glob` logic
        as `docs_ledger_check`.
      - A parse failure means a file matched by the glob search had no valid YAML
        frontmatter (i.e., `parseFrontmatter` returned null).
      - Print errors to stderr: `docs_index: DEAD GLOB chapter 04-sync.mdx watches
        "lib/core/sync/**" matches no files`
      - `--no-fail` prints same warnings but exits 0.

      **Verify:** red/green test. Introduce a bogus glob in a scratch copy of a chapter,
      confirm `node scripts/docs_index` exits 1 and names the chapter. Then use
      `--no-fail`, confirm exit 0.

- [ ] 1.7 Wire the gates into `scripts/verify_ledger.sh`. Add an index-coverage section
      that runs `node scripts/docs_index --no-fail`, reports coverage percentage (documents
      indexed vs documents found on disk), and fails only on parse errors and dead globs
      (design D11). Print what the index gate did NOT prove.

      **impl_notes:**
      - Add after the "Ledger Gate" section in `scripts/verify_ledger.sh`.
      - Coverage percentage = `(indexed records / total files matching corpus) * 100`.
      - Print: `NOT PROVEN by this gate: that every intent in the unbounded intent space
        resolves to a ruling. Only dead globs and parse failures are checked.`
      - Run `bash scripts/verify_ledger.sh --quick` to confirm green.

      **Verify:** `bash scripts/verify_ledger.sh` green with the new gate. Its output names
      the not-proven line.

---

## Phase 2 — Decision-warrant rule (independent of Phase 1)

The decision-warrant rule makes escalation the last resort, not the default. It can land
before or after the index — the index makes it cheap; the rule makes it explicit.

- [ ] 2.1 Add the decision-warrant section to `CLAUDE.md`, between the "Supersession rule"
      and "Queue doctrine" sections. State:
      - A session resolves applicable rulings before escalating.
      - Where a standing ruling determines the answer, the session decides, states the call
        and the ruling it rests on, and proceeds.
      - Where no ruling binds, the session escalates rather than inventing one.
      - Sequencing a delivered scope is a session call. Changing what is in scope is not
        (Capture rule unchanged).
      - Cross-link the Capture rule and Queue doctrine sections.
      - Declare explicitly which clauses are machine-checkable and which rest on review (D6).

      **impl_notes:**
      - Read the existing `CLAUDE.md` structure first. Find the "Supersession rule" section
        and the "Queue doctrine" section. Insert between them.
      - The section title: `## Decision-warrant rule`
      - The enforcement paragraph (D6):
        ```
        - **"Escalate only when no ruling binds"** — not mechanically checkable. Made correct
          by `./status.sh --docs`, not by a gate.
        - **"A decision cites its ruling"** — checkable by review. The `session.log` line
          records the warrant.
        - **"An ask never ends the session uncaptured"** — already checkable (Capture rule).
        ```
      - Reference `--docs` as the instrument that makes the rule operational.
      - No session-log scanning tooling will be built.

      **Verify:** The new section is between the Supersession rule and Queue doctrine.
      Grep the section for normative verbs: each `SHALL`, `MUST`, `never` is inside a link
      or is the rule itself.

- [ ] 2.2 Extend the `docs/manual/session.log` line format to carry the warranting record
      for any decided-not-escalated call. Update `FACTORY.md` step 5 to match the format.

      **Current format (from FACTORY.md):**
      `YYYY-MM-DDThh:mm+TZ <role> <change-name> <summary of what happened>`

      **New format:**
      `YYYY-MM-DDThh:mm+TZ <role> <change-name> [warrant: <record-path>] <summary>`

      **impl_notes:**
      - Read `docs/manual/FACTORY.md` to find the session-start protocol step 5.
      - `[warrant: docs/manual/04-sync.mdx]` is the directive/decision being recorded.
      - Update both FACTORY.md's template and step 5's description.
      - Keep the existing format working for entries without a warrant (backward compatible).

      **Verify:** `grep -c "FACTORY.md" CLAUDE.md` — FACTORY.md is referenced. The format
      string appears in exactly two places (FACTORY.md and session.log example), not three.

- [ ] 2.3 **Capture only:** create a stub change `add-atom-model-algebra` proposing the
      sealed `Atom` type with one composition operator and one interpreter (internal Dart
      DSL). One-line stub `tasks.md` is sufficient; do not design it here.

      **impl_notes:**
      - Create `openspec/changes/add-atom-model-algebra/tasks.md` with a single task:
        ```
        # Tasks — Atom Model Algebra

        - [ ] Capture the sealed `Atom` type design: one composition operator, one
              interpreter, internal Dart DSL. No implementation. See design D10 in
              add-intent-index-and-business-manual.
        ```
      - Also add it to `ROADMAP.md` backlog section (find the "Backlog" section).
      - No proposal.md, design.md, or specs needed yet — just the capture.

      **Verify:** The change directory exists at `openspec/changes/add-atom-model-algebra/`.
      The ROADMAP backlog lists it.

---

## Phase 3 — Product/business manual chapters (consumes Phase 1)

Author by consolidating rulings that already exist and are scattered, not by inventing
product strategy. Each chapter names its gaps rather than filling them with prose (D4).
Sources: `CLAUDE.md` canonical-stack table, `docs/VISION.MD`, `docs/PRD.md`,
`add-web-first-release-and-monetization`, `READINGS.md`.

Each chapter follows the same frontmatter contract as the engineering half:
`title:`, `name:`, `order:`, `domain:`, `status:`, `verified:`, `watches:`.

- [ ] 3.1 `docs/manual/13-product-positioning.mdx` — product domain. Covers wedge
      (who this is for, why breaking), atom model as market position (move → combo → set,
      not generic SRS), visual-first as differentiator, beachhead vs expansion thesis,
      competitive landscape (what breakdex is NOT). `watches:` the atom-model source
      (`lib/core/models/`) and the onboarding route.

      **impl_notes:**
      - Use `04-sync.mdx` as the frontmatter template. Frontmatter fields:
        ```yaml
        ---
        title: Product Positioning
        name: product-positioning
        order: 13
        domain: product
        status: draft
        verified: null
        watches:
          - lib/core/models/**
          - docs/VISION.MD
          - docs/PRD.md
        ---
        ```
      - Every claim links to `docs/VISION.MD`, the atom-model chapter, or a reading.
        Claims with no source are cut, not softened.
      - Title: one line. Content: ~200 lines.

      **Verify:** `bash scripts/status.sh --docs product-positioning` returns chapter 13.

- [ ] 3.2 `docs/manual/14-growth-model.mdx` — product domain. Covers full user journey
      (discover → onboard → practice → improve → share), retention levers and the
      practice-fidelity feedback loop, viral loops/content flywheel, activation criteria.
      `watches:` analytics events, onboarding flow, experiment flag schemas.

      **impl_notes:**
      - Frontmatter: `domain: product`, order 14, watches for analytics and onboarding.
      - Priority: document what exists and what is instrumented. Name the uninstrumented
        remainder as a gap (D4). Do not describe a funnel the product does not measure.
      - Sources: `CLAUDE.md`, `docs/PRD.md`, existing session.log entries about growth.

      **Verify:** `bash scripts/verify_ledger.sh` green after commit does not fail on
      chapter 14 (status is `draft` so ledger skips it).

- [ ] 3.3 `docs/manual/15-gtm-and-pricing.mdx` — gtm domain. Covers distribution strategy
      (web-first private release), invite-code cohort model (entitlement + config cohort),
      monetization tiers ($4.20–$9.99 USD rationale), platform merchant-of-record strategy
      (web merchant-of-record first, StoreKit IAP on iOS later), remote config + cohort
      gating (Appwrite Phase 1R). `watches:` pricing/offering config, entitlement logic,
      `scripts/distribute.sh`.

      **impl_notes:**
      - Frontmatter: `domain: gtm`, order 15.
      - Consolidate the rulings from `CLAUDE.md`'s canonical-stack table row
        ("Distribution & monetization") into prose, then link the table row rather than
        restating it (absorb-or-index).
      - No pricing implementation details — those belong to `add-web-first-release-and-monetization`.

      **Verify:** `--docs pricing` returns this chapter first (ranked above any change
      proposal with "pricing" in its title).

- [ ] 3.4 `docs/manual/16-forward-deployed.mdx` — business domain. Covers product
      decision-making authority (owner-driven model), the release gate (`verify.sh` +
      `distribute.sh`), what a session may and may not do (three session lanes from
      CLAUDE.md), escalation path, brownfield invariants (additive over invasive, no user
      state deletion). `watches:` `scripts/distribute.sh`, `scripts/verify_ledger.sh`,
      `scripts/docs_ledger_check`, `CLAUDE.md`.

      **impl_notes:**
      - Frontmatter: `domain: business`, order 16.
      - Each step of the forward-deployed experience names a real route or service.
        Steps with no implementation are marked as gaps.
      - Sources: `CLAUDE.md` session types section, `FACTORY.md`, `docs/VISION.MD`.

      **Verify:** `bash scripts/status.sh --docs forward-deployed` returns chapter 16.

- [ ] 3.5 `docs/manual/17-metrics-and-observability.mdx` — business domain. Covers key
      business metrics (activation, retention D1/D7/D30, conversion, practice volume per
      user), diagnostics infrastructure (`status.sh`, `verify.sh`, `DiagnosticsLog`),
      the board as health signal (what it measures and what it does not), what is
      explicitly NOT measured (crash-free rate, NPS, revenue — with rationale).

      **impl_notes:**
      - Frontmatter: `domain: business`, order 17.
      - Watches: diagnostics services (`lib/core/services/diagnostics/`), analytics DAOs,
        health-check scripts under `scripts/`.
      - Index (not duplicate) any existing metrics documentation.
      - The chapter's event list and the code's emitted names must match. If the chapter
        documents an event that does not exist in code, the task fails — the chapter is
        wrong, not the code.

      **Verify:** every documented event in the chapter exists as a grep-match in `lib/`.
      `bash scripts/status.sh --docs activation` returns chapter 17.

- [ ] 3.6 Update `docs/manual/index.mdx` — add "Product & Business" section heading,
      chapters 13–17 to the reading-order table with chapter number, title, domain, and
      coverage summary columns. Update the absorb-or-index audit if any product doc
      (VISION.md, PRD.md) changes disposition.

      **impl_notes:**
      - Find the `docs/manual/index.mdx` reading-order table. Add a new section before the
        existing one (or after — match existing style).
      - Table columns: `#`, `name`, `title`, `domain`, `status`.
      - Add a note: "Product chapters are in `draft` until their first `verified:` commit."

      **Verify:** Count matches `ls docs/manual/*.mdx | wc -l`. Every chapter file has a
      row in the index. `grep -c "Product & Business" docs/manual/index.mdx` returns 1.

---

## Phase 4 — READINGS.md domain field

- [ ] 4.1 Add `domain:` to `docs/manual/READINGS.md` format template. Controlled vocabulary:
      `engineering | product | design | gtm | business`. Optional — defaults to `engineering`
      when absent (design D7).

      **impl_notes:**
      - Edit `docs/manual/READINGS.md`. Add `- **Domain:** engineering (product | design | gtm | business)`
        to the format block, after `- **Caveat:**` and before the closing ```
      - Add a comment line: `Domain is optional; defaults to "engineering" when absent.`

      **Verify:** The format block now includes `Domain:`. `grep "Domain:" docs/manual/READINGS.md`
      returns the new line.

- [ ] 4.2 Write ≥1 Scholar entry per non-engineering domain to prove the format. At minimum
      one `product` entry (competitive analysis or product-theory source), one `gtm` entry
      (distribution or pricing reference), and one `design` entry (design system or UI
      pattern source).

      **impl_notes:**
      - Each entry follows the format block exactly, with `Domain:` field.
      - Sources should be real readings relevant to breakdex's domain.
      - Example product entry: a source about portable gyms or practice-fidelity feedback loops.
      - Example gtm entry: a source about invite-code distribution or web-first SaaS launches.
      - Example design entry: a source about visual-first design or motion design systems.

      **Verify:** `grep -c "Domain:" docs/manual/READINGS.md` returns ≥3 (one for each
      domain). Each entry's domain matches the controlled vocabulary.

- [ ] 4.3 Update `scripts/docs_index` to parse `domain:` from READINGS.md entries and
      include them in the index. Each reading entry becomes an index record with
      `source: "docs/manual/READINGS.md"` and `domain: <value>`.

      **impl_notes:**
      - In `scripts/docs_index`, add a reader for `docs/manual/READINGS.md` that splits
        on `### Source:` headings, parses each entry's `Domain:` field, and creates an
        index record.
      - Record format: `{ source: "docs/manual/READINGS.md", title: "<entry title>",
        domain: "product", status: "reading" }`

      **Verify:** `node scripts/docs_index --match product` returns the new READINGS.md
      entries. `--match gtm` returns GTM entries.

---

## Phase 5 — Integration (README, docs_bundle, ledger coverage)

- [ ] 5.1 Write root `README.md` — project elevator pitch, quick links to manual, roadmap,
      CLAUDE.md, design tokens, OpenSpec changes. First-time reader guidance. Build/run/test
      one-liners. Instrument signpost pointing to `./status.sh --docs`. ~40 lines, pointers
      only — every normative statement is a link.

      **impl_notes:**
      ```markdown
      # Breakdex

      A portable gym / infinite idea-generation machine for [practitioners].

      ## Quick links

      - Engineering manual: [docs/manual/index.mdx](./docs/manual/index.mdx)
      - Roadmap: [ROADMAP.md](./ROADMAP.md)
      - Agent contract: [CLAUDE.md](./CLAUDE.md)
      - Design tokens: [docs/design/TOKENS.md](./docs/design/TOKENS.md)
      - OpenSpec changes: [openspec/](./openspec/) → `./status.sh --queue`

      ## First time?

      - **If you are an agent:** start at [CLAUDE.md](./CLAUDE.md) → `## Session start`.
      - **If you are a human:** read the [manual](./docs/manual/index.mdx).

      ## Quick start

      - `flutter run` — launch the app
      - `flutter test` — run the test suite
      - `./status.sh` — check the board
      - `./status.sh --docs <keyword|path>` — resolve an intent to its rulings

      ## Verification

      See `./verify.sh` for the cumulative gate.
      ```
      - No roadmap summary, no architecture diagram, no session history.

      **Verify:** `grep -c "SHALL\|MUST\|never" README.md` = 0 (every normative statement
      is a link, so any matches are inside `[...](./...)` link text).

- [ ] 5.2 Add `--domain` flag to `scripts/docs_bundle`. `--domain product` bundles only
      product-domain chapters (+ standards preamble). `--domain gtm` bundles only gtm
      chapters. `--all` continues to include everything.

      **impl_notes:**
      - In `scripts/docs_bundle`, after the existing `--chapters` flag parsing, add
        `--domain <value>` that filters `loadChapters()` results to only chapters whose
        `domain` frontmatter matches.
      - Standards preamble is always included (same as `--chapters` behavior).
      - `--all` and `--domain` are mutually exclusive (error if both provided).
      - Update `--help` / usage error message to include `--domain`.

      **Verify:** `node scripts/docs_bundle --domain product` output starts with standards
      preamble and includes only chapters with `domain: product`. `--all` still returns 18
      chapters after Phase 3.

- [ ] 5.3 Verify product chapters are covered by `scripts/docs_ledger_check`. Commit a
      product chapter with a `verified:` hash matching HEAD; confirm the check passes.
      Bump a watched file; confirm the check names the product chapter as stale.

      **impl_notes:**
      - `docs_ledger_check` already walks all `docs/manual/*.mdx` files, so it covers
        product chapters automatically. No code changes needed.
      - This task is a manual verification: set `verified: HEAD` on one product chapter,
        run `node scripts/docs_ledger_check`, confirm exit 0. Then touch a watched file,
        re-run, confirm exit 1 with the chapter named.

      **Verify:** `node scripts/docs_ledger_check` exits 0 when chapters are current.
      Exit 1 when a watched file changes.

---

## Phase 6 — Dogfood validation (consumes all)

The change is not done because the scripts run. It is done when a decision that would have
been an escalation resolves without one.

- [ ] 6.1 Build the dogfood scenario set: at least five intents that previously required an
      owner ask, at least two of them business-side. Store as a fixture file that the index
      gate reads.

      **impl_notes:**
      - Create `test/fixtures/index-scenarios.json`:
        ```json
        [
          { "intent": "which offering tier does an invite code grant?", "domain": "gtm",
            "expects_chapter": "15-gtm-and-pricing.mdx" },
          { "intent": "does the icon-pack work ship before the web deploy?", "domain": "business",
            "expects_chapter": "16-forward-deployed.mdx" },
          { "intent": "what owns lib/core/sync/sync_backend.dart?", "domain": "engineering",
            "expects_chapter": "04-sync.mdx" },
          { "intent": "what is the atom model position?", "domain": "product",
            "expects_chapter": "13-product-positioning.mdx" },
          { "intent": "what metrics are measured?", "domain": "business",
            "expects_chapter": "17-metrics-and-observability.mdx" }
        ]
        ```
      - Each entry names the intent as a human would phrase it and the expected warranting
        record.

      **Verify:** the fixture file exists and each entry names a real chapter file.

- [ ] 6.2 Gate the scenario set in `scripts/verify_ledger.sh`: for each fixture intent,
      run `node scripts/docs_index --match "<intent>" 2>/dev/null`, verify that the
      expected chapter appears in the output. Fail with non-zero if any intent resolves
      to zero records (design D11).

      **impl_notes:**
      - Add after the index-coverage section in `scripts/verify_ledger.sh`.
      - Use `jq` or simple string matching to check whether the expected chapter appears
        in the index output.
      - Print: `FAIL  dogfood scenario "[intent]" resolved to no records — expected [chapter]`

      **Verify:** red/green test. Add an unresolvable intent to the fixture, confirm
      `bash scripts/verify_ledger.sh` exits 1. Remove it, exit 0.

- [ ] 6.3 Run one real session end-to-end using only `./status.sh --docs` to resolve its
      rulings, and record in `session.log` how many escalations it required and which
      intents forced them.

      **impl_notes:**
      - This is a manual task: a human or agent starts a working session and resolves every
        routing question using `bash scripts/status.sh --docs <arg>` before escalating.
      - Record in `docs/manual/session.log`:
        `warrant: dogfood-run escalations=2 intents="pricing rationale, web deploy timing"`
      - Unresolved intents become tasks in this change or a new one — never a chat message
        (Capture rule).

      **Verify:** The log line exists in `docs/manual/session.log`. Each unresolved intent
      is captured as a task.

- [ ] 6.4 Reconcile: fold the dogfood findings back into the chapters or the index, then
      state in the change's completion note exactly what this change did NOT prove
      (unbounded intent space, no device/browser verification, no runtime behavior).

      **impl_notes:**
      - Update the change's completion note in the archive directory.
      - State: `NOT PROVEN by this change: (1) every possible intent resolves — only the
        fixture set is gated; (2) device/browser/runtime behavior; (3) that the business
        manual's content is correct about the market (owner must verify).`

      **Verify:** The archive note exists.

---

## Verification

- [ ] V.1 `bash scripts/verify_ledger.sh` green — ledger, `openspec --strict`, docs ledger,
      l10n, analyzer 0/0, full suite.
- [ ] V.2 `node scripts/docs_index --match <domain>` round-trip for every domain and for
      each chapter's primary watched path.
- [ ] V.3 **NOT PROVEN by the above, state it plainly:** whether the product manual's content
      is *correct* about the market, pricing rationale, and growth thesis. Those are product
      decisions only the owner can verify. Route to `owner-verification-passes` as a
      product-manual sitting.
