# intent-index Specification

## ADDED Requirements

### Requirement: A derived index resolves an intent to the rulings that bind it

The repo SHALL provide `scripts/docs_index`, a deterministic instrument that reads
YAML frontmatter from `docs/manual/*.mdx`, `openspec/specs/**/spec.md`, and
`openspec/changes/*/proposal.md`, and resolves a query to the records that already
rule on it. The index SHALL be derived on every invocation and SHALL NOT be committed
to the repo in materialized form (design D1).

Sources to index:
- `docs/manual/*.mdx` — all engineering and product manual chapters
- `openspec/specs/**/spec.md` — all promoted capability specs
- `openspec/changes/*/proposal.md` — all active change proposals

Each index entry SHALL contain: `source` (file path), `title`, `domain` (if present),
`status`, `watches` (if present), and `keywords` (derived from title + frontmatter tags).

#### Scenario: Full index includes every documented seam

- **GIVEN** the repo has 18 manual chapters, 10 spec files, and ~30 change proposals
- **WHEN** `scripts/docs_index` runs with no arguments
- **THEN** it emits one JSON entry per document on stdout, covering all records found

#### Scenario: Index is always current with the working tree

- **GIVEN** a manual chapter was added or renamed
- **WHEN** `scripts/docs_index` runs immediately after the filesystem change
- **THEN** the index reflects the new state, because it reads the tree on every
  invocation and has no cached state to go stale

#### Scenario: A query with no binding record says so explicitly

- **WHEN** a query matches no record
- **THEN** the index reports zero matches and names the record classes it searched, so the
  caller can distinguish "nothing is ruled" from "the index did not look there"

### Requirement: Keyword and path-based matching

`scripts/docs_index --match <arg>` SHALL accept a single argument and interpret it
using a heuristic (design D2):

- If the argument starts with one of `lib/`, `docs/`, `scripts/`, `openspec/`,
  `test/`, or `web-mirror/` — it is a **path prefix** and matching is against each
  document's `watches:` glob list.
- Otherwise — it is a **keyword** and matching is against `title`, `name`, `domain`,
  and any `tags:` or `keywords:` frontmatter fields (case-insensitive substring).

Matching SHALL be ranked by record class: manual chapter > promoted spec > active change >
archived change. Archived changes SHALL be ranked last but never excluded — they carry
supersession notes.

#### Scenario: Reverse watches lookup by path

- **GIVEN** a file path `lib/core/sync/sync_backend.dart`
- **WHEN** `scripts/docs_index --match lib/core/sync/sync_backend.dart` runs
- **THEN** it returns the sync chapter (`04-sync.mdx`) whose `watches:` includes
  `lib/core/sync/**`, plus any spec or proposal with a matching watch glob

#### Scenario: Keyword search with ranking

- **GIVEN** the GTM chapter and `add-web-first-release-and-monetization` both concern pricing
- **WHEN** `scripts/docs_index --match pricing` runs
- **THEN** it returns both, ranked with the promoted chapter above the change proposal

#### Scenario: No match returns searched classes

- **GIVEN** a keyword with no matching document
- **WHEN** `scripts/docs_index --match zzznotathing` runs
- **THEN** it names the record classes it searched (manual chapters, specs, proposals)
  so the caller can distinguish "nothing is ruled" from "did not look"

### Requirement: Output format flags

`scripts/docs_index` SHALL support:
- `--json` (default) — one JSON array of objects per document
- `--tsv` — tab-separated columns: source, title, domain, status, watch count, match-reason

#### Scenario: TSV output for shell piping

- **WHEN** `scripts/docs_index --tsv --match sync` runs
- **THEN** the output is tab-separated lines with column headers, suitable for `awk`,
  `cut`, and `column -t` piping

### Requirement: Intent resolution is reachable from the standing board instrument

`scripts/status.sh` SHALL expose the index as `--docs <keyword|path>`, delegating to
`node scripts/docs_index --match <arg> --tsv`. The board SHALL remain read-only and
SHALL NOT be reordered by this verb.

#### Scenario: A session resolves an intent without knowing the index script path

- **GIVEN** a session that has run `bash scripts/status.sh` per the session-start protocol
- **WHEN** it runs `bash scripts/status.sh --docs sync`
- **THEN** it sees the sync chapter listed, linked by path, without grepping or prior
  knowledge of the manual

### Requirement: Dead and malformed index pointers fail the gate

`scripts/verify_ledger.sh` SHALL fail when a chapter's `watches:` glob matches no file on
disk, or when a record's frontmatter cannot be parsed. Index coverage across
`openspec/changes/*` SHALL be reported as a percentage (design D11).

#### Scenario: A renamed directory breaks a watch glob

- **GIVEN** a chapter watching `lib/core/sync/**`
- **WHEN** that directory is renamed and the chapter is not updated
- **THEN** `scripts/verify_ledger.sh` fails, naming the chapter and the dead glob

#### Scenario: A green run states what it did not prove

- **WHEN** the index gate passes
- **THEN** it prints its coverage percentage and states that unresolved intents outside the
  scenario set are not proven by this run

### Requirement: The repo root carries one signpost

The repo SHALL maintain a root `README.md` that names what the repo is, the three
instruments (`status.sh`, `verify_ledger.sh`, `docs_index`), both halves of `docs/manual/`,
and the session-start protocol entry point. It SHALL be a directory of pointers and SHALL
NOT restate any normative content held elsewhere.

#### Scenario: A reader finds the manual from the repo root

- **GIVEN** a reader (human or agent) who has opened the repo and knows nothing about it
- **WHEN** they read the root `README.md`
- **THEN** they reach `docs/manual/index.mdx` and `bash scripts/status.sh` in one hop each

#### Scenario: The signpost duplicates no ruling

- **WHEN** the README is reviewed
- **THEN** every normative statement in it is a link to the record that owns it, not a copy
