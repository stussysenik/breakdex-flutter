# Open With Breakdex

## ADDED Requirements

### Requirement: OS-level video entry points on all three platforms

The app SHALL register as a video handler so a user acting on an exact video file outside the
app lands inside Breakdex with that video: iOS via document-type/share-sheet registration,
Android via intent-filter, web via drag-and-drop onto the app. The received video SHALL open
the add flow prefilled with that file.

#### Scenario: Share a video into Breakdex on mobile

- **GIVEN** a video in the platform file manager or share sheet
- **WHEN** the user opens/shares it with Breakdex
- **THEN** the add flow opens prefilled with that exact video

#### Scenario: Drag-drop on web

- **WHEN** the user drops a video file onto the Flutter web app
- **THEN** the add flow opens prefilled with that file

### Requirement: Received videos deduplicate by content hash

A received video whose content hash matches an existing move SHALL open that move's detail
instead of starting a duplicate import — the same non-duplication rule as the media grid in
`redesign-visual-first-experience`.

#### Scenario: Already-added video routes to its move

- **GIVEN** a received video whose hash matches an existing move
- **WHEN** Breakdex handles it
- **THEN** the existing move's detail opens and no duplicate is created
