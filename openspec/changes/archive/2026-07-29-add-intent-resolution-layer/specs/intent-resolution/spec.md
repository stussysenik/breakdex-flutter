# intent-resolution Specification

## ADDED Requirements

### Requirement: A derived index resolves an intent to the rulings that bind it

The repo SHALL provide `scripts/docs_index`, a deterministic instrument that reads
`docs/manual/*.mdx` frontmatter, `openspec/specs/*/spec.md` requirement headings,
`openspec/changes/*/proposal.md` metadata, and the root records (`CLAUDE.md`, `ROADMAP.md`),
and resolves a query to the records that already rule on it. The index SHALL be derived on
every invocation and SHALL NOT be committed to the repo in materialized form.

#### Scenario: Reverse watch lookup routes a code path to its chapter

- **GIVEN** manual chapters declare `watches:` globs in frontmatter
- **WHEN** an agent queries a code path such as `lib/core/sync/`
- **THEN** the index returns every record whose `watches:` globs match that path, ranked, with
  each record's file path and the matching glob

#### Scenario: Keyword lookup routes a business intent to its ruling

- **GIVEN** the GTM chapter and `add-web-first-release-and-monetization` both concern pricing
- **WHEN** an agent queries the keyword `pricing`
- **THEN** the index returns both, ranked with the promoted chapter above the change proposal

#### Scenario: A query with no binding record says so explicitly

- **WHEN** a query matches no record
- **THEN** the index reports zero matches and names the record classes it searched, so the
  caller can distinguish "nothing is ruled" from "the index did not look there"

### Requirement: Intent resolution is reachable from the standing board instrument

`./status.sh` SHALL expose the index as `--docs <keyword|path>`, delegating to
`scripts/docs_index`. The board SHALL remain read-only and SHALL NOT be reordered by this
verb.

#### Scenario: A session resolves an intent without knowing the index exists

- **GIVEN** a fresh session that has run `./status.sh` per the session-start protocol
- **WHEN** it reads the board output
- **THEN** the output names `--docs` as the way to resolve an intent to its rulings

### Requirement: The repo root carries one signpost

The repo SHALL maintain a root `README.md` that names what the repo is, the three
instruments (`status.sh`, `verify.sh`, `docs_index`), both halves of `docs/manual/`, and the
session-start protocol entry point. It SHALL be a directory of pointers and SHALL NOT
restate any normative content held elsewhere.

#### Scenario: A reader finds the manual from the repo root

- **GIVEN** a reader (human or agent) who has opened the repo and knows nothing about it
- **WHEN** they read the root `README.md`
- **THEN** they reach `docs/manual/index.mdx` and `./status.sh` in one hop each

#### Scenario: The signpost duplicates no ruling

- **WHEN** the README is reviewed
- **THEN** every normative statement in it is a link to the record that owns it, not a copy

### Requirement: Dead and malformed index pointers fail the gate

`verify.sh` SHALL fail when a chapter's `watches:` glob matches no file on disk, or when a
record's frontmatter cannot be parsed. Index coverage across `openspec/changes/*` SHALL be
reported as a percentage and SHALL NOT be thresholded.

#### Scenario: A renamed directory breaks a watch glob

- **GIVEN** a chapter watching `lib/core/sync/**`
- **WHEN** that directory is renamed and the chapter is not updated
- **THEN** `verify.sh` fails, naming the chapter and the dead glob

#### Scenario: A green run states what it did not prove

- **WHEN** the index gate passes
- **THEN** it prints its coverage percentage and states that unresolved intents outside the
  scenario set are not proven by this run
