# Tasks — Add Capture & Pro Video Metadata

Written 2026-07-29 during queue reconciliation. The change carried a complete
`proposal.md` and four spec deltas but no task list for 20 days, so it counted as
BROKEN and could never be executed. Phases follow the proposal's own footprint table.

Ordering rule: **1 → 2 → 4 are independent and startable now. Phase 3 (open-with) is
last** — it is the only phase adding a dependency and the only one touching three
platform manifests.

## 1. In-app capture (`in-app-capture`)

- [ ] 1.1 Surface a Record anchor in the add flow, routing to the existing system-camera
      path (`lib/core/services/video_service.dart:150`, `image_picker` camera source).
      Zero new dependencies.
- [ ] 1.2 Recorded clips enter the normal import pipeline unchanged — same hashing,
      same dedupe, same destination as a picked video.
- [ ] 1.3 Widget test: Record anchor visible in the add flow and dispatches the camera
      intent; recorded-clip import path asserted against the existing import test harness.

## 2. Pro video metadata (`pro-video-metadata`)

- [ ] 2.1 Additive migration: `videoWidth`, `videoHeight`, `videoFps`, `videoCodec` on
      `moves` (nullable — brownfield rule: never backfill-block an existing row). Bump
      schema version; `dart run build_runner build`.
- [ ] 2.2 Probe service: extract resolution/fps/codec at import. Nullable on failure —
      a probe miss must never fail an import.
- [ ] 2.3 Render technical metadata in move detail, Study view mode, and picker tiles,
      showing nothing (not a placeholder) where unavailable.
- [ ] 2.4 Encode bytes-preserved and names-preserved as asserted invariants, not prose:
      a test proving the uploaded bytes and original filename survive the Drive path.
- [ ] 2.5 JSON sidecar written next to each video in the Drive upload path
      (`gdrive_provider.dart`): original name, hash, technical metadata, Breakdex identity.
- [ ] 2.6 Tests: migration on a populated fixture DB, probe fallback, sidecar shape.

## 3. Open with Breakdex (`open-with-breakdex`) — LAST, adds the only dependency

- [ ] 3.1 Add the share/open-intent plugin (e.g. `receive_sharing_intent`) — the single
      new dependency in this change.
- [ ] 3.2 iOS document-type / share-sheet registration. **Both plists** — debug builds read
      `Info-DebugProfile.plist` (see the iOS config gotcha; editing only `Info.plist`
      silently fails on debug).
- [ ] 3.3 Android intent-filter for video MIME types; web drag-drop onto the add flow.
- [ ] 3.4 Handler lands on the add flow prefilled with that exact video; **if its hash
      already matches a move, open the existing move instead** — same non-duplication rule
      as the media grid in `redesign-visual-first-experience`.
- [ ] 3.5 Unit tests: hash-match routing, no-match routing, unsupported-type rejection.

## 4. Entity annotations (`entity-annotations`)

- [ ] 4.1 Decks and sets gain notes + timestamped entries, reusing the existing
      `notes_section.dart` widget and the `MoveNoteEntries`/`ComboNoteEntries` table shape.
      Reuse over reinvention — this is deliberately not a new subsystem.
- [ ] 4.2 Tests: annotation CRUD on decks and sets; existing move/combo notes unregressed.

## 5. Gate

- [ ] 5.1 `./verify.sh` green (analyzer 0/0, full suite, ledger, `--strict`).
- [ ] 5.2 Tick every box above in the same commit as its work (ledger rule), and update
      the manual chapter for any seam changed.

## Owner-gated — not agent-closable

- [ ] 5.3 Device proof of open-with on real iOS and Android (Files → Breakdex). Belongs to
      the owner's dedicated device session; see `owner-verification-passes`.

## Non-goals (restated so they are not silently built)

- No transcoding, ever — invariant, not a feature.
- No in-app viewfinder this change; the full `camera` plugin stays a flagged evaluation
  until the system-camera path proves insufficient.
