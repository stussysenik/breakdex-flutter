# video-gallery-picker

## ADDED Requirements

### Requirement: Videos only, all of them
The gallery picker SHALL list only video assets — never images — across all sources: device Photo Library including iCloud-resident videos, the managed Breakdex album, and app-storage videos. iCloud videos SHALL appear in the grid even before they are downloaded locally.

#### Scenario: iCloud video appears
- **WHEN** the library contains a video that exists only in iCloud
- **THEN** its thumbnail tile appears in the grid and selecting it triggers a download-with-progress import

### Requirement: Tile metadata in logical order
Each video tile SHALL overlay, in order of prominence: duration and file size (primary — what distinguishes takes), capture date (secondary), and filename (tertiary). Unknown values render as "—", never as 0. Metadata resolves lazily per tile without blocking grid scroll.

#### Scenario: Tile shows scannable facts
- **WHEN** the grid renders a 12-second, 48 MB video from Jun 8
- **THEN** the tile shows "0:12 · 48 MB", "Jun 8", and the filename, in that visual order

### Requirement: Single-select import
Selection SHALL be single-select: tapping a second tile moves the selection. The import button label SHALL reflect exactly what will happen ("Import video"). The picker SHALL never advertise importing more items than it imports.

#### Scenario: Second tap moves selection
- **WHEN** the user taps tile A and then tile B
- **THEN** only B is selected and the button reads "Import video"

### Requirement: Determinate incremental progress
The import overlay SHALL show determinate progress that advances through every stage where byte or fraction progress is knowable — including the iCloud download stage via the native progress callback. Progress SHALL never sit at an indeterminate spinner when a fraction is available, and SHALL never jump 0→100 for an import that takes longer than one second. A stall (no progress advance for 2s) SHALL be logged with stage context.

#### Scenario: iCloud download advances the bar
- **WHEN** an iCloud-only video downloads over a slow connection
- **THEN** the progress bar advances smoothly through the download stage with a visible percentage

### Requirement: Edge-network resilience
Download/import failures and timeouts SHALL surface inside the overlay with Retry (same asset) and Cancel actions. Cancel SHALL always be available during long operations. Errors SHALL never be reported only via a transient snackbar.

#### Scenario: Timeout offers retry in place
- **WHEN** an iCloud download times out
- **THEN** the overlay shows the timeout message with Retry and Cancel buttons, and Retry re-requests the same asset
