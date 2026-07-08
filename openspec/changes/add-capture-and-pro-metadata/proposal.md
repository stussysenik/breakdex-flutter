# Add Capture & Pro Video Metadata

## Why

Breakdex is built around footage, but three gaps remain between it and a filmer's real
workflow. (1) **Capture**: a system-camera path already exists in code
(`lib/core/services/video_service.dart:150`, `image_picker` camera source) but is not
surfaced — there is no "record now" entry in the add flow. (2) **Pro metadata**: the moves
table stores only `videoPath`, `originalVideoName`, `videoFileSize`, `videoCreationDate`,
`contentHash` — **no resolution, fps, or codec** — so the app can't speak the language of a
DaVinci Resolve / Blackmagic workflow, and users can't trust what a clip technically is.
(3) **Entry points**: clicking a video in the OS file manager (Files on iOS, file managers on
Android, drag-drop on web) does nothing — the exact video a user is looking at should open
into Breakdex.

Owner rulings (2026-07-08): original bytes are the truth — uploads never transcode
(the Drive provider already uploads raw; this becomes a stated invariant); original filenames
are preserved end-to-end so NLE relink/conform workflows keep working; every core entity is
annotatable with text.

## What Changes

- **In-app capture**: surface a Record anchor in the add flow using the existing
  system-camera path (zero new dependencies); recorded clips enter the normal import
  pipeline. A flagged follow-up evaluates the full `camera` plugin (in-app viewfinder,
  beat-aware overlay) — deferred until the system path proves insufficient.
- **Pro video metadata**: DB migration adds `videoWidth`, `videoHeight`, `videoFps`,
  `videoCodec` to moves; probed at import (native/video_player probe); rendered in move
  detail, the Study view mode, and picker tiles where available. Bytes-preserved and
  name-preserved become spec invariants. A per-video JSON sidecar (original name, hash,
  technical metadata, Breakdex identity) uploads next to each video on Drive so external
  tools and NLE workflows can conform footage without opening the app.
- **Open with Breakdex**: iOS document-type/share-sheet registration, Android intent-filter,
  web drag-drop — all landing on the add flow prefilled with that exact video; if its hash
  already matches a move, open the existing move instead (same non-duplication rule as the
  media grid in `redesign-visual-first-experience`).
- **Entity annotations everywhere**: moves and combos already have notes + timestamped
  entries (`MoveNoteEntries`/`ComboNoteEntries`, `notes_section.dart`); decks and sets gain
  the same, reusing the existing widgets and table shape.

## Capabilities

### New

- `in-app-capture`: record-now entry in the add flow via the system camera.
- `pro-video-metadata`: technical metadata captured/stored/rendered; bytes + names preserved;
  JSON sidecar for NLE interop.
- `open-with-breakdex`: OS-level video entry points on all three platforms.
- `entity-annotations`: text annotations on every core entity.

## Footprint estimate (quantized against 2026-07-08 survey)

| Surface | Delta |
| --- | --- |
| Record anchor in add flow (`add_screen.dart` + `video_service.dart`) | +60 |
| Migration +4 columns (`moves.dart`, schema bump) + companions | +40 (+regen) |
| Probe service (resolution/fps/codec at import) | +120 |
| Rendering (move detail, Study mode, picker) | +90 |
| Sidecar writer in `gdrive_provider.dart` upload path | +80 |
| Share/intent plumbing (iOS plist + Android manifest + handler + web drag-drop) | +250 |
| Decks/sets notes (reuse `notes_section.dart` + entries tables) | +200 |
| Tests | +~400 |

Net: ~+840 product LOC + regen. New dependency: a share/open-intent plugin (e.g.
`receive_sharing_intent`) — the only one; camera stays plugin-free this change.

## Non-goals

- No transcoding, ever (invariant, not a feature).
- No in-app viewfinder this change (flagged evaluation only).
- No frame-positional/overlay annotations (text notes only; overlay annotations are a
  possible later change).
- No timecode track parsing (fps/resolution/codec first; timecode rides the sidecar as
  capture date + duration until a real conform need appears).
