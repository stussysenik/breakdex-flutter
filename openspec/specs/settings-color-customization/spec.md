# settings-color-customization Specification

## Purpose
TBD - created by archiving change clarify-review-loop-and-media-cleanup. Update Purpose after archive.
## Requirements
### Requirement: Settings color controls accept arbitrary colors
Existing color controls in Settings MUST allow arbitrary color selection instead of preset-only selection.

#### Scenario: Accent color accepts custom ARGB value
Given the user opens accent color settings
When they choose a non-preset ARGB value
Then the accent color is saved and applied

#### Scenario: Rating color accepts custom ARGB value
Given the user opens a rating button color editor
When they choose a non-preset ARGB value
Then that rating color is saved and reused by review controls

#### Scenario: Category create flow accepts custom ARGB value
Given the user is creating or renaming a category
When they edit the category color
Then they can save any chosen color instead of picking from presets only

