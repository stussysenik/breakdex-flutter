# Icon System

## ADDED Requirements

### Requirement: Product code names meanings, not glyphs

Product code under `lib/` SHALL reference icons through the `AppIcon` vocabulary. A raw
`Icons.*` reference in `lib/features/**`, `lib/shared/**`, or `lib/core/**` SHALL be a review
violation and SHALL fail the conformance gate. `web-mirror/` is out of scope.

`AppIcon` SHALL be a closed enum of semantic names. A name SHALL describe what the icon means
in the product (`AppIcon.move`, `AppIcon.back`, `AppIcon.tombstone`), never how it is drawn
(`AppIcon.roundedChevron` is not a valid name).

#### Scenario: A screen adds an icon

- **WHEN** a screen needs an icon for an existing meaning
- **THEN** it uses the existing `AppIcon` name, and the glyph it renders is whatever the
  active pack resolves for that name

#### Scenario: A screen needs a meaning the vocabulary lacks

- **WHEN** no existing `AppIcon` name fits
- **THEN** a name is added to the enum and to every pack in the same commit, and the addition
  is recorded in the `docs/design/TOKENS.md` iconography table

#### Scenario: A raw Material glyph is reintroduced

- **WHEN** a change adds `Icons.check_rounded` to a widget under `lib/`
- **THEN** the conformance test fails, naming the file and the forbidden reference

### Requirement: A pack cannot be incomplete

An icon pack SHALL resolve every member of `AppIcon`. Resolution SHALL be implemented as a
`switch` over `AppIcon` with no `default` clause and no catch-all pattern, so that the Dart
analyzer's exhaustiveness check reports an unresolved name as a compile error.

A pack SHALL NOT return a nullable `IconData`, and SHALL NOT substitute a placeholder for an
unmapped name. Absence is a build failure, never a rendered fallback.

#### Scenario: A vocabulary entry is added but a pack is not updated

- **WHEN** `AppIcon.foo` is added and only the `material` pack gains a case for it
- **THEN** `flutter analyze` fails on the `lucide` pack's non-exhaustive switch, before any
  build or test runs

#### Scenario: A pack is added

- **WHEN** a third pack is introduced
- **THEN** it compiles only once it resolves all names, so it is complete on the day it ships

### Requirement: The active pack is a theme value

The active `IconPack` SHALL be exposed as a `ThemeExtension` folded into `ThemeData`, built
from `iconPackProvider`. `AppIcon.resolve(BuildContext)` SHALL read it through
`Theme.of(context)`.

Widgets SHALL NOT watch `iconPackProvider` directly. A widget that needs an icon SHALL need
only a `BuildContext`.

#### Scenario: The user switches packs

- **WHEN** a different pack is selected
- **THEN** every icon in the app renders from the new pack after one theme rebuild, with no
  navigation, restart, or per-screen refresh

#### Scenario: A widget test pins a pack

- **WHEN** a test wraps a widget in a `Theme` carrying a chosen pack
- **THEN** the widget resolves icons from that pack without a `ProviderScope`

### Requirement: Pack choice is persisted and never silently overridden

The selected pack SHALL persist to `SharedPreferences` and SHALL survive restart. An unset
preference SHALL resolve to the `material` default. A stored preference SHALL NOT be
overridden when the default changes or when a new pack is added.

An unrecognised stored value SHALL fall back to the default without throwing, so that
removing a pack cannot brick a client that had it selected.

#### Scenario: The app is relaunched

- **WHEN** the user selected `lucide` and relaunches
- **THEN** the app renders `lucide` from first frame, without a flash of the default pack

#### Scenario: A previously shipped pack is removed

- **WHEN** a client has a now-unknown pack key stored
- **THEN** the app starts on the default pack and the stored value is replaced, rather than
  failing to resolve

### Requirement: Packs are selectable in Settings

Settings SHALL surface a section listing every available pack with a live preview rendering
the same representative subset of the vocabulary in each pack, so the choice is made by
looking rather than by reading a name.

The section SHALL be reachable through a `/settings-panel*` route and therefore SHALL use
`settingsSectionPage`, inheriting the Fluid + Morph transition. Pack names and section copy
SHALL resolve through `AppLocalizations`.

#### Scenario: The user compares packs

- **WHEN** the icon-pack section is open
- **THEN** each pack's row previews the same icons, so the families are compared side by side
  rather than one at a time

#### Scenario: A selection is made

- **WHEN** a pack is tapped
- **THEN** the whole app — including the preview, the surrounding chrome, and the tab bar
  behind the section — is already rendering that pack when the section is dismissed

### Requirement: The default pack preserves current glyphs except where a collapse is recorded

For every `AppIcon` name derived from exactly one Material glyph, the `material` pack SHALL
resolve to that same glyph, so migration is pixel-identical at that site.

Where two or more Material glyphs collapse into one semantic name, the collapse SHALL be
recorded in the `docs/design/TOKENS.md` iconography ledger, naming the superseded glyphs, the
surviving name, and the affected files. An unrecorded collapse SHALL be a review violation.

#### Scenario: A file is migrated with no collapses

- **WHEN** a file's icons each map one-to-one
- **THEN** the rendered result is unchanged, and the diff is reviewable as mechanical

#### Scenario: Two variants collapse

- **WHEN** `Icons.close` and `Icons.close_rounded` both become `AppIcon.close`
- **THEN** one of the two call sites changes appearance, and the ledger row states which
  glyph survived and where the change lands
