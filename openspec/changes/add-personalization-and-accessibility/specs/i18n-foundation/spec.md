# i18n Foundation

## ADDED Requirements

### Requirement: Localization infrastructure exists

The app SHALL use `flutter_localizations` with `gen-l10n` and an English ARB file as the base
locale. The infrastructure SHALL be wired into the app shell (MaterialApp localization
delegates) so adding a locale is a content task, not an engineering task.

#### Scenario: Localization wiring resolves

- **WHEN** the app builds with the l10n configuration
- **THEN** generated localizations resolve for the base English locale and the shell renders
  through them

### Requirement: Phased string extraction with a no-new-hardcoded-strings rule

String extraction SHALL proceed in phases — navigation shell and the five highest-traffic
screens (library, add, review, settings, move detail) first — and from the moment the
foundation lands, NEW user-facing strings SHALL be added through l10n, never hardcoded.
Parametric nouns (renamed data-banks) compose with localization rather than bypassing it.

#### Scenario: Top surfaces read from ARB

- **WHEN** the shell and the five target screens render
- **THEN** their user-facing strings resolve from the generated localizations

#### Scenario: New string goes through l10n

- **GIVEN** a diff adding a user-facing string on any surface
- **WHEN** it is reviewed
- **THEN** the string lives in the ARB file, not as a Dart literal

#### Scenario: Parametric nouns compose

- **GIVEN** a localized template referencing the data-bank noun
- **WHEN** the user has renamed "Moves"
- **THEN** the rendered string uses the custom noun inside the localized sentence
