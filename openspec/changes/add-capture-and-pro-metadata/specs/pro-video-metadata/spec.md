# Pro Video Metadata

## ADDED Requirements

### Requirement: Technical metadata is captured and rendered

Each imported video SHALL have its resolution (width×height), frame rate, and codec probed at
import and stored on the move (additive migration). The metadata SHALL render in move detail,
the Study view mode, and picker tiles where available; a failed probe stores nulls and never
blocks import.

#### Scenario: Probe on import

- **WHEN** a clip is imported
- **THEN** the move stores width, height, fps, and codec when probeable

#### Scenario: Probe failure never blocks

- **GIVEN** a clip whose metadata cannot be probed
- **WHEN** import runs
- **THEN** the move is created with null technical fields and the import succeeds

### Requirement: Original bytes and names are preserved end-to-end

Video uploads SHALL never transcode or rewrite the original bytes, and the original filename
(`originalVideoName`) SHALL be preserved through import, sync, and cloud storage so external
NLE workflows (relink/conform in DaVinci Resolve and similar) keep working against Breakdex-
managed footage.

#### Scenario: Byte-identical upload

- **WHEN** a video syncs to Drive
- **THEN** the uploaded object is byte-identical to the local file (hash match)

#### Scenario: Filename survives the round trip

- **GIVEN** a clip imported as `A034_C012_0708.mov`
- **WHEN** it is uploaded and later retrieved
- **THEN** the original filename is recoverable from the record and the sidecar

### Requirement: JSON sidecar accompanies each uploaded video

Each video upload SHALL be accompanied by a JSON sidecar carrying the original filename,
content hash, technical metadata, capture date, and Breakdex identity (move id), so external
tools can conform or audit footage without the app.

#### Scenario: Sidecar uploads with the video

- **WHEN** a video uploads to Drive
- **THEN** a sidecar JSON with name, hash, width/height/fps/codec, capture date, and move id
  is written alongside it

#### Scenario: Sidecar updates on metadata change

- **GIVEN** a move whose technical metadata is re-probed or corrected
- **WHEN** the next sync runs
- **THEN** the sidecar reflects the current values
