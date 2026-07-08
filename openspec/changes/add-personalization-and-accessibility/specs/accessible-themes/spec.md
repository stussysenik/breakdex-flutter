# Accessible Themes

## ADDED Requirements

### Requirement: Color-blind-safe theme mode

The app SHALL offer a color-blind-safe theme mode whose palette is distinguishable under
deuteranopia/protanopia (token-level ramp swap in `lib/core/design/`), and in every theme
meaning SHALL never be carried by color alone — rating and state signals pair color with
icon, shape, or label.

#### Scenario: Rating signals survive a grayscale filter

- **WHEN** the review rating row renders in any theme
- **THEN** each rating is distinguishable by icon/shape/label even with color information
  removed

#### Scenario: Color-blind mode swaps the ramp

- **GIVEN** color-blind mode is enabled
- **WHEN** category and state colors render
- **THEN** they resolve from the deuteranopia-safe ramp tokens

### Requirement: Monochrome non-stimulating mode

The app SHALL offer a monochrome (grayscale) theme mode for non-stimulating use, distinct
from the existing `ViewingMode.monoOutline` render style, covering all product surfaces via
the theme layer.

#### Scenario: Monochrome covers product surfaces

- **GIVEN** monochrome mode is enabled
- **WHEN** the user visits library, review, and settings
- **THEN** all surfaces render from the grayscale ramp while remaining fully usable
  (contrast ratios preserved)

#### Scenario: Modes compose with existing themes

- **WHEN** the user toggles monochrome off
- **THEN** the previously selected theme returns exactly
