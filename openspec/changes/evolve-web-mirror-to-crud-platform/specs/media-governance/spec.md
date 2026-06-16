# media-governance

## ADDED Requirements

### Requirement: Video swap-out is copy-then-verify

The web app SHALL let the owner replace a move's video with a new file. The replacement SHALL be
uploaded as a new content-addressed blob, the canonical media index SHALL be updated to point at
the new hash, and only after the new blob is confirmed present SHALL the prior blob be marked
orphaned. The prior media SHALL NOT be deleted inline.

#### Scenario: Swap points the move at new media
- **WHEN** the owner swaps a move's video on the web app
- **THEN** the new file is uploaded and hashed, the index is updated, and the move plays the new video on both clients

#### Scenario: Failed upload leaves original intact
- **WHEN** a swap upload fails before confirmation
- **THEN** the move still references the original media and nothing is orphaned or deleted

### Requirement: Export governance

The web app SHALL let the owner export library data and/or media, governed by explicit scope
selection (what is included). Export SHALL be read-only with respect to the canonical truth and
SHALL NOT mutate or delete source data.

#### Scenario: Owner exports a selection
- **WHEN** the owner chooses an export scope and confirms
- **THEN** the app produces the export from the canonical truth without modifying any source record or media

### Requirement: Orphaned media is reclaimed only by audited GC

Media blobs that become orphaned by a swap SHALL be reclaimed only by a separate, audited
garbage-collection step, never by an inline delete during the swap or export flow.

#### Scenario: Orphan is not deleted during swap
- **WHEN** a swap orphans a prior blob
- **THEN** the blob remains until a distinct, audited GC step reclaims it
