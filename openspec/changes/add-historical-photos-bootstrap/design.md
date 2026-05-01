# Add Historical Photos Bootstrap — Design

## Product Contract

Breakdex remains the source of truth for active move rows once they exist locally. When the local database is missing historical rows but Breakdex-managed Photos assets still exist, startup reconciliation may promote those managed assets back into first-class move rows.

## Recovery Strategy

1. Reconcile tracked managed asset IDs for existing active rows.
2. Discover historical Photos albums using regex patterns that match Breakdex naming variants.
3. Relink existing rows first using exact semantic filename matches, then ranked fuzzy scoring.
4. Import unmatched recoverable assets as new move rows by restoring local video files and attaching managed album metadata.

## Naming

Recovered move creation must avoid duplicate card names. If a recovered base name already exists, append a deterministic recovery suffix.

## Risks

- Broad album matching can import more videos than expected if users manually store unrelated clips in matching albums.
- Filename-derived category parsing is heuristic and may be imperfect for older assets.
