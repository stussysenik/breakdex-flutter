# Add Library Time & Metadata Browsing

## Why

The library answers "what do I have" but not "when did I get it". Every list in the app is
hardcoded to newest-first with no way to change it, and no surface anywhere shows a date:

- **Ordering is a constant, not a choice.** `MovesDao.watchAll()` orders by
  `createdAt DESC` (`moves_dao.dart:29`, repeated at `:39/:45/:49/:118/:124`);
  `ComboLibraryView` orders by `created_at DESC, name ASC` (`combos_dao.dart:465`). The
  only sort control in the whole app is a name A–Z toggle buried in one experimental
  category-detail nav mode (`move_category_screen.dart:724`).
- **The most meaningful date is stored and never shown.** `moves.videoCreationDate`
  (`tables/moves.dart:20`) holds when the clip was actually filmed — the date a dancer
  thinks in ("that's from the OPTW practice in June"). Nothing reads it. `createdAt`,
  `updatedAt`, `videoFileSize`, and `originalVideoName` are likewise available on every
  row and rendered nowhere.
- **Tiles are near-empty.** A grid cell shows a thumbnail, a name, and a category label
  only when the category isn't `'default'` (`move_grid_cell.dart:52-56`). A user scanning
  200 moves has no way to tell an old clip from yesterday's.
- **Categories can't be browsed over time.** `MoveCategoryScreen` computes a per-category
  count in Dart (`:36-43`) and stops there — no sense of which categories are active, which
  have gone cold, or when a category was last added to.

The library is the product's front door and it is currently time-blind. As the archive
grows past a few hundred clips, "newest first, forever" stops being an ordering and starts
being the only thing you can see.

## What Changes

- **A single sort control on the library**, applied uniformly to Moves and Combos:
  recently added, recently filmed, recently practiced, and A–Z. The choice persists
  (SharedPreferences, alongside `arsenal_view_mode`).
- **One canonical notion of "when"** — an `effectiveDate` for a move (filmed date when
  known, else added date) and for a combo (created, else last activity), so every date
  surface agrees and null capture dates degrade predictably instead of disappearing.
- **Date grouping in the list view** — sticky month headers when a date sort is active, so
  scrolling reads as a timeline rather than an undifferentiated column.
- **Metadata on preview rows and tiles** — the date, and (owner-gated, design O1) an
  optional second line of provenance: file size, original filename, backup state. Which of
  these earn tile space is a visual-first doctrine question, not an engineering one.
- **Categories gain a time dimension** — each category tile reports its most recent
  activity alongside its count, and the category grid can itself be ordered by recency
  instead of only alphabetically.

## Capabilities

- `library-browsing` (new) — sorting, date semantics, time grouping, tile metadata, and
  category recency. Spec delta: `specs/library-browsing/spec.md`.

## Footprint estimate

| Surface | Current | Target |
| --- | --- | --- |
| `lib/features/move_list/move_list_screen.dart` | ~1100 LOC | +60 (sort provider, control, grouping) |
| `lib/core/models/` — sort dimension + `effectiveDate` | — | +50 (new, pure, unit-testable) |
| `lib/features/move_list/widgets/move_row.dart` | ~230 LOC | +15 (date line) |
| `lib/features/move_list/widgets/move_grid_cell.dart` | ~180 LOC | +12 (date line) |
| `lib/features/move_list/widgets/combo_row.dart` | ~120 LOC | +10 (date line) |
| `lib/features/move_category/move_category_screen.dart` | ~830 LOC | +35 (recency + category sort) |
| `lib/core/database/daos/moves_dao.dart` | ~140 LOC | +0 (sorting stays client-side, design D1) |
| ARB / l10n | — | +10 keys |
| Tests | — | +10–14 (sort comparators, date fallback, grouping boundaries) |

## Non-goals

- **No new columns and no migration.** Every date this change surfaces already exists.
  Duration is deliberately excluded — `moves` has no duration column, so showing it would
  mean a schema change plus a backfill pass over every video; that is its own change.
- **No filtering by date range.** Sorting and grouping first; a date-range filter is only
  worth building once we know how people actually navigate the timeline.
- **No change to what a date means.** `videoCreationDate` is read as-is; this change does
  not attempt to repair or backfill missing capture dates from file metadata.
- **No new view mode.** Glance/scan/study stay as `redesign-visual-first-experience`
  shipped them; grouping is an ordering concern layered onto the existing slivers.
- **No sort control inside the category-detail experimental nav modes** — those are a
  separate unresolved experiment (`CategoryNavMode`); this change does not adopt or
  extend them.
