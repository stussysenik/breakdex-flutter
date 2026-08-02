# icon-vocabulary Specification

## Purpose
TBD - created by archiving change unify-text-first-frame-and-icon-vocabulary. Update Purpose after archive.
## Requirements
### Requirement: One glyph vocabulary on every platform

The default `IconPack` SHALL be `CupertinoPack`, and `IconPackId.fromKey` SHALL fall back to
`cupertino` for unknown or absent persisted keys. `CupertinoIcons` ships with Flutter as a font
asset, so the same build renders the same glyph on iOS, Android, and web rather than deferring
to a host set. A pack SHALL resolve every `AppIcon` through a `switch` with no `default`, so
an incomplete pack is a compile error rather than a review finding.

#### Scenario: The app runs on Android or web with no persisted pack

- **WHEN** a client that has never chosen an icon pack renders any surface
- **THEN** the glyphs are the Cupertino set, identical to the iOS build

#### Scenario: A persisted pack name is no longer known

- **GIVEN** SharedPreferences holds an `icon_pack` value that no longer maps to a pack
- **WHEN** the pack is resolved at startup
- **THEN** it falls back to `cupertino` and the client keeps rendering

#### Scenario: A new `AppIcon` name is added

- **WHEN** a semantic name is added to the enum
- **THEN** every pack gains its case in the same commit, or the build fails exhaustiveness

### Requirement: An icon names a meaning, not a layout

A semantic name SHALL describe what a surface *is*, never how it is currently arranged. The
catalogue SHALL be named `AppIcon.library` (a book) and the practice surface `AppIcon.dojo`
(the training floor), because a grid glyph describes the layout and stops being true the moment
the layout changes.

#### Scenario: The navigation bar renders

- **WHEN** the bottom navigation is built
- **THEN** Breakdex resolves `AppIcon.library` and Review resolves `AppIcon.dojo`

#### Scenario: A surface changes its layout

- **GIVEN** the catalogue switches from a grid to a list
- **WHEN** the navigation renders
- **THEN** its icon is unchanged, because the name described the surface and not its arrangement

