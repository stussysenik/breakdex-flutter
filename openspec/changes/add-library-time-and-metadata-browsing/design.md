# Design — add-library-time-and-metadata-browsing

## D1 — Sort client-side, not in the DAO

The obvious move is to parameterize `MovesDao.watchAll()` with an ordering. Rejected: the
list screen already loads the whole library and filters it in Dart (search at
`move_list_screen.dart:247-256`), so the rows are in memory regardless. Pushing sort into
Drift would mean a parameterized watch per dimension, a new stream subscription on every
sort change, and a widened DAO surface — for a library measured in hundreds of rows, where
a comparator over an in-memory list is microseconds.

**Ruling:** sort is view state. A `LibrarySort` enum + a comparator function, applied in
the provider that already derives the filtered list. The DAO keeps its single
`createdAt DESC` watch as the stable input. This also keeps the sort logic pure and
unit-testable without a database.

Revisit only if a real library crosses a threshold where the in-memory pass is measurable —
the boring solution first, per the essentialist axiom.

## D2 — One `effectiveDate`, three sort dimensions

Four date-ish fields exist on `moves` (`videoCreationDate`, `createdAt`, `updatedAt`,
`archivedAt`) and three on `combos` (`createdAt`, `updatedAt`, plus `lastEntryAt` derived
in `combos_dao.dart:459-491`). Exposing them raw would produce a sort menu nobody can
reason about.

**Ruling:** three user-facing dimensions, each with an explicit fallback:

| Sort | Move reads | Combo reads | Fallback when null |
| --- | --- | --- | --- |
| Recently added | `createdAt` | `createdAt` | never null (non-nullable column) |
| Recently filmed | `videoCreationDate` | — (n/a) | `createdAt` |
| Recently practiced | `updatedAt` | `lastEntryAt` → `updatedAt` | `createdAt` |
| A–Z | `name` | `name` | — |

`effectiveDate(sort)` is a single pure accessor per entity. The fallback chain is what
makes the feature safe: `videoCreationDate` is nullable and, for legacy imports, usually
null. Without a fallback, "recently filmed" would silently drop most of the library to the
bottom in arbitrary order. With it, those clips sort by when they entered Breakdex, which
is the honest approximation.

**Correction from 1.1 — the combo `updatedAt` link is not wired.** D2's table reads the
chain off the `combos` table, but the library's own stream does not carry it:
`watchLibraryRows` constructs `Combo(...)` from named columns and omits `updatedAt`
(`combos_dao.dart:475-484`), leaving it null for every row. `effectiveDate` implements the
full chain as specified — the gap is hydration, not the model — so the fix is one column in
that SELECT, moved into task 2.1 rather than left as a silent degradation to
`lastEntryAt → createdAt`.

**"Recently filmed" is hidden for combos, not faked.** A combo has no capture date; when
that sort is active the combo tab falls back to recently-added and says so, rather than
inventing a date from its member moves.

## D3 — Grouping is a projection of the active sort

Sticky month headers appear **only** when a date sort is active — grouping an A–Z list by
month is noise. Buckets are calendar months in local time, labeled relatively for the near
past ("This month", "Last month") and absolutely beyond it ("June 2026"), so the top of the
list reads in the tense a user thinks in.

Grouping applies to `scan` (list) mode. `glance` (2-col grid) gets headers as full-width
sliver rows; `study` (large cards) does not group — one card fills the viewport, so a
header between cards is a scroll interruption with no scanning benefit. Stated explicitly
so an executor doesn't "finish" the third mode for symmetry.

## D4 — Tile metadata sits against visual-first doctrine (owner call)

The repo's interface ruling is explicit: *chrome communicates through visual anchors; text
is for input and settings* (`/CLAUDE.md`, `redesign-visual-first-experience`). Phases 2–5
of that change deliberately **removed** text from these exact surfaces. Adding a metadata
line to every tile pushes directly back against a shipped ruling.

The tension is real and this change does not resolve it unilaterally. Ruling: **the date
line is in scope** — a date is the smallest possible text and it is the thing the user
asked for. Everything else (file size, original filename, backup state) is **owner-gated
as O1**, with a bias toward visual encoding where one exists: backup state already has an
icon (`move_grid_cell.dart:29-45`), and that icon should be made honest against
`copyCount` rather than duplicated as a text label.

Note the current backup icon keys off `contentHash != null`, which means "this asset is
tracked", not "this asset is backed up" — a real dishonesty, and the same class of defect
`fix-video-backup-truth-and-unify-account` exists to remove. Correcting it depends on that
change's Phase 4 landing `copyCount` truth (D7/D8 there); until then this change does not
touch the icon. Cross-change dependency, recorded in tasks.

### O1 ruled 2026-07-18 (owner): the date line stands alone

Nothing beyond the date earns tile space. File size and original filename stay off the
tile — both are text on a surface the visual-first ruling reserves for imagery, and
neither answers a browsing question the date does not. 5.2 is therefore a **no-op**: the
only provenance added past the date is backup state, and it is added as the *visual* the
paragraph above already prefers, which is 5.3's work. This keeps the change's net text
addition at exactly one line per tile.

**Reading the code corrected this D4 paragraph.** The backup icon is not a general tile
indicator — it renders only in the no-thumbnail placeholder branch
(`move_grid_cell.dart`, `move.videoPath == null`), so a tile with a thumbnail makes no
backup claim at all. That narrows the dishonesty but does not excuse it: the claim the
icon actually makes there is *"this is retrievable from the cloud"*, and `contentHash !=
null` is true for every tracked asset including ones that never finished uploading.

The honest predicate is also **not `copyCount >= 2`**, as this paragraph assumed.
`copyCount` counts verified copy rows *including the local one*, so it answers "is this
sufficiently protected", not "can I pull these bytes back". The restore affordance needs
the narrower question — **is there a verified copy on a provider other than `local`** —
which is what `AssetCopiesDao.watchRestorableHashes()` answers, in one stream for the
whole grid rather than a query per tile.

Two states, not three: "restorable" versus "gone". Tracked-but-unprotected and never-
tracked are distinguishable in the data but identical to the user standing in front of a
missing video — neither can be recovered — so the tile does not spend a third visual on
the difference. While the stream is unresolved the tile reads as *not* restorable: a
momentary honest "gone" beats a promise the app cannot keep.

## D5 — Category recency without a schema change

`MoveCategoryScreen` already computes per-category counts in Dart over the full move list
(`:36-43`). Most-recent-activity per category is the same pass with a `max` instead of a
count — no new query, no new column, no cost. Categories remain SharedPreferences-backed
(`categories_service.dart`); nothing here changes that model or requires it to.

## Open questions (owner)

- **O1:** Beyond the date, which provenance earns tile space — file size, original
  filename, backup state — or does the date line stand alone (visual-first default)?
- **O2 — RULED 2026-07-18: global, single key.** One `library_sort` preference and one
  control row for both tabs; switching segments never silently re-orders the list. Chosen
  because it is the cheaper thing to widen: per-tab keys can later default from the global
  value with no migration, whereas collapsing two keys into one has to pick a loser. It
  also matches the visual-first ruling — one control, not one per segment. Consequence:
  a filmed sort on the combo tab is always a fallback, which is exactly what task 2.3
  exists to disclose rather than hide.
