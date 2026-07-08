# In-App Capture

## ADDED Requirements

### Requirement: Record-now entry in the add flow

The add flow SHALL offer a Record anchor alongside clip selection, launching the system
camera (existing `image_picker` camera path) and feeding the recorded clip into the normal
import pipeline (same metadata, hash, and sync behavior as a picked clip).

#### Scenario: Record and import

- **WHEN** the user activates Record on the Add tab and captures a clip
- **THEN** the clip enters the standard import flow and results in a move identical in shape
  to one created from a picked clip

#### Scenario: Cancel is safe

- **WHEN** the user cancels the system camera
- **THEN** the add flow returns to its prior state with no partial record created

#### Scenario: Platform without a camera degrades visibly

- **GIVEN** a platform/session without camera access (e.g. web desktop)
- **WHEN** the Add surface renders
- **THEN** the Record anchor is absent or visibly disabled — never silently broken
